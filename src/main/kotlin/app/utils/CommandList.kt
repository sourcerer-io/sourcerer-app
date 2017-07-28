// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

import com.beust.jcommander.Parameters

@Parameters(separators = "=",
            commandDescription = "List tracked repositories")
class CommandList {
    // Command name for CLI.
    val name = "list"
}
