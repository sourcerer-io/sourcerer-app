package app.ui

import app.Logger
import app.api.Api
import app.config.Configurator
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

        println("List of your emails:")
        user.emails.forEach { email -> println(email) }

        val knownEmails = user.emails.map { it.email }
        val newEmails = hashSetOf<String>()
        val configEmails = hashSetOf<String>()
        // TODO(anatoly): Tell about web editing emails, when it's ready.
        // TODO(anatoly): Add global config parsing.
        // TODO(anatoly): Add user config parsing.

        // Add emails from git configs.
        for (repo in configurator.getLocalRepos()) {
            try {
                val git = Git.open(File(repo.path))
                val email = git.repository
                               .config.getString("user", null, "email") ?: ""
                if (!knownEmails.contains(email)) {
                    configEmails.add(email)
                }
            } catch (e: Exception) {
                Logger.error(e, "Error while parsing git config")
            }
        }

        if (configEmails.isNotEmpty()) {
            println("Your git config contains untracked emails:")
            configEmails.forEach { email -> println(email) }
            if (UiHelper.confirm("Do you want to add this emails to your " +
                "account?", defaultIsYes = true)) {
                newEmails.addAll(configEmails)
            }
        }

        // Ask user to enter his emails.
        if (UiHelper.confirm("Do you want to specify additional emails " +
            "that you use in repositories?", defaultIsYes = false)) {
            while (true) {
                println("Type a email, or hit Enter to continue.")
                val email = readLine() ?: ""
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
            println("Confirm your emails to show all statistics in " +
                "profile.")
        }
    }

    override fun next() {
        context.changeState(UpdateRepoState(context, api, configurator))
    }
}
