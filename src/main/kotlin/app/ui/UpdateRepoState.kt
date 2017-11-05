// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.hashers.RepoHasher
import app.Logger
import app.api.Api
import app.config.Configurator
import app.utils.HashingException

/**
 * Update repositories console UI state.
 */
class UpdateRepoState constructor(private val context: Context,
                                  private val api: Api,
                                  private val configurator: Configurator)
    : ConsoleState {
    override fun doAction() {
        println("Hashing your git repositories.")
        Logger.info { "Hashing started" }

        for (repo in configurator.getLocalRepos()) {
            try {
                RepoHasher(repo, api, configurator).update()
            } catch (e: HashingException) {
                e.errors.forEach { error ->
                    Logger.error(error, "Error while hashing")
                }
            } catch (e: Exception) {
                Logger.error(e, "Error while hashing")
            }
        }

        println("The repositories have been hashed. See result online on your "
                + "Sourcerer profile.")
        Logger.info(Logger.Events.HASHING_SUCCESS) { "Hashing success" }
    }

    override fun next() {
        context.changeState(CloseState())
    }
}
