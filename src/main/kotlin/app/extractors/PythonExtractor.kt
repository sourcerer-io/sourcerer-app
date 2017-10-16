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
        val evaluator = ExtractorInterface.getLibrariesModelEvaluator(LANGUAGE_NAME)
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        val regex =
            Regex("""(from\s+(\w+)[.\w+]*\s+import|import\s+(\w+[,\s*\w+]*))""")
        fileContent.forEach {
            val res = regex.find(it)
            if (res != null) {
                val lineLibs = res.groupValues.last { it != "" }
                    .split(Regex(""",\s*"""))
                imports.addAll(lineLibs)
            }
        }

        return imports.toList()

    }

    override fun tokenize(line: String): List<String> {
        val docImportRegex = Regex("""^([^\n]*#|\s*\"\"\"|\s*import|\s*from)[^\n]*""")
        val commentRegex = Regex("""^(.*#).*""")
        var newLine = docImportRegex.replace(line, "")
        newLine = commentRegex.replace(newLine, "")
        return super.tokenize(newLine)
    }

    override fun getLineLibraries(line: String,
                                  fileLibraries: List<String>): List<String> {

        return super.getLineLibraries(line, fileLibraries, evaluator, LANGUAGE_NAME)
    }
}
