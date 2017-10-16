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
        val SEPARATOR = ">"
    }

    fun create(extension: String): ExtractorInterface {
        return when (extension) {
            in JavascriptExtractor.FILE_EXTS -> JavascriptExtractor()
            in JavaExtractor.FILE_EXTS -> JavaExtractor()
            in PythonExtractor.FILE_EXTS -> PythonExtractor()
            in RubyExtractor.FILE_EXTS -> RubyExtractor()
            in PhpExtractor.FILE_EXTS -> PhpExtractor()
            in CExtractor.FILE_EXTS -> CExtractor()
            in CppExtractor.FILE_EXTS -> CppExtractor()
            in CSharpExtractor.FILE_EXTS -> CSharpExtractor()
            in GoExtractor.FILE_EXTS -> GoExtractor()
            in ObjectiveCExtractor.FILE_EXTS -> ObjectiveCExtractor()
            in SwiftExtractor.FILE_EXTS -> SwiftExtractor()
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
