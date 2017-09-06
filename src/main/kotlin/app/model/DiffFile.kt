// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.utils.FileHelper

class DiffFile(
    val path: String = "",
    val contentOld: List<String> = listOf(),
    val contentNew: List<String> = listOf(),
    val imports: List<String> = listOf(),
    val language: String = "",
    val edits: List<DiffEdit> = listOf()
) {
    val extension: String = FileHelper.getFileExtension(path)

    fun getAllAdded(): List<String> {
        return edits.fold(mutableListOf()) { total, edit ->
            total.addAll(contentNew.subList(edit.addStart, edit.addEnd))
            total
        }
    }

    fun getAllDeleted(): List<String> {
        return edits.fold(mutableListOf()) { total, edit ->
            total.addAll(contentOld.subList(edit.delStart, edit.delEnd))
            total
        }
    }
}
