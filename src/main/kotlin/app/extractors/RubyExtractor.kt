// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

class RubyExtractor : ExtractorInterface {
    companion object {
        const val LANGUAGE_NAME = Lang.RUBY
        val importRegex = Regex("""(require\s+'(\w+)'|load\s+'(\w+)\.\w+')""")
        val commentRegex = Regex("""^([^\n]*#)[^\n]*""")
        val extractImportRegex =
            Regex("""(require\s+'(\w+)'|load\s+'(\w+)\.\w+')""")
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        fileContent.forEach {
            val res = extractImportRegex.find(it)
            if (res != null) {
                val lineLib = res.groupValues.last { it != "" }
                imports.add(lineLib)
            }
        }

        return imports.toList()
    }

    override fun tokenize(line: String): List<String> {
        var newLine = importRegex.replace(line, "")
        newLine = commentRegex.replace(newLine, "")
        return super.tokenize(newLine)
    }

    override fun determineLibs(line: String,
                               importedLibs: List<String>): List<String> {
        // TODO(lyaronskaya): Case with no imports.
        val libraries = importedLibs + "rb.rails"

        return super.determineLibs(line, libraries)
    }

    override fun getLanguageName(): String? {
        return LANGUAGE_NAME
    }
}
