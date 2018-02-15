// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.hashers

import app.BuildConfig
import app.Logger
import app.api.Api
import app.config.Configurator
import app.model.Author
import app.model.LocalRepo
import app.model.ProcessEntry
import app.model.Repo
import app.utils.FileHelper.toPath
import app.utils.HashingException
import app.utils.RepoHelper
import org.eclipse.jgit.api.Git
import java.io.File
import java.io.IOException
import kotlin.collections.HashSet

class RepoHasher(private val localRepo: LocalRepo, private val api: Api,
                 private val configurator: Configurator,
                 private val processEntryId: Int? = null) {
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
            updateProcess(processEntryId, Api.PROCESS_STATUS_START)
            val (rehashes, authors) = CommitCrawler.fetchRehashesAndAuthors(git)

            localRepo.parseGitConfig(git.repository.config)
            initServerRepo(rehashes.last)
            Logger.debug { "Local repo path: ${localRepo.path}" }
            Logger.debug { "Repo remote: ${localRepo.remoteOrigin}" }
            Logger.debug { "Repo rehash: ${serverRepo.rehash}" }

            // Get repo setup (commits, emails to hash) from server.
            postRepoFromServer()

            // Send all repo emails for invites.
            postAuthorsToServer(authors)

            val emails = authors.map { author -> author.email }.toHashSet()
            val filteredEmails = filterEmails(emails)

            // Common error handling for subscribers.
            // Exceptions can't be thrown out of reactive chain.
            val errors = mutableListOf<Throwable>()
            val onError: (Throwable) -> Unit = {
                e -> errors.add(e)
                Logger.error(e, "Hashing error")
            }

            // Only code longevity needs to calculate each commit, if it's
            // disabled then read only author's emails.
            val crawlerEmails = if (!BuildConfig.LONGEVITY_ENABLED) {
                filteredEmails
            } else null
            val jgitObservable = CommitCrawler.getJGitObservable(git,
                rehashes.size, crawlerEmails).publish()
            val observable = CommitCrawler.getObservable(git,
                jgitObservable, serverRepo)

            // Hash by all plugins.
            if (BuildConfig.COMMIT_HASHER_ENABLED) {
                CommitHasher(serverRepo, api, rehashes, filteredEmails)
                    .updateFromObservable(observable, onError)
            }
            if (BuildConfig.FACT_HASHER_ENABLED) {
                FactHasher(serverRepo, api, rehashes, filteredEmails)
                    .updateFromObservable(observable, onError)
            }
            if (BuildConfig.LONGEVITY_ENABLED) {
                CodeLongevity(serverRepo, filteredEmails, git)
                    .updateFromObservable(jgitObservable, onError, api)
            }
            if (BuildConfig.META_HASHER_ENABLED) {
                MetaHasher(serverRepo, api)
                    .calculateAndSendFacts(authors)
            }

            // Start and synchronously wait until all subscribers complete.
            Logger.print("Stats computation. May take a while...")
            jgitObservable.connect()

            if (errors.isNotEmpty()) {
                throw HashingException(errors)
            }
            Logger.info(Logger.Events.HASHING_REPO_SUCCESS)
                { "Hashing repo completed" }
            updateProcess(processEntryId, Api.PROCESS_STATUS_COMPLETE)
        } catch (e: Throwable) {
            updateProcess(processEntryId, Api.PROCESS_STATUS_FAIL)
            throw e
        } finally {
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

    private fun postAuthorsToServer(authors: HashSet<Author>) {
        api.postAuthors(authors.map { author ->
            author.repo = serverRepo
            author
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

    private fun updateProcess(processEntryId: Int?, status: Int,
                              errorCode: Int = 0) {
        if (processEntryId == null) {
            return
        }

        val processEntry = ProcessEntry(id = processEntryId, status = status,
            errorCode = errorCode)
        api.postProcess(listOf(processEntry)).onErrorThrow()
    }
}
