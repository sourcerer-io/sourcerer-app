// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

import app.RegexMeasured

class RustExtractor : ExtractorInterface {
    companion object {
        const val CLASS_TAG = "RustExtractor-"
        const val LANGUAGE_NAME = Lang.RUST
        val importRegex = RegexMeasured(
            CLASS_TAG + "importRegex",
            """^extern crate \w+;$"""
        )
        val commentRegex = RegexMeasured(
            CLASS_TAG + "commentRegex",
            "(//.+$)|(/[*].*?[*]/)"
        )
        val extractImportRegex = RegexMeasured(
            CLASS_TAG + "extractImportRegex",
            """^extern crate (\w+);$"""
        )
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        fileContent.forEach {
            val res = extractImportRegex.find(it)
            if (res != null) {
                val lineLib = res.groupValues[1]
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
