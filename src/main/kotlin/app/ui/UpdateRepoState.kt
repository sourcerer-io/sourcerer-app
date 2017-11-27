// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.BuildConfig
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
        Logger.info { "Hashing started" }

        for (repo in configurator.getLocalRepos()) {
            try {
                Logger.print("Hashing $repo repository...", indentLine = true)
                RepoHasher(repo, api, configurator).update()
                Logger.print("Hashing $repo completed.")
            } catch (e: HashingException) {
                e.errors.forEach { error ->
                    Logger.error(error, "Error while hashing")
                }
            } catch (e: Exception) {
                Logger.error(e, "Error while hashing")
            }
        }

        api.postComplete().onErrorThrow()
        Logger.print("The repositories have been hashed.")
        Logger.print("Take a look at the updates in your profile at " +
            BuildConfig.PROFILE_URL + configurator.getUsername(),
            indentLine = true)
        Logger.info(Logger.Events.HASHING_SUCCESS) { "Hashing success" }
    }

    override fun next() {
        context.changeState(CloseState())
    }
}
