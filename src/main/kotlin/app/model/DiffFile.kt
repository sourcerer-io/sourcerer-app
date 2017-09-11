// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.utils.FileHelper

class DiffFile(
    val path: String = "",
    val old: DiffContent = DiffContent(),
    val new: DiffContent = DiffContent(),
    var language: String = ""
) {
    val extension: String = FileHelper.getFileExtension(path)

    fun getAllAdded(): List<String> {
        return new.getAllDiffs()
    }

    fun getAllDeleted(): List<String> {
        return old.getAllDiffs()
    }
}
