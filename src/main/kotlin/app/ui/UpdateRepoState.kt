// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.BuildConfig
import app.hashers.RepoHasher
import app.Logger
import app.Protos
import app.api.Api
import app.config.Configurator
import app.model.ProcessEntry
import app.utils.HashingException
import java.util.*
import kotlin.concurrent.fixedRateTimer

/**
 * Update repositories console UI state.
 */
class UpdateRepoState constructor(private val context: Context,
                                  private val api: Api,
                                  private val configurator: Configurator)
    : ConsoleState {
    override fun doAction() {
        Logger.info { "Hashing started" }

        val localRepos = configurator.getLocalRepos()
        val process = api.postProcessCreate(requestNumEntries = localRepos.size)
                         .getOrThrow()
        val processEntryIds = process.entries.map { entry -> entry.id }
        val heartbeatTimer = runHeartbeatTimer(processEntryIds)
        for ((index, repo) in localRepos.withIndex()) {
            try {
                Logger.print("Hashing $repo repository...", indentLine = true)
                val processEntryId = processEntryIds.elementAtOrNull(index)
                RepoHasher(repo, api, configurator, processEntryId).update()
                Logger.print("Hashing $repo completed.")
            } catch (e: HashingException) {
                e.errors.forEach { error ->
                    Logger.error(error, "Error while hashing")
                }
            } catch (e: Throwable) {
                Logger.error(e, "Error while hashing")
            }
        }
        heartbeatTimer.cancel()

        Logger.print("The repositories have been hashed.")
        Logger.print("Take a look at the updates in your profile at " +
            BuildConfig.PROFILE_URL + configurator.getUsername(),
            indentLine = true)
        Logger.info(Logger.Events.HASHING_SUCCESS) { "Hashing success" }
    }

    override fun next() {
        context.changeState(CloseState())
    }

    private fun runHeartbeatTimer(processEntryIds: List<Int>): Timer {
        val entries = processEntryIds.map { id -> ProcessEntry(id = id) }
        return fixedRateTimer(
            name = "heartbeat",
            daemon = true,
            initialDelay = BuildConfig.HEARTBEAT_RATE,
            period = BuildConfig.HEARTBEAT_RATE,
            action = {
                try {
                    api.postProcess(entries).onErrorThrow()
                } catch (e: Throwable) {
                    Logger.error(e)
                }
            }
        )
    }
}
