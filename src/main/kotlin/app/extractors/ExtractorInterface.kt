// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.DiffFile
import app.model.CommitStats

interface ExtractorInterface {
    fun extract(files: List<DiffFile>): List<CommitStats>
}
