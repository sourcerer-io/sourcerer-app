// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

class RustExtractor : ExtractorInterface {
    companion object {
        const val LANGUAGE_NAME = Lang.RUST
        val importRegex = Regex("""^extern crate \w+;$""")
        val commentRegex = Regex("(//.+$)|(/[*].*?[*]/)")
        val extractImportRegex = Regex("""^extern crate (\w+);$""")
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
