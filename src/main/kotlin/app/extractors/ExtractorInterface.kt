// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.DiffContent
import app.model.CommitStats

interface ExtractorInterface {
    fun extract(diffs: List<DiffContent>): List<CommitStats>
}
