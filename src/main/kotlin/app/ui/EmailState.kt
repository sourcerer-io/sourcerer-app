// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.Logger
import app.api.Api
import app.config.Configurator
import app.hashers.CommitCrawler
import app.model.LocalRepo
import app.model.User
import app.model.UserEmail
import app.utils.UiHelper
import org.eclipse.jgit.api.Git
import java.io.File

/**
 * Update repositories console UI state.
 */
class EmailState constructor(private val context: Context,
                             private val api: Api,
                             private val configurator: Configurator)
    : ConsoleState {
    override fun doAction() {
        val user = configurator.getUser()

        if (user.emails.isNotEmpty()) {
            Logger.print("List of your emails:", indentLine = true)
            user.emails.forEach { email -> println(email) }
        } else {
            // Shouldn't really happen. User always have primary email.
            Logger.print("Add at least one email to build your profile.",
                indentLine = true)
        }

        val knownEmails = user.emails.map { it.email }
        val newEmails = hashSetOf<String>()
        val configEmails = hashSetOf<String>()
        // TODO(anatoly): Tell about web editing emails, when it's ready.
        // TODO(anatoly): Add global config parsing.
        // TODO(anatoly): Add user config parsing.

        // Add emails from git configs.
        val reposEmails = hashMapOf<LocalRepo, HashSet<String>>()
        for (repo in configurator.getLocalRepos()) {
            var git: Git? = null
            try {
                git = Git.open(File(repo.path))
                var email = git.repository.config
                               .getString("user", null, "email") ?: ""
                email = email.toLowerCase()
                if (email.isNotEmpty() && !knownEmails.contains(email)) {
                    configEmails.add(email)
                }
                // Fetch and save emails from repo for "no-email" warning.
                val (_, authors) = CommitCrawler.fetchRehashesAndAuthors(git)
                reposEmails.put(repo, authors.map { it.email }.toHashSet())
            } catch (e: Exception) {
                Logger.error(e, "Error while parsing repo")
            } finally {
                if (git != null) {
                    git.repository?.close()
                    git.close()
                }
            }
        }

        if (configEmails.isNotEmpty()) {
            Logger.print("Your git config contains untracked emails:")
            configEmails.forEach { email -> println(email) }
            if (UiHelper.confirm("Do you want to add this emails to your " +
                "account?", defaultIsYes = true)) {
                newEmails.addAll(configEmails)
            }
        }

        // Show warning if no commits
        val reposUserMissing = mutableListOf<LocalRepo>()
        for (repo in configurator.getLocalRepos()) {
            val presentedEmails = reposEmails.get(repo)
            val updatedEmails = knownEmails + newEmails
            if (presentedEmails != null) {
                var userMissing = true
                for (email in presentedEmails) {
                    if (updatedEmails.contains(email)) {
                        userMissing = false
                        break
                    }
                }
                if (userMissing) {
                    reposUserMissing.add(repo)
                }
            }
        }
        if (reposUserMissing.isNotEmpty()) {
            if (reposUserMissing.size == 1) {
                Logger.print("${reposUserMissing.first()} repo does not " +
                    "contains commits from emails you've specified")
            } else {
                Logger.print("Following repos do not contain commits from " +
                    "emails you've specified:")
                reposUserMissing.forEach { Logger.print(it) }
            }
        }

        // Ask user to enter his emails.
        if (UiHelper.confirm("Do you want to specify additional emails " +
            "that you use in repositories?", defaultIsYes = false)) {
            while (true) {
                Logger.print("Type a email, or hit Enter to continue.")
                val email = (readLine() ?: "").toLowerCase()
                if (email.isBlank()) break
                if (!knownEmails.contains(email)) newEmails.add(email)
            }
        }

        if (newEmails.isNotEmpty()) {
            val newUserEmails = newEmails.map { UserEmail(email = it) }
            // We will need new emails during hashing.
            user.emails.addAll(newUserEmails)

            // Send new emails to server.
            val userNewEmails = User(emails = newUserEmails.toHashSet())
            api.postUser(userNewEmails)
        }

        // Warn user about need of confirmation.
        if (user.emails.filter { email -> !email.verified }.isNotEmpty() ||
            newEmails.isNotEmpty()) {
            Logger.print("Confirm your emails to show all statistics in " +
                "profile.")
        }
    }

    override fun next() {
        context.changeState(UpdateRepoState(context, api, configurator))
    }
}
