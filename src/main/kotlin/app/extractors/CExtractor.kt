// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class CExtractor : ExtractorInterface {
    companion object {
        val LANGUAGE_NAME = "c"
        val FILE_EXTS = listOf("c")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val libraries = mutableSetOf<String>()

        val regex = Regex("""#include\s+["<](\w+)[/\w+]*\.\w+[">]""")
        fileContent.forEach {
            val res = regex.find(it)
            if (res != null) {
                val lineLib = res.groupValues.last()
                libraries.add(lineLib)
            }
        }

        return libraries.toList()
    }
}
