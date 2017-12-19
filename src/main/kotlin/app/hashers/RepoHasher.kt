// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.hashers

import app.Logger
import app.api.Api
import app.config.Configurator
import app.model.Author
import app.model.LocalRepo
import app.model.Repo
import app.utils.FileHelper.toPath
import app.utils.HashingException
import app.utils.RepoHelper
import org.eclipse.jgit.api.Git
import java.io.File
import java.io.IOException
import kotlin.collections.HashSet

class RepoHasher(private val localRepo: LocalRepo, private val api: Api,
                 private val configurator: Configurator) {
    var serverRepo: Repo = Repo()

    init {
        if (!RepoHelper.isValidRepo(localRepo.path.toPath())) {
            throw IllegalArgumentException("Invalid repo $localRepo")
        }
    }

    fun update() {
        Logger.info { "Hashing of repo started" }
        val git = loadGit(localRepo.path)
        try {
            val (rehashes, emails) = CommitCrawler.fetchRehashesAndEmails(git)

            localRepo.parseGitConfig(git.repository.config)
            initServerRepo(rehashes.last)
            Logger.debug { "Local repo path: ${localRepo.path}" }
            Logger.debug { "Repo remote: ${localRepo.remoteOrigin}" }
            Logger.debug { "Repo rehash: ${serverRepo.rehash}" }

            // Get repo setup (commits, emails to hash) from server.
            postRepoFromServer()

            // Send all repo emails for invites.
            postAuthorsToServer(emails)

            val filteredEmails = filterEmails(emails)

            // Common error handling for subscribers.
            // Exceptions can't be thrown out of reactive chain.
            val errors = mutableListOf<Throwable>()
            val onError: (Throwable) -> Unit = {
                e -> errors.add(e)
                Logger.error(e, "Hashing error")
            }

            // Hash by all plugins.
            val jgitObservable =
                CommitCrawler.getJGitObservable(git, rehashes.size).publish()
            val observable =
                CommitCrawler.getObservable(git, jgitObservable, serverRepo)

            CommitHasher(serverRepo, api, rehashes, filteredEmails)
                .updateFromObservable(observable, onError)
            FactHasher(serverRepo, api, rehashes, filteredEmails)
                .updateFromObservable(observable, onError)
            CodeLongevity(serverRepo, filteredEmails, git)
                .updateFromObservable(jgitObservable, onError, api)

            // Start and synchronously wait until all subscribers complete.
            Logger.print("Stats computation. May take a while...")
            jgitObservable.connect()

            if (errors.isNotEmpty()) {
                throw HashingException(errors)
            }

            Logger.info(Logger.Events.HASHING_REPO_SUCCESS)
                { "Hashing repo completed" }
        }
        finally {
            closeGit(git)
        }
    }

    private fun loadGit(path: String): Git {
        return try {
            Git.open(File(path))
        } catch (e: IOException) {
            throw IllegalStateException("Cannot access repository at $path")
        }
    }

    private fun closeGit(git: Git) {
        git.repository?.close()
        git.close()
    }

    private fun postRepoFromServer() {
        val repo = api.postRepo(serverRepo).getOrThrow()
        serverRepo.commits = repo.commits
        Logger.info {
            "Received repo from server with ${serverRepo.commits.size} commits"
        }
        Logger.debug { serverRepo.toString() }
    }

    private fun postAuthorsToServer(emails: HashSet<String>) {
        api.postAuthors(emails.map { email ->
            Author(email = email, repo = serverRepo)
        }).onErrorThrow()
    }

    private fun initServerRepo(initCommitRehash: String) {
        serverRepo = Repo(initialCommitRehash = initCommitRehash,
                          rehash = RepoHelper.calculateRepoRehash(
                              initCommitRehash, localRepo))
    }

    private fun filterEmails(emails: HashSet<String>): HashSet<String> {
        if (localRepo.hashAllContributors) {
            return emails
        }

        val knownEmails = hashSetOf<String>()
        knownEmails.addAll(configurator.getUser().emails.map { it.email })
        knownEmails.addAll(serverRepo.emails)

        return knownEmails.filter { emails.contains(it) }.toHashSet()
    }
}
