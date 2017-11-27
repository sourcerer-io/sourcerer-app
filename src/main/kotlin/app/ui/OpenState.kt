// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.Logger
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
            Logger.print("Sourcerer hashes your git repositories into " +
                "intelligent engineering profiles.")
            Logger.print("If you don't have an account, please, sign up at " +
                    "https://sourcerer.io/join")
        } else {
            Logger.print("Sourcerer. Use flag --help to list available " +
                "commands.")
        }
    }

    override fun next() {
        context.changeState(AuthState(context, api, configurator))
    }
}
