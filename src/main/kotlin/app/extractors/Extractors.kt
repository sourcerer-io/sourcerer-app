// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

open class ExtractorBase(private val language: String,
                         private val importRegex: Regex,
                         private val commentRegex: Regex,
                         private val extractImportRegex: Regex) : ExtractorInterface {
    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        fileContent.forEach {
            val line = commentRegex.replace(it, "")
            val res = extractImportRegex.find(line)
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
        return language
    }
}
