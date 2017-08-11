// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.Configurator
import app.model.LocalRepo
import app.utils.RepoHelper

/**
 * Add repository dialog console UI state.
 */
class AddRepoState constructor(val context: Context) : ConsoleState {
    override fun doAction() {
        if (Configurator.getLocalRepos().isEmpty()) return

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
                    Configurator.addLocalRepoPersistent(
                            LocalRepo(pathString))
                    Configurator.saveToFile()
                } else {
                    println("No valid git repository found at $pathString.")
                }
            }
        }
    }

    override fun next() {
        context.changeState(UpdateRepoState(context))
    }
}
