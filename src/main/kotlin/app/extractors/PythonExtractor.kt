// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class PythonExtractor : ExtractorInterface {
    companion object {
        const val LANGUAGE_NAME = Lang.PYTHON
        const val COMPREHENSION_MAP = "map"
        const val COMPREHENSION_LIST = "list"
        val docImportRegex = Regex("""^([^\n]*#|\s*\"\"\"|\s*import|""" +
            """\s*from)[^\n]*""")
        val commentRegex = Regex("""^(.*#).*""")
        val extractImportRegex = Regex("""(from\s+(\w+)[.\w+]*\s+import|""" +
            """import\s+(\w+(,\s*\w+)*))(as\s+)*""")
        val mapRegex = Regex("""(map\([^,]+?,)""")
        val listRegex = Regex("""\[.+? for .+? in .+?]""")
        val lineEndRegex = Regex(""",\s*""")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        val stats = super.extract(files).toMutableList()

        // List comprehension fun fact.
        val allAdded = files.map{ file -> file.getAllAdded() }.flatten()
        val allDeleted = files.map{ file -> file.getAllDeleted() }.flatten()

        val mapAllAdded = allAdded.fold(0) { total, line ->
            total + mapRegex.findAll(line).toList().size }
        val mapAllDeleted = allDeleted.fold(0) { total, line ->
            total + mapRegex.findAll(line).toList().size }

        val listAllAdded = allAdded.fold(0) { total, line ->
            total + listRegex.findAll(line).toList().size }
        val listAllDeleted = allDeleted.fold(0) { total, line ->
            total + listRegex.findAll(line).toList().size }

        if (mapAllAdded > 0 || mapAllDeleted > 0) {
            stats.add(CommitStats(
                mapAllAdded, mapAllDeleted, ExtractorInterface.TYPE_SYNTAX,
                tech = LANGUAGE_NAME + ExtractorInterface.SEPARATOR +
                    COMPREHENSION_MAP
            ))
        }

        if (listAllAdded > 0 || listAllDeleted > 0) {
            stats.add(CommitStats(
                listAllAdded, listAllDeleted, ExtractorInterface.TYPE_SYNTAX,
                tech = LANGUAGE_NAME + ExtractorInterface.SEPARATOR +
                    COMPREHENSION_LIST
            ))
        }

        return stats
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        val imports = mutableSetOf<String>()

        fileContent.forEach {
            val res = extractImportRegex.find(it)
            if (res != null) {
                val lineLibs = res.groupValues.last {
                    it != "" && !it.startsWith(',')
                }.split(lineEndRegex)
                imports.addAll(lineLibs)
            }
        }

        val filteredImports = imports.filter { import ->
            !import.endsWith("_pb") && !import.endsWith("_pb2")
        }.toMutableList()
        if (filteredImports.size < imports.size) {
            filteredImports.add("pb")
        }
        return filteredImports

    }

    override fun tokenize(line: String): List<String> {
        var newLine = docImportRegex.replace(line, "")
        newLine = commentRegex.replace(newLine, "")
        return super.tokenize(newLine)
    }

    override fun getLanguageName(): String? {
        return LANGUAGE_NAME
    }
}
