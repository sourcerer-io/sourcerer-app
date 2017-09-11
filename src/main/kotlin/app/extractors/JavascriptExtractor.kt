// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile
import java.io.File

class JavascriptExtractor : ExtractorInterface {
    companion object {
        val LANGUAGE_NAME = "js"
        val FILE_EXTS = listOf("js")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val libraries = mutableSetOf<String>()

        // TODO(anatoly): Load file statically.
        val jsLibraries = File("data/libraries/js_libraries.txt")
            .inputStream().bufferedReader()
            .readLines()
            .toSet()

        val splitRegex =
            Regex("""\s+|,|;|:|\\*|\n|\(|\)|\\[|]|\{|}|\+|=|\.|>|<|#|@|\$""")
        val fileTokens = fileContent.joinToString(separator = " ")
            .split(splitRegex)
        libraries.addAll(fileTokens.filter { token -> token in jsLibraries })

        return libraries.toList()
    }
}
