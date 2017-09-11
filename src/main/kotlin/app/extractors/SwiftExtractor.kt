// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class SwiftExtractor : ExtractorInterface {
    companion object {
        val LANGUAGE_NAME = "swift"
        val FILE_EXTS = listOf("swift")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val libraries = mutableSetOf<String>()

        val regex = Regex("""import\s+(\w+)""")
        fileContent.forEach {
            val res = regex.find(it)
            if (res != null) {
                val lineLib = res.groupValues[1]
                libraries.add(lineLib)
            }
        }

        return libraries.toList()
    }
}
