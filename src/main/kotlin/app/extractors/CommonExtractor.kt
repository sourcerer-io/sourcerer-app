// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.DiffFile
import app.model.CommitStats

/**
 * Common extractor that get basic stats and assigns it to specified language.
 */
class CommonExtractor(val language: String) : ExtractorInterface {

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        val stats = mutableListOf<CommitStats>()

        stats.add(CommitStats(
            numLinesAdded = files.fold(0) { total, file ->
                total + file.getAllAdded().size },
            numLinesDeleted = files.fold(0) { total, file ->
                total + file.getAllDeleted().size },
            type = Extractor.TYPE_LANGUAGE,
            tech = language))

        return stats
    }
}
