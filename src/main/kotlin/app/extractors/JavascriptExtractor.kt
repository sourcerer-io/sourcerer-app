// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class JavascriptExtractor : ExtractorInterface {
    companion object {
        val LANGUAGE_NAME = "js"
        val FILE_EXTS = listOf("js")
        val LIBRARIES = ExtractorInterface.getLibraries("js")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        val splitRegex =
            Regex("""\s+|,|;|:|\\*|\n|\(|\)|\\[|]|\{|}|\+|=|\.|>|<|#|@|\$""")
        val fileTokens = fileContent.joinToString(separator = " ")
            .split(splitRegex)
        imports.addAll(fileTokens.filter { token -> token in LIBRARIES })

        return imports.toList()
    }
}
