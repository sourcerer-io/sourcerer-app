// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class CommonExtractor(val languageName: String) : ExtractorInterface {
    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = languageName }
        return super.extract(files)
    }
}
