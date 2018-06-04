// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class ObjectiveCExtractor : ExtractorInterface {
    companion object {
        const val LANGUAGE_NAME = Lang.ObjectiveC
        val evaluator by lazy {
            ExtractorInterface.getLibraryClassifier(LANGUAGE_NAME)
        }
        val importRegex = Regex("""^([^\n]*[#@](import|include))\s[^\n]*""")
        val commentRegex = Regex("""^([^\n]*//)[^\n]*""")
        val sharpImportIncludeRegex =
                Regex("""#(import|include)\s+[">](\w+)[/\w+]*\.\w+[">]""")
        val atImportRegex = Regex("""@import\s+(\w+)""")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        fileContent.forEach {
            val res = sharpImportIncludeRegex.findAll(it) +
                atImportRegex.findAll(it)
            if (res.toList().isNotEmpty()) {
                val lineLib = res.toList().map { it.groupValues }.last().last()
                imports.add(lineLib)
            }
        }

        return imports.toList()
    }

    override fun tokenize(line: String): List<String> {
        var newLine = importRegex.replace(line, "")
        newLine = commentRegex.replace(newLine, "")
        return super.tokenize(newLine)
    }

    override fun getLineLibraries(line: String,
                                  fileLibraries: List<String>): List<String> {

        return super.getLineLibraries(line, fileLibraries, evaluator,
            LANGUAGE_NAME)
    }
}
