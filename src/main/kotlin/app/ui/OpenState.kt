// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.Configurator

/**
 * On application open console UI state.
 */
class OpenState constructor(val context: Context) : ConsoleState {
    override fun doAction() {
        if (!Configurator.isValidCredentials()) {
            println("Sourcerer hashes your git repositories into intelligent "
                    + "engineering profiles. If you don't have an account, "
                    + "please, proceed to http://sourcerer.io/register.")
        } else {
            println("Sourcerer. Use flag --help to list available commands.")
        }
    }

    override fun next() {
        context.changeState(AuthState(context))
    }
}
