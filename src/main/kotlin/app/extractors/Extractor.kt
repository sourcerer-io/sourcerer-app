// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class Extractor : ExtractorInterface {
    companion object {
        val TYPE_LANGUAGE = 1
        val TYPE_LIBRARY = 2
        val TYPE_KEYWORD = 3
        val TYPE_SYNTAX = 4
        val SEPARATOR = ">"
        val RESTRICTED_EXTS = listOf(".min.js")

        fun getAllExtensions(): HashSet<String> {
            return Heuristics
                .map { (ext, _) -> ext }
                .toHashSet()
        }
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        return files
            .filter { file -> !RESTRICTED_EXTS.contains(file.extension) }
            .mapNotNull { file ->
                val extractor = Heuristics.get(file.extension)
                if (extractor != null) extractor(file.new.content)?.extract(listOf(file))
                else null
            }
            .fold(mutableListOf()) { accStats, stats ->
                accStats.addAll(stats)
                accStats
            }
    }
}
