// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class EmptyExtractor : ExtractorInterface {
    override fun extract(files: List<DiffFile>): List<CommitStats> {
        return listOf()
    }
}
