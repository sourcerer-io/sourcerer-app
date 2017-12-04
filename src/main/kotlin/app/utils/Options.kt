// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

import com.beust.jcommander.Parameter

class Options {
    // Sourcerer account username.
    @Parameter(names = arrayOf("-u", "--username"),
               description = "Sourcerer account username",
               order = 0)
    var username: String = ""

    // Sourcerer account password.
    @Parameter(names = arrayOf("-p", "--password"),
               description = "Sourcerer account password",
               order = 1)
    var password: String = ""

    // List options and commands.
    @Parameter(names = arrayOf("-h", "--help"),
               description = "List options and commands",
               order = 2)
    var help: Boolean = false

    // Cleanup configs and run setup again.
    @Parameter(names = arrayOf("--setup"),
               description = "Cleanup configs and run setup again",
               order = 3)
    var setup: Boolean = false

    // Uninstall. Runs by install script, added to display info in help.
    @Parameter(names = arrayOf("--uninstall"),
               description = "Remove Sourcerer App",
               order = 4)
    var uninstall: Boolean = false
}
