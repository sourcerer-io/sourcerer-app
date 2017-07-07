// Copyright 2017 Sourcerer Inc. All Rights Reserved.

package app

import app.utils.Args
import app.utils.EmailValidator

class Greeter(args: Args) {
    var username: String? = args.username  // Sourcerer account username.
    var password: String? = args.password  // Sourcerer account password.
    var path: String? = args.path  // Path to analyzed repository.
    var silent: Boolean = args.silent  // Mode without displaying messages.

    fun run() {
        if (!silent) {
            println("Sourcerer app")
        }

        if (username == null) {
            println("Enter your Sourcerer username:")
            username = readLine()
        }
    }
}
