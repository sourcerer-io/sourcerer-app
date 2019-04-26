// Copyright 2019 Sourcerer Inc. All Rights Reserved.
// Author: Anton Maminov (anton.maminov@gmail.com)

package app.extractors

import app.RegexMeasured

class CrystalExtractor : ExtractorInterface {
    companion object {
        const val CLASS_TAG = "CrystalExtractor-"
        const val LANGUAGE_NAME = Lang.CRYSTAL
        val importRegex = RegexMeasured(
            CLASS_TAG + "importRegex",
            """require\s+\"(\w+)\""""
        )
        val commentRegex = RegexMeasured(
            CLASS_TAG + "commentRegex",
            """^([^\n]*#)[^\n]*"""
        )
        val extractImportRegex = RegexMeasured(
            CLASS_TAG + "extractImportRegex",
            """require\s+\"(.+)\""""
        )
        val includeRegex = RegexMeasured(
            CLASS_TAG + "includeRegex",
            """include\s+(\w+)::.+"""
        )
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        fileContent.forEach {
            val res = extractImportRegex.find(it)
            if (res != null) {
                val lineLib = res.groupValues.last { it != "" }
                imports.add(lineLib)
            }
        }

        if (imports.isEmpty()) {
            fileContent.forEach {
                val res = includeRegex.find(it)
                if (res != null) {
                    imports.add(res.groupValues.last().toLowerCase())
                }
            }
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
