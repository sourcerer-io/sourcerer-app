// Copyright 2019 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class TypescriptExtractor : ExtractorInterface{
    companion object {
        const val LANGUAGE_NAME = Lang.TYPESCRIPT
        private val javascriptExtractor = JavascriptExtractor()
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.forEach { file ->
            file.lang = Lang.JAVASCRIPT
        }
        val libStats = javascriptExtractor.extractLibStats(files)

        files.forEach { file ->
            file.lang = LANGUAGE_NAME
        }
        return super.extractLangStats(files) + libStats
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        return javascriptExtractor.extractImports(fileContent)
    }

    override fun tokenize(line: String): List<String> {
        return javascriptExtractor.tokenize(line)
    }

    override fun mapImportToIndex(import: String, lang: String,
                                  startsWith: Boolean): String? {
        return super.mapImportToIndex(import, Lang.JAVASCRIPT, startsWith = true)
    }

    override fun getLanguageName(): String? {
        return LANGUAGE_NAME
    }
}
