// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class Extractor : ExtractorInterface {
    companion object Constants {
        val TYPE_LANGUAGE = 1
        val TYPE_KEYWORD = 2

        val SEPARATOR = ">"

        val JAVASCRIPT_FILE_EXTS = listOf("js")
        val JAVA_FILE_EXTS = listOf("java")
        val PYTHON_FILE_EXTS = listOf("py", "py3")
        val RUBY_FILE_EXTS = listOf("rb", "rbw")
        val PHP_FILE_EXTS = listOf("php", "phtml", "php4", "php3", "php5",
                                   "phps")
        val C_FILE_EXTS = listOf("c")
        val CPP_FILE_EXTS = listOf("cc", "cpp", "cxx", "c++")
        val CS_FILE_EXTS = listOf("cs")
        val GO_FILE_EXTS = listOf("go")
        val OC_FILE_EXTS = listOf("h", "m", "mm")
        val SWIFT_FILE_EXTS = listOf("swift")
    }

    fun create(extension: String): ExtractorInterface {
        return when (extension) {
            in JAVASCRIPT_FILE_EXTS -> CommonExtractor("js")
            in JAVA_FILE_EXTS -> JavaExtractor()
            in PYTHON_FILE_EXTS -> CommonExtractor("python")
            in RUBY_FILE_EXTS -> CommonExtractor("ruby")
            in PHP_FILE_EXTS -> CommonExtractor("php")
            in C_FILE_EXTS -> CommonExtractor("c")
            in CPP_FILE_EXTS -> CommonExtractor("cpp")
            in CS_FILE_EXTS -> CommonExtractor("cs")
            in GO_FILE_EXTS -> CommonExtractor("go")
            in OC_FILE_EXTS -> CommonExtractor("oc")
            in SWIFT_FILE_EXTS -> CommonExtractor("swift")
            else -> EmptyExtractor()
        }
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        return files.groupBy { file -> file.extension }
            .map { (extension, files) -> create(extension).extract(files) }
            .fold(mutableListOf()) { accStats, stats ->
                accStats.addAll(stats)
                accStats
            }
    }
}
