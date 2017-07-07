// Copyright 2017 Sourcerer Inc. All Rights Reserved.

package app.utils

import com.beust.jcommander.Parameter

class Args {
    // Sourcerer account username.
    @Parameter(names = arrayOf("-n", "--username"),
            validateWith = arrayOf(UsernameValidator::class),
            description = "Sourcerer account username")
    var username: String? = null

    // Sourcerer account password.
    @Parameter(names = arrayOf("-pw", "--password"),
            validateWith = arrayOf(PasswordValidator::class),
            description = "Sourcerer account password")
    var password: String? = null

    // Path to analyzed repository.
    @Parameter(names = arrayOf("-p", "--path"),
            validateWith = arrayOf(PathValidator::class),
            description = "Repository path")
    var path: String? = null

    // Mode without displaying messages.
    @Parameter(names = arrayOf("-s", "--silent"),
            description = "Silent mode")
    var silent: Boolean = false
}
