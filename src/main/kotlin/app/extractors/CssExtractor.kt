// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class CssExtractor : ExtractorInterface {
    companion object {
        val LANGUAGE_NAME = "css"
        val FILE_EXTS = listOf("css", "scss", "less", "sass")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        val stats = FILE_EXTS.filter { it != "css" }.map { extension ->
            val result = files.filter { it.extension == extension }
                .fold(Pair(0, 0)) { total, file ->
                    val currentNumAdded = file.getAllAdded()
                                              .filter { it.isNotBlank() }.size
                    val currentNumDeleted = file.getAllDeleted()
                                                .filter { it.isNotBlank() }.size
                    Pair(total.first + currentNumAdded,
                         total.second + currentNumDeleted)}.toList()

            CommitStats(numLinesAdded = result[0],
                        numLinesDeleted = result[1],
                        type = Extractor.TYPE_LIBRARY,
                        tech = extension)
        }.filter { it.numLinesAdded > 0 || it.numLinesDeleted > 0 }

        return stats + super.extract(files)
    }
}
