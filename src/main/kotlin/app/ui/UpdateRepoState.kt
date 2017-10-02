// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.Analytics
import app.hashers.RepoHasher
import app.Logger
import app.api.Api
import app.config.Configurator
import app.utils.HashingException
import app.utils.RequestException

/**
 * Update repositories console UI state.
 */
class UpdateRepoState constructor(private val context: Context,
                                  private val api: Api,
                                  private val configurator: Configurator)
    : ConsoleState {
    override fun doAction() {
        println("Hashing your git repositories.")
        for (repo in configurator.getLocalRepos()) {
            try {
                RepoHasher(repo, api, configurator).update()
            } catch (e: HashingException) {
                Logger.error("During hashing ${e.errors.size} errors occurred:")
                e.errors.forEach { error ->
                    Logger.error("", error)
                }
            } catch (e: Exception) {
                Logger.error("Error while hashing $repo", e)
            }
        }
        println("The repositories have been hashed. See result online on your "
                + "Sourcerer profile.")

        Analytics.trackHashingSuccess()
    }

    override fun next() {
        context.changeState(CloseState())
    }
}
