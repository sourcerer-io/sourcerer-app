// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.api.Api

/**
 * On application close console UI state.
 */
class CloseState constructor(private val context: Context,
                             private val api: Api) : ConsoleState {
    override fun doAction() {
        println("You could use console commands to control repositories. To "
                + "setup again run application with flag --setup. For more "
                + "info run application with flag --help.")
        // TODO(anatoly): Check for problems for display support message.
        println("Feel free to contact us on any problem by "
                + "support@sourcerer.io.")
    }

    override fun next() {
    }
}
