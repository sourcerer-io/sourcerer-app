// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Tuomas Hietanen
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class FSharpExtractor : ExtractorInterface {
    companion object {
        const val LANGUAGE_NAME = Lang.FSharp
        // The behaviour of csharp library classifier is the same as for csharp.
        val LIBRARIES = ExtractorInterface.getLibraries("cs")
        val evaluator by lazy {
            ExtractorInterface.getLibraryClassifier("csharp")
        }
        val importRegex = Regex("""^.*open\s+(\w+[.\w+]*)""")
        val commentRegex = Regex("""^([^\n]*//)[^\n]*""")
        val extractImportRegex = Regex("""open\s+(\w+[.\w+]*)""")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        fileContent.forEach {
            val res = extractImportRegex.find(it)
            if (res != null) {
                val importedName = res.groupValues[1]
                LIBRARIES.forEach { library ->
                    if (importedName.startsWith(library)) {
                        imports.add(library)
                    }
                }
            }
        }

        return imports.toList()
    }

    override fun tokenize(line: String): List<String> {
        val importRegex = Regex("""^.*open\s+(\w+[.\w+]*)""")
        val commentRegex = Regex("""^([^\n]*//)[^\n]*""")
        var newLine = importRegex.replace(line, "")
        newLine = commentRegex.replace(newLine, "")
        return super.tokenize(newLine)
    }

    override fun getLineLibraries(line: String,
                                  fileLibraries: List<String>): List<String> {

        return super.getLineLibraries(line, fileLibraries, evaluator,
            LANGUAGE_NAME)
    }
}
