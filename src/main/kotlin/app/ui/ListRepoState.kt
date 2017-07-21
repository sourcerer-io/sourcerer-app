// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.Configurator
import app.utils.RepoHelper

/**
 * List tracked repositories console UI state.
 */
class ListRepoState constructor(val context: Context) : ConsoleState {
    override fun doAction() {
        RepoHelper.printRepos(Configurator.getRepos(), "Tracked repositories:")
    }

    override fun next() {
        context.changeState(AddRepoState(context))
    }
}
