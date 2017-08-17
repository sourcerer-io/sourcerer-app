// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.Configurator
import app.api.Api
import app.model.LocalRepo
import app.utils.RepoHelper
import app.utils.UiHelper

/**
 * Add repository dialog console UI state.
 */
class AddRepoState constructor(private val context: Context,
                               private val api: Api) : ConsoleState {
    override fun doAction() {
        if (Configurator.getLocalRepos().isNotEmpty()) return

        while (true) {
            println("Type a path to repository, or hit Enter to start "
                    + "hashing.")
            val pathString = readLine() ?: ""

            if (pathString.isEmpty()) {
                if (Configurator.getLocalRepos().isEmpty()) {
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
                    Configurator.addLocalRepoPersistent(localRepo)
                    Configurator.saveToFile()
                } else {
                    println("No valid git repository found at $pathString.")
                }
            }
        }
    }

    override fun next() {
        context.changeState(UpdateRepoState(context, api))
    }
}
