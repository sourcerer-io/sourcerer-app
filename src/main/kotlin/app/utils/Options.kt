// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

import com.beust.jcommander.Parameter

class Options {
    // Sourcerer account username.
    @Parameter(names = arrayOf("-u", "--username"),
            validateWith = arrayOf(UsernameValidator::class),
            description = "Sourcerer account username",
            order = 0)
    var username: String? = null

    // Sourcerer account password.
    @Parameter(names = arrayOf("-p", "--password"),
            description = "Sourcerer account password",
            password = true,
            order = 1)
    var password: String? = null

    // Mode without displaying messages.
    @Parameter(names = arrayOf("-s", "--silent"),
            description = "Silent mode",
            order = 2)
    var silent: Boolean? = null
}
