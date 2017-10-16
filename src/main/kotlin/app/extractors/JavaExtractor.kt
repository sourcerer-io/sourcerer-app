// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class JavaExtractor : ExtractorInterface {
    companion object {
        val LANGUAGE_NAME = "java"
        val FILE_EXTS = listOf("java")
        val LIBRARIES = ExtractorInterface.getLibraries("java")
        val KEYWORDS = listOf("abstract", "continue", "for", "new", "switch",
            "assert", "default", "goto", "package", "synchronized", "boolean",
            "do", "if", "private", "this", "break", "double", "implements",
            "protected", "throw", "byte", "else", "import", "public", "throws",
            "case", "enum", "instanceof", "return", "transient", "catch",
            "extends", "int", "short", "try", "char", "final", "interface",
            "static", "void", "class", "finally", "long", "strictfp",
            "volatile", "const", "float", "native", "super", "while")
        val evaluator = ExtractorInterface.getLibrariesModelEvaluator(LANGUAGE_NAME)
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = GoExtractor.LANGUAGE_NAME }

        val stats = super.extract(files).toMutableList()

        val added = files.fold(mutableListOf<String>(), { total, file ->
            total.addAll(file.getAllAdded())
            total
        })

        val deleted = files.fold(mutableListOf<String>(), { total, file ->
            total.addAll(file.getAllDeleted())
            total
        })

        // Keywords stats.
        // TODO(anatoly): ANTLR parsing.
        KEYWORDS.forEach { keyword ->
            val totalAdded = added.count { line -> line.contains(keyword)}
            val totalDeleted = deleted.count { line -> line.contains(keyword)}
            if (totalAdded > 0 || totalDeleted > 0) {
                stats.add(CommitStats(
                    numLinesAdded = totalAdded,
                    numLinesDeleted = totalDeleted,
                    type = Extractor.TYPE_KEYWORD,
                    tech = LANGUAGE_NAME + Extractor.SEPARATOR + keyword))
            }
        }

        return stats
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        val regex = Regex("""import\s+(\w+[.\w+]*)""")
        fileContent.forEach {
            val res = regex.find(it)
            if (res != null) {
                val importedName = res.groupValues[1]
                LIBRARIES.forEach { library ->
                    if (importedName.startsWith(library)) {
                        imports.add(library)
                    }
                }
            }
        }

        return imports.toList()
    }

    override fun tokenize(line: String): List<String> {
        val importRegex = Regex("""^(.*import)\s[^\n]*""")
        val commentRegex = Regex("""^([^\n]*//)[^\n]*""")
        var newLine = importRegex.replace(line, "")
        newLine = commentRegex.replace(newLine, "")
        return super.tokenize(newLine)
    }

    override fun getLineLibraries(line: String,
                                  fileLibraries: List<String>): List<String> {

        return super.getLineLibraries(line, fileLibraries, evaluator, LANGUAGE_NAME)
    }
}
