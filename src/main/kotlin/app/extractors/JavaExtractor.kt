// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class JavaExtractor : ExtractorInterface {
    companion object {
        const val LANGUAGE_NAME = Lang.JAVA
        val KEYWORDS = listOf("abstract", "continue", "for", "new", "switch",
            "assert", "default", "goto", "package", "synchronized", "boolean",
            "do", "if", "private", "this", "break", "double", "implements",
            "protected", "throw", "byte", "else", "import", "public", "throws",
            "case", "enum", "instanceof", "return", "transient", "catch",
            "extends", "int", "short", "try", "char", "final", "interface",
            "static", "void", "class", "finally", "long", "strictfp",
            "volatile", "const", "float", "native", "super", "while")
        val importRegex = Regex("""^(.*import)\s[^\n]*""")
        val commentRegex = Regex("""^([^\n]*//)[^\n]*""")
        val packageRegex = Regex("""^(.*package)\s[^\n]*""")
        val extractImportRegex = Regex("""import\s+(\w+[.\w+]*)""")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        val stats = super.extract(files).toMutableList()

        // Keywords stats.
        val added = files.fold(mutableListOf<String>(), { total, file ->
            total.addAll(file.getAllAdded())
            total
        })
        val deleted = files.fold(mutableListOf<String>(), { total, file ->
            total.addAll(file.getAllDeleted())
            total
        })

        KEYWORDS.forEach { keyword ->
            val totalAdded = added.count { line -> line.contains(keyword)}
            val totalDeleted = deleted.count { line -> line.contains(keyword)}
            if (totalAdded > 0 || totalDeleted > 0) {
                stats.add(CommitStats(
                    numLinesAdded = totalAdded,
                    numLinesDeleted = totalDeleted,
                    type = ExtractorInterface.TYPE_KEYWORD,
                    tech = LANGUAGE_NAME + ExtractorInterface.SEPARATOR +
                        keyword
                ))
            }
        }

        return stats
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
