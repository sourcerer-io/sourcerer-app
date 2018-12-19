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
import app.utils.EmptyRepoException
import app.utils.FileHelper.toPath
import app.utils.HashingException
import app.utils.RepoHelper
import app.utils.batch
import org.eclipse.jgit.api.Git
import java.io.File
import java.io.IOException
import kotlin.collections.HashSet

class RepoHasher(private val api: Api,
                 private val configurator: Configurator) {
    fun update(localRepo: LocalRepo) {
        Logger.debug { "RepoHasher.update call: $localRepo" }
        val processEntryId = localRepo.processEntryId

        if (!RepoHelper.isValidRepo(localRepo.path.toPath())) {
            // TODO(anatoly): Send empty repo.
            throw IllegalArgumentException("Invalid repo $localRepo")
        }

        val git = loadGit(localRepo.path)
        try {
            Logger.info { "Hashing of repo started" }
            updateProcess(processEntryId, Api.PROCESS_STATUS_START)

            val (rehashes, authors, commitsCount) =
                CommitCrawler.fetchRehashesAndAuthors(git)
            localRepo.parseGitConfig(git.repository.config)
            val serverRepo = initServerRepo(localRepo, rehashes.last,
                processEntryId)

            // Get repo setup (commits, emails to hash) from server.
            postRepoFromServer(serverRepo)

            // Send all repo emails for invites.
            postAuthorsToServer(authors, serverRepo)

            // Choose emails to filter commits with.
            val emails = authors.map { author -> author.email }.toHashSet()
            val filteredEmails = if (localRepo.hashAllContributors) {
                emails
            } else {
                filterEmails(emails, serverRepo)
            }

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
                rehashes.size, filteredEmails = crawlerEmails,
                extractCoauthors = true
            ).publish()
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
                val userEmail = configurator.getUser().emails.map { it.email }
                MetaHasher(serverRepo, api)
                    .calculateAndSendFacts(authors = authors,
                                           commitsCount = commitsCount,
                                           userEmails = userEmail)
            }
            if (BuildConfig.DISTANCES_ENABLED) {
                val userEmails = configurator.getUser().emails.map { it.email }.toHashSet()
                val pathsObservable = CommitCrawler.getJGitObservable(git,
                        extractCommit = false, extractDate = true,
                        extractDiffs = false, extractEmail = true,
                        extractPaths = true)
                AuthorDistanceHasher(serverRepo, api, emails, userEmails)
                        .updateFromObservable(pathsObservable, onError)
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
        } catch (e: EmptyRepoException) {
            updateProcess(processEntryId, Api.PROCESS_STATUS_FAIL,
                Api.PROCESS_ERROR_EMPTY_REPO)
            throw e
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

    private fun postRepoFromServer(serverRepo: Repo) {
        val repo = api.postRepo(serverRepo).getOrThrow()
        serverRepo.commits = repo.commits
        Logger.info {
            "Received repo from server with ${serverRepo.commits.size} commits"
        }
        Logger.debug { serverRepo.toString() }
    }

    private fun postAuthorsToServer(authors: HashSet<Author>,
                                    serverRepo: Repo) {
        authors.forEach { author -> author.repo = serverRepo }
        for (authorsBatch in authors.asSequence().batch(1000)) {
            api.postAuthors(authorsBatch).onErrorThrow()
        }
    }

    private fun initServerRepo(localRepo: LocalRepo,
                               initCommitRehash: String,
                               processEntryId: Int?): Repo {
        val rehash = RepoHelper.calculateRepoRehash(initCommitRehash, localRepo)
        val repo = Repo(initialCommitRehash = initCommitRehash,
                        rehash = rehash,
                        meta = localRepo.meta,
                        processEntryId = processEntryId ?: 0)
        Logger.debug { "Local repo path: ${localRepo.path}" }
        Logger.debug { "Repo remote: ${localRepo.remoteOrigin}" }
        Logger.debug { "Repo rehash: $rehash" }
        return repo
    }

    private fun filterEmails(emails: HashSet<String>,
                             serverRepo: Repo): HashSet<String> {
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
