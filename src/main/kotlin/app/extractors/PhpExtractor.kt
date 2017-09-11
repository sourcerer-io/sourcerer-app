// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class PhpExtractor : ExtractorInterface {
    companion object {
        val LANGUAGE_NAME = "php"
        val FILE_EXTS = listOf("php", "phtml", "php4", "php3", "php5", "phps")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val libraries = mutableSetOf<String>()

        val useRegex = Regex("""use\s+(\w+)[\\\w+]*""")
        val requireIncludeRegex = Regex("""(require|require_once|include|""" +
            """"include_once)\s*[(]?'(\w+)[.\w+]*'[)]?""")
        fileContent.forEach {
            val res = useRegex.findAll(it) + requireIncludeRegex.findAll(it)
            if (res.toList().isNotEmpty()) {
                val lineLib = res.toList().map { it.groupValues }.last().last()
                libraries.add(lineLib)
            }
        }

        return libraries.toList()
    }
}
