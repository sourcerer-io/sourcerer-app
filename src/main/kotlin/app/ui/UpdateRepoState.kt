// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.Configurator
import app.Logger
import app.RepoHasher
import app.api.Api
import app.utils.RequestException

/**
 * Update repositories console UI state.
 */
class UpdateRepoState constructor(private val context: Context,
                                  private val api: Api) : ConsoleState {
    override fun doAction() {
        println("Hashing your git repositories.")
        for (repo in Configurator.getLocalRepos()) {
            try {
                RepoHasher(repo, api).update()
            } catch (e: RequestException) {
                Logger.error("Network error while hashing $repo, "
                        + "skipping...", e)
            }
        }
        println("The repositories have been hashed. See result online on your "
                + "Sourcerer profile.")
    }

    override fun next() {
        context.changeState(CloseState(context, api))
    }
}
