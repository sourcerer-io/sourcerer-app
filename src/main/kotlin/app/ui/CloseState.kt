// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.Logger

/**
 * On application close console UI state.
 */
class CloseState : ConsoleState {
    override fun doAction() {
        Logger.print("You could use console commands to control repositories.",
            indentLine = true)
        Logger.print("For more info run application with flag --help.")
        // TODO(anatoly): Check for problems for display support message.
        Logger.print("Feel free to contact us on any problem by " +
            "support@sourcerer.io.")
    }

    override fun next() {
    }
}
