// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class JavascriptExtractor : ExtractorInterface {
    companion object {
        val LANGUAGE_NAME = "javascript"
        val FILE_EXTS = listOf("js", "jsx")
        val LIBRARIES = ExtractorInterface.getLibraries("js")
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

        val splitRegex =
            Regex("""\s+|,|;|:|\*|\n|\(|\)|\\[|]|\{|}|\+|=|\.|>|<|#|@|\$""")
        val fileTokens = fileContent.joinToString(separator = " ").toLowerCase()
            .split(splitRegex)
        imports.addAll(fileTokens.filter { token -> token in LIBRARIES })

        return imports.toList()
    }

    override fun getLineLibraries(line: String,
                                  fileLibraries: List<String>): List<String> {

        return super.getLineLibraries(line, fileLibraries, evaluator, LANGUAGE_NAME)
    }
}
