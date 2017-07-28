// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.Configurator
import app.RepoHasher

/**
 * Update repositories console UI state.
 */
class UpdateRepoState constructor(val context: Context) : ConsoleState {
    override fun doAction() {
        println("Hashing your git repositories.")
        for (repo in Configurator.getRepos()) {
            RepoHasher(repo).update()
        }
        println("The repositories have been hashed. See result online on your "
                + "Sourcerer profile.")
    }

    override fun next() {
        context.changeState(CloseState(context))
    }
}
