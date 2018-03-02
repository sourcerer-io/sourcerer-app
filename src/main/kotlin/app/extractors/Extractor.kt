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
            val set =
                CommonExtractor.FILE_EXTS_MAP.value.keys +
                CExtractor.FILE_EXTS +
                CppExtractor.FILE_EXTS +
                CSharpExtractor.FILE_EXTS +
                CssExtractor.FILE_EXTS +
                GoExtractor.FILE_EXTS +
                JavaExtractor.FILE_EXTS +
                JavascriptExtractor.FILE_EXTS +
                KotlinExtractor.FILE_EXTS +
                ObjectiveCExtractor.FILE_EXTS +
                PhpExtractor.FILE_EXTS +
                PythonExtractor.FILE_EXTS +
                RubyExtractor.FILE_EXTS +
                SwiftExtractor.FILE_EXTS

            return set.toHashSet()
        }
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
            in KotlinExtractor.FILE_EXTS -> KotlinExtractor()
            in CssExtractor.FILE_EXTS -> CssExtractor()
            else -> CommonExtractor()
        }
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        return files.groupBy { file -> file.extension }
            .filter { (extension, _) -> !RESTRICTED_EXTS.contains(extension) }
            .map { (extension, files) -> create(extension).extract(files) }
            .fold(mutableListOf()) { accStats, stats ->
                accStats.addAll(stats)
                accStats
            }
    }
}
