// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class ObjectiveCExtractor : ExtractorInterface {
    companion object {
        val LANGUAGE_NAME = "objectivec"
        val FILE_EXTS = listOf("h", "m", "mm")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val libraries = mutableSetOf<String>()

        val sharpImportIncludeRegex =
            Regex("""#(import|include)\s+[">](\w+)[/\w+]*\.\w+[">]""")
        val atImportRegex = Regex("""@import\s+(\w+)""")

        fileContent.forEach {
            val res = sharpImportIncludeRegex.findAll(it) +
                atImportRegex.findAll(it)
            if (res.toList().isNotEmpty()) {
                val lineLib = res.toList().map { it.groupValues }.last().last()
                libraries.add(lineLib)
            }
        }

        return libraries.toList()
    }
}
