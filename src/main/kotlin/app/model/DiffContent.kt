// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import java.nio.file.Path
import java.nio.file.Paths

/**
 * Per file diff from commit.
 */
data class DiffContent(
        var path: Path = Paths.get(""),
        var added: List<String> = listOf(),
        var deleted: List<String> = listOf()
)
