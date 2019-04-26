// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.RegexMeasured

class KotlinExtractor : ExtractorInterface {
    companion object {
        const val CLASS_TAG = "KotlinExtractor-"
        const val LANGUAGE_NAME = Lang.KOTLIN
        val importRegex = RegexMeasured(
            CLASS_TAG + "importRegex",
            """^(.*import)\s[^\n]*"""
        )
        val commentRegex = RegexMeasured(
            CLASS_TAG + "commentRegex",
            """^([^\n]*//)[^\n]*"""
        )
        val packageRegex = RegexMeasured(
            CLASS_TAG + "packageRegex",
            """^(.*package)\s[^\n]*"""
        )
        val extractImportRegex = RegexMeasured(
            CLASS_TAG + "extractImportRegex",
            """import\s+(\w+[.\w+]*)""")
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        fileContent.forEach {
            val res = extractImportRegex.find(it)
            if (res != null) {
                val importedName = res.groupValues[1]
                imports.add(importedName)
            }
        }

        return imports.toList()
    }

    override fun tokenize(line: String): List<String> {
        var newLine = importRegex.replace(line, "")
        newLine = commentRegex.replace(newLine, "")
        newLine = packageRegex.replace(newLine, "")
        return super.tokenize(newLine)
    }

    override fun mapImportToIndex(import: String, lang: String,
                                  startsWith: Boolean): String? {
        return super.mapImportToIndex(import, lang, startsWith = true)
    }

    override fun getLanguageName(): String? {
        return LANGUAGE_NAME
    }
}
