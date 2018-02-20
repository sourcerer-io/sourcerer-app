// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.BuildConfig
import app.hashers.RepoHasher
import app.Logger
import app.api.Api
import app.config.Configurator
import app.model.LocalRepo
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

        // TODO(anatoly): Move code to RepoHasher.
        val localRepos = configurator.getLocalRepos()
        assignProcess(localRepos)

        val heartbeatTimer = runHeartbeatTimer(localRepos)
        for (repo in localRepos) {
            try {
                Logger.print("Hashing $repo repository...", indentLine = true)
                RepoHasher(api, configurator).update(repo)
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

    // Notify server about processing start and get processing ids.
    private fun assignProcess(localRepos: List<LocalRepo>) {
        val process = api.postProcessCreate(requestNumEntries = localRepos.size)
            .getOrThrow()
        if (process.entries.isEmpty()) return
        process.entries.subList(0, localRepos.size).forEachIndexed { index, e ->
            localRepos[index].processEntryId = e.id
        }
    }

    private fun runHeartbeatTimer(localRepos: List<LocalRepo>): Timer {
        val entries = localRepos.filter { it.processEntryId != null}
                                .map { ProcessEntry(id = it.processEntryId!!) }
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
