// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.Configurator
import app.api.Api
import app.utils.RepoHelper

/**
 * List tracked repositories console UI state.
 */
class ListRepoState constructor(private val context: Context,
                                private val api: Api) : ConsoleState {
    override fun doAction() {
        RepoHelper.printRepos(Configurator.getLocalRepos(),
                "Tracked repositories:")
    }

    override fun next() {
        context.changeState(AddRepoState(context, api))
    }
}
