// Copyright 2019 Sourcerer Inc. All Rights Reserved.
// Author: Nickolas Gupton (nickolas@gupton.xyz)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class DMExtractor : ExtractorInterface {
    companion object {
        const val LANGUAGE_NAME = Lang.DM
    }

    override fun extractLibStats(files: List<DiffFile>): List<CommitStats> {
        val mapExtension = ".dmm"
        val spriteExtension = ".dmi"

        val mapFiles = files.filter { it.path.endsWith(mapExtension) }
        val spriteFiles = files.filter { it.path.endsWith(spriteExtension) }

        // Add stats from *.dmm files.
        val mapStats = listOf(CommitStats(
            numLinesAdded = mapFiles.map { it.getAllAdded().size }.sum(),
            numLinesDeleted = mapFiles.map { it.getAllDeleted().size }.sum(),
            type = ExtractorInterface.TYPE_LIBRARY,
            tech = "dm.byond-mapping"
        )).filter { it.numLinesAdded > 0 || it.numLinesDeleted > 0 }

        // Add stats from *.dmi files.
        val spriteStats = listOf(CommitStats(
            numLinesAdded = spriteFiles.map { it.getAllAdded().size }.sum(),
            numLinesDeleted = spriteFiles.map { it.getAllDeleted().size }.sum(),
            type = ExtractorInterface.TYPE_LIBRARY,
            tech = "dm.byond-sprites"
        )).filter { it.numLinesAdded > 0 || it.numLinesDeleted > 0 }

        return mapStats + spriteStats;
    }

    override fun getLanguageName(): String? {
        return LANGUAGE_NAME
    }
}
