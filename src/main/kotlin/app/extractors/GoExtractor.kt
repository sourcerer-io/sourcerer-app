// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class GoExtractor : ExtractorInterface {
    companion object {
        val LANGUAGE_NAME = "go"
        val FILE_EXTS = listOf("go")
        val evaluator by lazy {
            ExtractorInterface.getLibraryClassifier(LANGUAGE_NAME)
        }
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        val singleImportRegex = Regex("""import\s+"(\w+)"""")
        fileContent.forEach {
            val res = singleImportRegex.find(it)
            if (res != null) {
                val lineLib = res.groupValues.last()
                imports.add(lineLib)
            }
        }
        val multipleImportRegex = Regex("""import[\s\t\n]+\((.+?)\)""",
                RegexOption.DOT_MATCHES_ALL)
        val contentJoined = fileContent.joinToString(separator = "")
        multipleImportRegex.findAll(contentJoined).forEach { matchResult ->
            imports.addAll(matchResult.groupValues.last()
                .split(Regex("""(\t+|\n+|\s+|")"""))
                .filter { it.isNotEmpty() }
                .map { it -> it.replace("\"", "") }
                .map { it ->  if (it.contains("github.com")) it.split("/")[2] else it})
        }

        return imports.toList()
    }

    override fun tokenize(line: String): List<String> {
        val importRegex = Regex("""^(.*import)\s[^\n]*""")
        val commentRegex = Regex("""^([^\n]*//)[^\n]*""")
        var newLine = importRegex.replace(line, "")
        newLine = commentRegex.replace(newLine, "")
        return super.tokenize(newLine)
    }

    override fun getLineLibraries(line: String,
                                  fileLibraries: List<String>): List<String> {

        return super.getLineLibraries(line, fileLibraries, evaluator, LANGUAGE_NAME)
    }
}
