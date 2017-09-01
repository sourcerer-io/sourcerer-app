// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.DiffContent
import app.model.CommitStats

class PythonExtractor : ExtractorInterface {
    val NAME = "Python"

    override fun extract(diffs: List<DiffContent>): List<CommitStats> {
        val stats = mutableListOf<CommitStats>()

        // Language stats.
        stats.add(CommitStats(
                numLinesAdded = diffs.fold(0) { total, diffContent ->
                    total + diffContent.added.size },
                numLinesDeleted = diffs.fold(0) { total, diffContent ->
                    total + diffContent.deleted.size },
                type = Extractor.TYPE_LANGUAGE,
                tech = NAME))

        return stats
    }
}
