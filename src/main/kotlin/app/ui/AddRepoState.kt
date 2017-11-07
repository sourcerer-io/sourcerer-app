// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.Logger
import app.api.Api
import app.config.Configurator
import app.model.LocalRepo
import app.utils.RepoHelper
import app.utils.UiHelper

/**
 * Add repository dialog console UI state.
 */
class AddRepoState constructor(private val context: Context,
                               private val api: Api,
                               private val configurator: Configurator)
    : ConsoleState {
    override fun doAction() {
        if (configurator.getLocalRepos().isNotEmpty()) return

        while (true) {
            println("Type a path to repository, or hit Enter to start "
                    + "hashing.")
            val pathString = readLine() ?: ""

            if (pathString.isEmpty()) {
                if (configurator.getLocalRepos().isEmpty()) {
                    println("Add at least one valid repository.")
                } else {
                    break // User finished to add repos.
                }
            } else {
                if (RepoHelper.isValidRepo(pathString)) {
                    println("Added git repository at $pathString.")
                    val localRepo = LocalRepo(pathString)
                    localRepo.hashAllContributors = UiHelper.confirm("Do you "
                        + "want to hash commits of all contributors?",
                        defaultIsYes = true)
                    configurator.addLocalRepoPersistent(localRepo)
                    configurator.saveToFile()
                } else {
                    println("Directory should contain valid git repository.")
                    println("Make sure that master branch with at least one " +
                        "commit exists.")
                }
            }
        }

        Logger.info(Logger.Events.CONFIG_SETUP) { "Config setup" }
    }

    override fun next() {
        context.changeState(UpdateRepoState(context, api, configurator))
    }
}
