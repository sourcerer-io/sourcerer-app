// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class EmptyExtractor : ExtractorInterface {
    override fun extract(files: List<DiffFile>): List<CommitStats> {
        return listOf()
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        return listOf()
    }
}
