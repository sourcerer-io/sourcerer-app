// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.utils.FileHelper
import org.eclipse.jgit.diff.DiffEntry

class DiffFile(
    val path: String = "",
    val changeType: DiffEntry.ChangeType,
    val old: DiffContent = DiffContent(),
    val new: DiffContent = DiffContent(),
    var lang: String = ""
) {
    val extension: String = FileHelper.getFileExtension(path)

    fun getAllAdded(): List<String> {
        return new.getAllDiffs()
    }

    fun getAllDeleted(): List<String> {
        return old.getAllDiffs()
    }
}
