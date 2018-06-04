// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class PhpExtractor : ExtractorInterface {
    companion object {
        const val LANGUAGE_NAME = Lang.PHP
        val evaluator by lazy {
            ExtractorInterface.getLibraryClassifier(LANGUAGE_NAME)
        }
        val importRegex = Regex("""^(.*require|require_once|include|include_once|use)\s[^\n]*""")
        val commentRegex = Regex("""^([^\n]*//)[^\n]*""")
        val useRegex = Regex("""use\s+(\w+)[\\\w+]*""")
        val requireIncludeRegex = Regex("""(require|require_once|include|""" +
                """"include_once)\s*[(]?'(\w+)[.\w+]*'[)]?""")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        fileContent.forEach {
            val res = useRegex.findAll(it) + requireIncludeRegex.findAll(it)
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
