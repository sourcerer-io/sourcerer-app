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
        val splitRegex =
                Regex("""\s+|,|;|:|\*|\n|\(|\)|\[|]|\{|}|\+|=|\.|>|<|#|@|\$""")
        val multilineCommentRegex = Regex("""/\*.+?\*/""")
        val twoOrMoreWordsRegex = Regex("""(".+?\s.+?"|'.+?\s.+?')""")

        val commentRegex = Regex("""^([^\n]*//)[^\n]*""")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val line = fileContent.map { line -> commentRegex.replace(line, "")}
                       .joinToString(separator = " ").toLowerCase()
        val fileTokens = multilineCommentRegex.replace(
                            twoOrMoreWordsRegex.replace(line, ""), "")
                            .split(splitRegex)
        return fileTokens.filter { token -> token in LIBRARIES }.distinct()
    }

    override fun getLineLibraries(line: String,
                                  fileLibraries: List<String>): List<String> {
        return super.getLineLibraries(line, fileLibraries, evaluator,
            LANGUAGE_NAME)
    }

    override fun tokenize(line: String): List<String> {
        val commentRegex = Regex("""^([^\n]*//)[^\n]*""")
        return super.tokenize(commentRegex.replace(line, ""))
    }
}
