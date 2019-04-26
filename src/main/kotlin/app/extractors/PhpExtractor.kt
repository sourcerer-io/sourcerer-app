// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.RegexMeasured

class PhpExtractor : ExtractorInterface {
    companion object {
        const val CLASS_TAG = "PhpExtractor-"
        const val LANGUAGE_NAME = Lang.PHP
        val importRegex = RegexMeasured(
            CLASS_TAG + "importRegex",
            """^(.*require|require_once|include|""" +
            """include_once|use)\s[^\n]*"""
        )
        val commentRegex = RegexMeasured(
            CLASS_TAG + "commentRegex",
            """^([^\n]*//)[^\n]*"""
        )
        val useRegex = RegexMeasured(
            CLASS_TAG + "useRegex",
            """use\s+(\w+)[\\\w+]*"""
        )
        val requireIncludeRegex = RegexMeasured(
            CLASS_TAG + "requireIncludeRegex",
            """(require|require_once|include|""" +
                """"include_once)\s*[(]?'(\w+)[.\w+]*'[)]?"""
        )
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        fileContent.forEach {
            val res = useRegex.findAll(it) + requireIncludeRegex.findAll(it)
            if (res.toList().isNotEmpty()) {
                val lineLib = res.toList().map { it.groupValues }.last().last()
                imports.add(lineLib)
            }
        }

        return imports.toList()
    }

    override fun tokenize(line: String): List<String> {
        var newLine = importRegex.replace(line, "")
        newLine = commentRegex.replace(newLine, "")
        return super.tokenize(newLine)
    }

    override fun getLanguageName(): String? {
        return LANGUAGE_NAME
    }
}
