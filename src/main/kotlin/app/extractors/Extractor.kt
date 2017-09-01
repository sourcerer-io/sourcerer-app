// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.DiffContent
import app.model.CommitStats
import app.utils.FileHelper

class Extractor : ExtractorInterface {
    companion object Constants {
        val TYPE_LANGUAGE = 1
        val TYPE_KEYWORD = 2

        val SEPARATOR = ">"

        val JAVA_FILE_EXTENSIONS = listOf("java")
        val PYTHON_FILE_EXTENSIONS = listOf("py", "py3")
    }

    fun create(extension: String): ExtractorInterface {
        return when (extension) {
            in JAVA_FILE_EXTENSIONS -> JavaExtractor()
            in PYTHON_FILE_EXTENSIONS -> PythonExtractor()
            else -> EmptyExtractor()
        }
    }

    override fun extract(diffs: List<DiffContent>): List<CommitStats> {
        return diffs.groupBy { diff -> FileHelper.getFileExtension(diff.path) }
                .map { (extension, diffs) -> create(extension).extract(diffs) }
                .fold(mutableListOf<CommitStats>()) { accStats, stats ->
                    accStats.addAll(stats)
                    accStats
                }
    }
}
