// Copyright 2019 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffContent
import app.model.DiffFile
import app.model.DiffRange
import org.json.JSONObject

class IPythonExtractor : ExtractorInterface{
    companion object {
        const val LANGUAGE_NAME = Lang.PYTHON
        private val pythonExtractor = PythonExtractor()
    }

    private fun getCodeContent(diffContent: DiffContent): DiffContent {
        if (diffContent.content.isEmpty()) {
            return diffContent
        }

        val code = JSONObject(
            diffContent.content.joinToString("\n"))
        .optJSONArray("cells")?.let {
            0.until(it.length()).map { i -> it.optJSONObject(i) }
        }?.filter {
            it.optString("cell_type") == "code"
        }?.filter {
            it.optJSONArray("source") != null
        }?.map { it.optJSONArray("source").map {line -> line.toString()}}

        val content = code?.fold(mutableListOf()) {
                acc: MutableList<String>, x: List<String> ->
                acc.addAll(x)
                acc
            } ?: listOf<String>()

        return DiffContent(content = content,
                           ranges = listOf(DiffRange(0, content.size)),
                           imports = diffContent.imports)
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.forEach { file ->
            file.old = getCodeContent(file.old)
            file.new = getCodeContent(file.new)
            file.lang = LANGUAGE_NAME
        }
        return pythonExtractor.extract(files)
    }

    override fun extractImports(fileContent: List<String>): List<String> {
        return pythonExtractor.extractImports(fileContent)
    }

    override fun tokenize(line: String): List<String> {
        return pythonExtractor.tokenize(line)
    }

    override fun getLanguageName(): String? {
        return LANGUAGE_NAME
    }
}
