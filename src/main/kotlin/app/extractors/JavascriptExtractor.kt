// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.RegexMeasured
import app.model.CommitStats
import app.model.DiffFile
import app.split

class JavascriptExtractor : ExtractorInterface {
    companion object {
        const val CLASS_TAG = "JavascriptExtractor-"
        const val LANGUAGE_NAME = Lang.JAVASCRIPT
        val splitRegex = RegexMeasured(
            CLASS_TAG + "splitRegex",
            """\s+|,|;|:|\*|\n|\(|\)|\[|]|\{|}|\+|=|\.|>|<|#|@|\$"""
        )
        val multilineCommentRegex = RegexMeasured(
            CLASS_TAG + "multilineCommentRegex",
            """/\*.+?\*/"""
        )
        val twoOrMoreWordsRegex = RegexMeasured(
            CLASS_TAG + "twoOrMoreWordsRegex",
            """(".+?\s.+?"|'.+?\s.+?')"""
        )
        val commentRegex = RegexMeasured(
            CLASS_TAG + "commentRegex",
            """^([^\n]*//)[^\n]*"""
        )
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val line = fileContent.map { line -> commentRegex.replace(line, "") }
                       .joinToString(separator = " ").toLowerCase()
        val fileTokens = multilineCommentRegex.replace(
            twoOrMoreWordsRegex.replace(line, ""), "").split(splitRegex)
        return fileTokens.distinct()
    }

    override fun extractLibStats(files: List<DiffFile>): List<CommitStats> {
        val vueExtension = ".vue"
        val vueFiles = files.filter { it.path.endsWith(vueExtension) }
        val otherFiles = files.filter { !it.path.endsWith(vueExtension) }

        // Add stats from *.vue files.
        val vueStats = listOf(CommitStats(
            numLinesAdded = vueFiles.map { it.getAllAdded().size }.sum(),
            numLinesDeleted = vueFiles.map { it.getAllDeleted().size }.sum(),
            type = ExtractorInterface.TYPE_LIBRARY,
            tech = "js.vue"
        )).filter { it.numLinesAdded > 0 || it.numLinesDeleted > 0 }
        return vueStats + super.extractLibStats(otherFiles)
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
