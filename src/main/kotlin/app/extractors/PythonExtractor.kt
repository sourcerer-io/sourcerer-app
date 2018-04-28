// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class PythonExtractor : ExtractorInterface {
    companion object {
        val LANGUAGE_NAME = "python"
        val evaluator by lazy {
            ExtractorInterface.getLibraryClassifier(LANGUAGE_NAME)
        }
        val MULTI_IMPORT_TO_LIB =
                ExtractorInterface.getMultipleImportsToLibraryMap(LANGUAGE_NAME)
        val COMPREHENSION_MAP = "map"
        val COMPREHENSION_LIST = "list"
        val docImportRegex = Regex("""^([^\n]*#|\s*\"\"\"|\s*import|\s*from)[^\n]*""")
        val commentRegex = Regex("""^(.*#).*""")
        val extractImportRegex =
            Regex("""(from\s+(\w+)[.\w+]*\s+import|import\s+(\w+(,\s*\w+)*))(as\s+)*""")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        val stats = super.extract(files).toMutableList()

        // List comprehension fun fact.
        val allAdded = files.map{ file -> file.getAllAdded() }.flatten()
        val allDeleted = files.map{ file -> file.getAllDeleted() }.flatten()

        val mapRegex = Regex("""(map\([^,]+?,)""")
        val mapAllAdded = allAdded.fold(0) { total, line ->
            total + mapRegex.findAll(line).toList().size }
        val mapAllDeleted = allDeleted.fold(0) { total, line ->
            total + mapRegex.findAll(line).toList().size }

        val listAllAdded = allAdded.fold(0) { total, line ->
            total + line.count { c -> c == '[' } }
        val listAllDeleted = allDeleted.fold(0) { total, line ->
            total + line.count { c -> c == '[' } }

        if (mapAllAdded > 0 || mapAllDeleted > 0) {
            stats.add(CommitStats(
                mapAllAdded, mapAllDeleted, Extractor.TYPE_SYNTAX,
                tech = LANGUAGE_NAME + Extractor.SEPARATOR + COMPREHENSION_MAP))
        }

        if (listAllAdded > 0 || listAllDeleted > 0) {
            stats.add(CommitStats(
                listAllAdded, listAllDeleted, Extractor.TYPE_SYNTAX,
                tech = LANGUAGE_NAME + Extractor.SEPARATOR + COMPREHENSION_LIST))
        }

        return stats
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        fileContent.forEach {
            val res = extractImportRegex.find(it)
            if (res != null) {
                val lineLibs = res.groupValues.last { it != "" && !it.startsWith(',')}
                    .split(Regex(""",\s*"""))
                imports.addAll(lineLibs)
            }
        }

        var libraries = imports.map { MULTI_IMPORT_TO_LIB.getOrDefault(it, it) }
            .filter { !it.endsWith("pb")}.toMutableList()
        if (libraries.size < imports.size) {
            libraries.add("protobuf")
        }
        return libraries

    }

    override fun tokenize(line: String): List<String> {
        var newLine = docImportRegex.replace(line, "")
        newLine = commentRegex.replace(newLine, "")
        return super.tokenize(newLine)
    }

    override fun getLineLibraries(line: String,
                                  fileLibraries: List<String>): List<String> {

        return super.getLineLibraries(line, fileLibraries, evaluator,
            LANGUAGE_NAME)
    }
}
