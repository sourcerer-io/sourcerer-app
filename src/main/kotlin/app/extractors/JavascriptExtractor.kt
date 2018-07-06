// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

class JavascriptExtractor : ExtractorInterface {
    companion object {
        const val LANGUAGE_NAME = Lang.JAVASCRIPT
        val splitRegex = Regex("""\s+|,|;|:|\*|\n|\(|\)|\[|]|\{|}|\+|=|\.|>|<|#|@|\$""")
        val multilineCommentRegex = Regex("""/\*.+?\*/""")
        val twoOrMoreWordsRegex = Regex("""(".+?\s.+?"|'.+?\s.+?')""")
        val commentRegex = Regex("""^([^\n]*//)[^\n]*""")
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val line = fileContent.map { line -> commentRegex.replace(line, "") }
                       .joinToString(separator = " ").toLowerCase()
        val fileTokens = multilineCommentRegex.replace(
            twoOrMoreWordsRegex.replace(line, ""), "").split(splitRegex)
        return fileTokens.distinct()
    }

    override fun tokenize(line: String): List<String> {
        return super.tokenize(commentRegex.replace(line, ""))
    }

    override fun mapImportToIndex(import: String, lang: String,
                                  startsWith: Boolean): String? {
        return super.mapImportToIndex(import, lang, startsWith = true)
    }

    override fun getLanguageName(): String? {
        return LANGUAGE_NAME
    }
}
