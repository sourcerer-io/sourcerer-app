// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class CppExtractor : ExtractorInterface {
    companion object {
        const val LANGUAGE_NAME = Lang.CPP
        const val TEMPLATE = "template"
        val importRegex = Regex("""^([^\n]*#include)\s[^\n]*""")
        val commentRegex = Regex("""^([^\n]*//)[^\n]*""")
        val extractImportRegex = Regex("""#include\s+["<](\w+[/\w+]*(\.\w+)?)[">]""")
        val templateRegex = Regex("""template\s*<""")
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        fileContent.forEach {
            val res = extractImportRegex.find(it)
            if (res != null) {
                val lineLib = res.groupValues
                                 .last { !it.startsWith(".") && it != ""}
                imports.add(lineLib)
            }
        }
        return imports.toSet().toList()
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        val stats = super.extract(files).toMutableList()

        // Templates fun fact.
        val allAdded = files.map{ file -> file.getAllAdded() }.flatten()
        val allDeleted = files.map{ file -> file.getAllDeleted() }.flatten()

        val templateAllAdded = allAdded.filter { isTemplate(it) }.size
        val templateAllDeleted = allDeleted.filter { isTemplate(it) }.size

        if (templateAllAdded > 0 || templateAllDeleted > 0) {
            stats.add(CommitStats(
                    templateAllAdded, templateAllDeleted, ExtractorInterface.TYPE_SYNTAX,
                    tech = LANGUAGE_NAME + ExtractorInterface.SEPARATOR + TEMPLATE
            ))
        }

        return stats
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

    private fun isTemplate(line: String): Boolean {
        return line.contains(templateRegex)
    }
}
