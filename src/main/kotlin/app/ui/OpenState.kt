// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.api.Api
import app.config.Configurator

/**
 * On application open console UI state.
 */
class OpenState constructor(private val context: Context,
                            private val api: Api,
                            private val configurator: Configurator)
    : ConsoleState {
    override fun doAction() {
        if (!configurator.isValidCredentials()) {
            println("Sourcerer hashes your git repositories into intelligent "
                    + "engineering profiles. If you don't have an account, "
                    + "please, proceed to http://sourcerer.io/register.")
        } else {
            println("Sourcerer. Use flag --help to list available commands.")
        }
    }

    override fun next() {
        context.changeState(AuthState(context, api, configurator))
    }
}
