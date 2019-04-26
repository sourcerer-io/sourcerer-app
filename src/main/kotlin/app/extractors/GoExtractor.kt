// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.RegexMeasured
import app.split

class GoExtractor : ExtractorInterface {
    companion object {
        const val CLASS_TAG = "GoExtractor-"
        const val LANGUAGE_NAME = Lang.GO
        val importRegex = RegexMeasured(
            CLASS_TAG + "importRegex",
            """^(.*import)\s[^\n]*"""
        )
        val commentRegex = RegexMeasured(
            CLASS_TAG + "commentRegex",
            """^([^\n]*//)[^\n]*"""
        )
        val singleImportRegex = RegexMeasured(
            CLASS_TAG + "singleImportRegex",
            """import\s+"(.+?)""""
        )
        val multipleImportRegex = RegexMeasured(
            CLASS_TAG + "multipleImportRegex",
            """import[\s\t\n]+\((.+?)\)""",
            RegexOption.DOT_MATCHES_ALL
        )
        val separatorsRegex = RegexMeasured(
            CLASS_TAG + "separatorsRegex",
            """(\t+|\n+|\s+|")"""
        )
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        fileContent.forEach {
            val res = singleImportRegex.find(it)
            if (res != null) {
                val lineLib = res.groupValues.last()
                imports.add(lineLib)
            }
        }
        val contentJoined = fileContent.joinToString(separator = "")
        multipleImportRegex.findAll(contentJoined).forEach { matchResult ->
            imports.addAll(matchResult.groupValues.last()
                .split(separatorsRegex)
                .filter { it.isNotEmpty() }
                .map { it.replace("\"", "") })
        }

        return imports.toList()
    }

    override fun tokenize(line: String): List<String> {
        var newLine = importRegex.replace(line, "")
        newLine = commentRegex.replace(newLine, "")
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
