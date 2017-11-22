package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class KotlinExtractor : ExtractorInterface {
    companion object {
        val LANGUAGE_NAME = "kotlin"
        val FILE_EXTS = listOf("kt")
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.map { file -> file.language = LANGUAGE_NAME }
        return super.extract(files)
    }
}
