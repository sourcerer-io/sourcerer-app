// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

import com.beust.jcommander.Parameter
import com.beust.jcommander.Parameters

@Parameters(separators = "=",
            commandDescription = "Configure Sourcerer app")
class CommandConfig {
    // Command name for CLI.
    val name = "config"

    // Key value pair of configurable parameters.
    @Parameter(description = "KEY VALUE", arity = 2, order = 0)
    var pair: List<String> = arrayListOf()
}
