// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

class ObjectiveCExtractor : ExtractorInterface {
    companion object {
        const val LANGUAGE_NAME = Lang.OBJECTIVEC
        val importRegex = Regex("""^([^\n]*[#@](import|include))\s[^\n]*""")
        val commentRegex = Regex("""^([^\n]*//)[^\n]*""")
        val sharpImportIncludeRegex =
                Regex("""[#@](import|include)\s+["<](\w+)[/\w+]*\.\w+[">]""")
        val atImportRegex = Regex("""@import\s+(\w+)""")
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        fileContent.forEach {
            val res = sharpImportIncludeRegex.findAll(it) +
                atImportRegex.findAll(it)
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
