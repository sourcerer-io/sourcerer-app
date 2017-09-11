// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class PythonExtractor : ExtractorInterface {
    companion object {
        val LANGUAGE_NAME = "python"
        val FILE_EXTS = listOf("py", "py3")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val libraries = mutableSetOf<String>()

        val regex =
            Regex("""(from\s+(\w+)[.\w+]*\s+import|import\s+(\w+[,\s*\w+]*))""")
        fileContent.forEach {
            val res = regex.find(it)
            if (res != null) {
                val lineLibs = res.groupValues.last { it != "" }
                    .split(Regex(""",\s*"""))
                libraries.addAll(lineLibs)
            }
        }

        return libraries.toList()
    }
}
