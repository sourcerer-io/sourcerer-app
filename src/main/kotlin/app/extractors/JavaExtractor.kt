// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class JavaExtractor : ExtractorInterface {
    val NAME = "Java"

    val KEYWORDS = listOf("abstract", "continue", "for", "new", "switch",
            "assert", "default", "goto", "package", "synchronized", "boolean",
            "do", "if", "private", "this", "break", "double", "implements",
            "protected", "throw", "byte", "else", "import", "public", "throws",
            "case", "enum", "instanceof", "return", "transient", "catch",
            "extends", "int", "short", "try", "char", "final", "interface",
            "static", "void", "class", "finally", "long", "strictfp",
            "volatile", "const", "float", "native", "super", "while")

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        val stats = mutableListOf<CommitStats>()

        val added = files.fold(mutableListOf<String>(), { total, file ->
            total.addAll(file.getAllAdded())
            total
        })

        val deleted = files.fold(mutableListOf<String>(), { total, file ->
            total.addAll(file.getAllDeleted())
            total
        })

        // Language stats.
        stats.add(CommitStats(
            numLinesAdded = added.size,
            numLinesDeleted = deleted.size,
            type = Extractor.TYPE_LANGUAGE,
            tech = NAME))

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
                    tech = NAME + Extractor.SEPARATOR + keyword))
            }
        }

        return stats
    }
}
