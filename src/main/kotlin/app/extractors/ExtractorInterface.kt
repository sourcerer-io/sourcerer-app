// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.extractors

import app.model.DiffFile
import app.model.CommitStats

interface ExtractorInterface {
    fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file ->
            file.old.imports = extractImports(file.old.content)
            file.new.imports = extractImports(file.new.content)
            file
        }

        return files.filter { file -> file.language.isNotBlank() }
                    .groupBy { file -> file.language }
                    .map { (language, files) -> CommitStats(
                        numLinesAdded = files.fold(0) { total, file ->
                            total + file.getAllAdded().size },
                        numLinesDeleted = files.fold(0) { total, file ->
                            total + file.getAllDeleted().size },
                        type = Extractor.TYPE_LANGUAGE,
                        tech = language)}
    }

    fun extractImports(fileContent: List<String>): List<String> {
        return listOf()
    }
}
