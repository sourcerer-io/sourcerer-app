// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.DiffContent
import app.model.Stats

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

    override fun extract(diffs: List<DiffContent>): List<Stats> {
        val stats = mutableListOf<Stats>()

        val added = diffs.fold(mutableListOf<String>()) { total, diff ->
            total.addAll(diff.added)
            total
        }

        val deleted = diffs.fold(mutableListOf<String>()) { total, diff ->
            total.addAll(diff.deleted)
            total
        }

        // Language stats.
        stats.add(Stats(
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
                stats.add(Stats(
                        numLinesAdded = totalAdded,
                        numLinesDeleted = totalDeleted,
                        type = Extractor.TYPE_KEYWORD,
                        tech = NAME + Extractor.SEPARATOR + keyword))
            }
        }

        return stats
    }
}
