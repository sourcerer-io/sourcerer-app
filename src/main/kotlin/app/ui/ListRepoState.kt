// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.api.Api
import app.config.Configurator
import app.utils.RepoHelper

/**
 * List tracked repositories console UI state.
 */
class ListRepoState constructor(private val context: Context,
                                private val api: Api,
                                private val configurator: Configurator)
    : ConsoleState {
    override fun doAction() {
        RepoHelper.printRepos(configurator.getLocalRepos(),
                "Tracked repositories:")
    }

    override fun next() {
        context.changeState(AddRepoState(context, api, configurator))
    }
}
