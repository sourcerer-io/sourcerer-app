// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

class GoExtractor : ExtractorInterface {
    companion object {
        const val LANGUAGE_NAME = Lang.GO
        val importRegex = Regex("""^(.*import)\s[^\n]*""")
        val commentRegex = Regex("""^([^\n]*//)[^\n]*""")
        val singleImportRegex = Regex("""import\s+"(.+?)"""")
        val multipleImportRegex = Regex("""import[\s\t\n]+\((.+?)\)""",
                RegexOption.DOT_MATCHES_ALL)
        val separatorsRegex = Regex("""(\t+|\n+|\s+|")""")
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
