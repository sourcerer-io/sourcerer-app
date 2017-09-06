// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import org.eclipse.jgit.diff.Edit

/**
 * Edit is partial change of file. [delStart] (inclusive) and [delEnd]
 * (exclusive) specifies range of deleted lines in old content, [addStart]
 * (inclusive) and [addEnd] (exlusive) specifies range of added lines instead
 * of deleted lines. Made to decouple statistics classes from JGit.
 */
data class DiffEdit(val delStart: Int, val delEnd: Int,
                    val addStart: Int, val addEnd: Int) {
    constructor(edit: Edit) : this(edit.beginA, edit.endA,
                                   edit.beginB, edit.endB)
}
