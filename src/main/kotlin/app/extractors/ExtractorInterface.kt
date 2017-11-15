// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.extractors

import app.BuildConfig
import app.Logger
import app.model.DiffFile
import app.model.CommitStats
import org.dmg.pmml.FieldName
import org.dmg.pmml.PMML
import org.jpmml.evaluator.Evaluator
import org.jpmml.evaluator.FieldValue
import org.jpmml.evaluator.ModelEvaluatorFactory
import org.jpmml.evaluator.ProbabilityDistribution
import org.jpmml.model.PMMLUtil
import org.jpmml.sklearn.PickleUtil
import sklearn.pipeline.Pipeline
import sklearn2pmml.PMMLPipeline
import java.io.InputStream
import org.jpmml.sklearn.CompressedInputStreamStorage
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.file.Files
import java.nio.file.Paths
import org.apache.http.client.methods.HttpGet
import org.apache.http.impl.client.HttpClientBuilder
import java.io.File

interface ExtractorInterface {
    companion object {
        private val librariesCache = hashMapOf<String, Set<String>>()
        private val evaluatorsCache = hashMapOf<String, Evaluator>()
        private val classifiersCache = hashMapOf<String, Classifier>()

        private fun getResource(path: String): InputStream {
            return ExtractorInterface::class.java.classLoader
                .getResourceAsStream(path)
        }

        fun getLibraries(name: String): Set<String> {
            if (librariesCache.containsKey(name)) {
                return librariesCache[name]!!
            }
            val libraries = getResource("data/libraries/${name}_libraries.txt")
                .bufferedReader().readLines().toSet()
            librariesCache.put(name, libraries)
            return libraries
        }

        private fun downloadModel(name: String, outputDir: String) {
            val url = BuildConfig.LIBRARY_MODELS_URL + "$name.pb"
            val outputPath = "$outputDir/$name.pb"

            if (Files.notExists(Paths.get(outputDir))) {
                Files.createDirectories(Paths.get(outputDir))
            }

            val builder = HttpClientBuilder.create()
            val client = builder.build()
            try {
                client.execute(HttpGet(url)).use { response ->
                    val entity = response.entity
                    if (entity != null) {
                        FileOutputStream(outputPath).use { outstream ->
                            entity.writeTo(outstream)
                            outstream.flush()
                            outstream.close()
                        }
                    }

                }
            }
            catch (e: Exception) {
                Logger.error(e, "Failed to download $name model")
            }
        }

        fun getLibraryClassifier(name: String): Classifier {
            if (classifiersCache.containsKey(name)) {
                return classifiersCache[name]!!
            }

            val pbDir = ".sourcerer/data/pb"
            val pbPath = "$pbDir/$name.pb"

            if (Files.notExists(Paths.get(pbDir))) {
                Files.createDirectories(Paths.get(pbDir))
            }

            if (Files.notExists(Paths.get(pbPath))) {
                Logger.info { "Downloading $name.pb" }
                downloadModel(name, pbDir)
                Logger.info { "Downloaded $name.pb" }
            }

            Logger.info {"Loading $name evaluator" }

            val bytesArray = File(pbPath).readBytes()
            val classifier = Classifier(bytesArray)
            classifiersCache.put(name, classifier)

            Logger.info { "$name evaluator ready" }

            return classifier
        }
    }

    fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file ->
            file.old.imports = extractImports(file.old.content)
            file.new.imports = extractImports(file.new.content)
            file
        }

        val oldLibraryToCount = mutableMapOf<String, Int>()
        val newLibraryToCount = mutableMapOf<String, Int>()
        val oldFilesImports = files.fold(mutableSetOf<String>()) { acc, file ->
            acc.addAll(file.old.imports)
            acc
        }
        val newFilesImports = files.fold(mutableSetOf<String>()) { acc, file ->
            acc.addAll(file.new.imports)
            acc
        }

        oldFilesImports.forEach { oldLibraryToCount[it] = 0}
        newFilesImports.forEach { newLibraryToCount[it] = 0}


        files.filter { file -> file.language.isNotBlank() }
            .forEach { file ->
                val oldFileLibraries = mutableListOf<String>()
                file.getAllDeleted().forEach {
                    val lineLibs = getLineLibraries(it, file.old.imports)
                    oldFileLibraries.addAll(lineLibs)
                }
                file.old.imports.forEach { import ->
                    val numLines = oldFileLibraries.count { it == import }
                    oldLibraryToCount[import] =
                        oldLibraryToCount[import] as Int + numLines
                }

                val newFileLibraries = mutableListOf<String>()
                file.getAllAdded().forEach {
                    val lineLibs = getLineLibraries(it, file.new.imports)
                    newFileLibraries.addAll(lineLibs)
                }
                file.new.imports.forEach { import ->
                    val numLines = newFileLibraries.count { it == import }
                    newLibraryToCount[import] =
                            newLibraryToCount[import] as Int + numLines
                }
            }

        val allImports = mutableSetOf<String>()
        allImports.addAll(oldFilesImports + newFilesImports)

        val libraryStats = allImports.map {
            CommitStats(
                numLinesAdded = newLibraryToCount.getOrDefault(it, 0),
                numLinesDeleted = oldLibraryToCount.getOrDefault(it, 0),
                type = Extractor.TYPE_LIBRARY,
                tech = it)
        }.filter {it.numLinesAdded > 0 || it.numLinesDeleted > 0}

        return files.filter { file -> file.language.isNotBlank() }
                    .groupBy { file -> file.language }
                    .map { (language, files) -> CommitStats(
                        numLinesAdded = files.fold(0) { total, file ->
                            total + file.getAllAdded().size },
                        numLinesDeleted = files.fold(0) { total, file ->
                            total + file.getAllDeleted().size },
                        type = Extractor.TYPE_LANGUAGE,
                        tech = language)} + libraryStats
    }

    fun extractImports(fileContent: List<String>): List<String> {
        return listOf()
    }

    fun tokenize(line: String): List<String> {
        val stringRegex = Regex("""(".+?"|'.+?')""")
        val newLine = stringRegex.replace(line, "")
        //TODO(lyaronskaya): multiline comment regex
        val splitRegex =
            Regex("""\s|,|;|\*|\n|\(|\)|\[|]|\{|}|\+|=|&|\$|!=|\.|>|<|#|@|:|\?|!""")
        val tokens = splitRegex.split(newLine)
            .filter { it.isNotBlank() && !it.contains('"') && !it.contains('\'')
                && it != "-" && it != "@"}
        return tokens
    }

    fun getLineLibraries(line: String, fileLibraries: List<String>):
        List<String> {
        return listOf()
    }

    fun getLineLibraries(line: String,
                         fileLibraries: List<String>,
                         evaluator: Classifier,
                         languageLabel: String): List<String> {
        val probabilities = evaluator.evaluate(tokenize(line))
        val libraries = evaluator.getCategories()

        val maxProbability = probabilities.max() as Double
        val maxProbabilityCategory =
                libraries[probabilities.indexOf(maxProbability)]
        val selectedCategories = libraries.filter {
            probabilities[libraries.indexOf(it)] >= 0.2 * maxProbability
        }

        if (maxProbabilityCategory == languageLabel) {
            return emptyList()
        }

        // For C language.
        // Consider line with language label being the one with high probability
        // as not having library.
        // Keep it while the number of libraries is small.
        if (languageLabel == CExtractor.LANGUAGE_NAME &&
                languageLabel in selectedCategories) {
            return emptyList()
        }

        val lineLibraries = fileLibraries.filter { it in selectedCategories }
        return lineLibraries
    }
}
