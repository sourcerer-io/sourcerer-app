// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import org.eclipse.jgit.diff.Edit

/**
 * Edit is partial change of file. [del] specifies range of deleted lines in old
 * content, [add] specifies range of added lines instead of deleted lines.
 * Made to decouple statistics classes from JGit.
 */
data class DiffEdit(val del: DiffRange, val add: DiffRange) {
    constructor(edit: Edit) : this(DiffRange(edit.beginA, edit.endA),
                                   DiffRange(edit.beginB, edit.endB))
}
