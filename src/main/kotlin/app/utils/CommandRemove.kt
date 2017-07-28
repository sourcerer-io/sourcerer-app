// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

import com.beust.jcommander.Parameter
import com.beust.jcommander.Parameters

@Parameters(separators = "=",
            commandDescription = "Remove a repository from tracking list")
class CommandRemove {
    // Command name for CLI.
    val name = "remove"

    // Path to analyzed repository.
    @Parameter(description = "REPOPATH")
    var path: String? = null
}
