// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile
import java.io.File

class CSharpExtractor : ExtractorInterface {
    companion object {
        val LANGUAGE_NAME = "cs"
        val FILE_EXTS = listOf("cs")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val libraries = mutableSetOf<String>()

        // TODO(anatoly): Load file statically.
        val csLibraries = File("data/libraries/cs_libraries.txt")
            .inputStream().bufferedReader()
            .readLines()
            .toSet()

        val regex = Regex("""using\s+(\w+[.\w+]*)""")
        fileContent.forEach {
            val res = regex.find(it)
            if (res != null) {
                val importedName = res.groupValues[1]
                csLibraries.forEach { library ->
                    if (importedName.startsWith(library)) {
                        libraries.add(library)
                    }
                }
            }
        }

        return libraries.toList()
    }
}
