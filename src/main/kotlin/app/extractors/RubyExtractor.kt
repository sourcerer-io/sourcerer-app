// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class RubyExtractor : ExtractorInterface {
    companion object {
        val LANGUAGE_NAME = "ruby"
        val FILE_EXTS = listOf("rb", "rbw")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        val regex = Regex("""(require\s+'(\w+)'|load\s+'(\w+)\.\w+')""")
        fileContent.forEach {
            val res = regex.find(it)
            if (res != null) {
                val lineLib = res.groupValues.last { it -> it != "" }
                imports.add(lineLib)
            }
        }

        return imports.toList()
    }
}
