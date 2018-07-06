// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class CommonExtractor(private val langName: String) : ExtractorInterface {
    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.lang = langName }
        return super.extract(files)
    }
}
