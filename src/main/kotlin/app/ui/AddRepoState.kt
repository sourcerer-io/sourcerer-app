// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.Logger
import app.api.Api
import app.config.Configurator
import app.model.LocalRepo
import app.utils.FileHelper.toPath
import app.utils.RepoHelper
import app.utils.UiHelper
import java.nio.file.Files
import java.nio.file.Path

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
            Logger.print("")
            Logger.print("Type one or more paths to repository. You can specify " +
                    "multiple repository paths separated by space on the same line.")
            Logger.print("If you finished specifying repositories, just hit 'Enter' to continue.")
            val pathsString = readLine() ?: ""

            if (pathsString.isEmpty()) {
                if (configurator.getLocalRepos().isEmpty()) {
                    Logger.print("Add at least one valid repository.")
                } else {
                    Logger.print("Finished processing git repositories")
                    break  // User finished to add repos.
                }
            } else {
                val paths: List<String> = pathsString.split(' ')
                paths.forEach {
                    val path = it.toPath()
                    if (RepoHelper.isValidRepo(path)) {
                        processPath(path)
                    } else {
                        Files.walk(path)
                                .filter { p -> RepoHelper.isValidGitRepo(p) }
                                .forEach { p -> processPath(p) }
                    }
                }
            }
        }

        Logger.info(Logger.Events.CONFIG_SETUP) { "Config setup" }
    }

    private fun processPath(path: Path) {
        if (RepoHelper.isValidRepo(path)) {
            Logger.print("Added git repository at $path.")
            val localRepo = LocalRepo(path.toString())
            localRepo.hashAllContributors = UiHelper.confirm("Do you "
                    + "want to hash commits of all contributors?",
                    defaultIsYes = true)
            configurator.addLocalRepoPersistent(localRepo)
            configurator.saveToFile()
            Logger.print("Successfully processed $path")
        } else {
            Logger.warn { "No valid git repository found at specified path $path" }
            Logger.print("Make sure that master branch with at least " +
                    "one commit exists.")
        }
    }

    override fun next() {
        context.changeState(EmailState(context, api, configurator))
    }
}
