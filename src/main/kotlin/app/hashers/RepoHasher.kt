// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.hashers

import app.Logger
import app.api.Api
import app.config.Configurator
import app.model.Author
import app.model.LocalRepo
import app.model.Repo
import app.utils.HashingException
import app.utils.RepoHelper
import org.apache.commons.codec.digest.DigestUtils
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.revwalk.RevCommit
import org.eclipse.jgit.revwalk.RevWalk
import java.io.File
import java.io.IOException
import java.util.*
import kotlin.collections.HashSet

class RepoHasher(private val localRepo: LocalRepo, private val api: Api,
                 private  val configurator: Configurator) {
    var serverRepo: Repo = Repo()

    init {
        if (!RepoHelper.isValidRepo(localRepo.path)) {
            throw IllegalArgumentException("Invalid repo $localRepo")
        }
    }

    fun update() {
        println("Hashing $localRepo...")
        Logger.info { "Hashing of repo started" }
        val git = loadGit(localRepo.path)
        try {
            val (rehashes, emails) = fetchRehashesAndEmails(git)

            localRepo.parseGitConfig(git.repository.config)
            if (localRepo.author.email.isBlank()) {
                throw IllegalStateException("Can't load email from Git config")
            }

            initServerRepo(rehashes.last)
            Logger.debug { "Local repo path: ${localRepo.path}" }
            Logger.debug { "Repo rehash: ${serverRepo.rehash}" }

            val filteredEmails = filterEmails(emails)

            if (!isKnownRepo()) {
                // Notify server about new contributor and his email.
                postRepoToServer()
            }

            // Send all repo emails for invites.
            postAuthorsToServer(emails)

            // Get repo setup (commits, emails to hash) from server.
            getRepoFromServer()

            // Common error handling for subscribers.
            // Exceptions can't be thrown out of reactive chain.
            val errors = mutableListOf<Throwable>()
            val onError: (Throwable) -> Unit = {
                e -> errors.add(e)
                Logger.error(e, "Hashing error")
            }

            // Hash by all plugins.
            val observable = CommitCrawler.getObservable(git, serverRepo)
                                          .publish()
            CommitHasher(serverRepo, api, rehashes, filteredEmails)
                .updateFromObservable(observable, onError)
            FactHasher(serverRepo, api, rehashes, filteredEmails)
                .updateFromObservable(observable, onError)

            // Start and synchronously wait until all subscribers complete.
            observable.connect()

            // TODO(anatoly): CodeLongevity hash from observable.
            try {
                CodeLongevity(serverRepo, filteredEmails, git).updateStats(api)
            }
            catch (e: Throwable) {
                onError(e)
            }

            // Confirm hashing completion.
            postRepoToServer()

            if (errors.isNotEmpty()) {
                throw HashingException(errors)
            }

            println("Hashing $localRepo completed.")
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

    private fun isKnownRepo(): Boolean {
        return configurator.getRepos()
            .find { it.rehash == serverRepo.rehash } != null
    }

    private fun getRepoFromServer() {
        val repo = api.getRepo(serverRepo.rehash).getOrThrow()
        serverRepo.commits = repo.commits
        Logger.info{
            "Received repo from server with ${serverRepo.commits.size} commits"
        }
        Logger.debug { serverRepo.toString() }
    }

    private fun postRepoToServer() {
        serverRepo.commits = listOf()
        api.postRepo(serverRepo).onErrorThrow()
        Logger.debug { serverRepo.toString() }
    }

    private fun postAuthorsToServer(emails: HashSet<String>) {
        api.postAuthors(emails.map { email ->
            Author(email=email, repo=serverRepo)
        }).onErrorThrow()
    }

    private fun initServerRepo(initCommitRehash: String) {
        serverRepo = Repo(userEmail = localRepo.author.email)
        serverRepo.initialCommitRehash = initCommitRehash
        serverRepo.rehash = RepoHelper.calculateRepoRehash(
            serverRepo.initialCommitRehash, localRepo)
    }

    private fun fetchRehashesAndEmails(git: Git):
        Pair<LinkedList<String>, HashSet<String>> {
        val head: RevCommit = RevWalk(git.repository)
            .parseCommit(git.repository.resolve(RepoHelper.MASTER_BRANCH))

        val revWalk = RevWalk(git.repository)
        revWalk.markStart(head)

        val commitsRehashes = LinkedList<String>()
        val emails = hashSetOf<String>()

        var commit: RevCommit? = revWalk.next()
        while (commit != null) {
            commitsRehashes.add(DigestUtils.sha256Hex(commit.name))
            emails.add(commit.authorIdent.emailAddress)
            commit.disposeBody()
            commit = revWalk.next()
        }
        revWalk.dispose()

        return Pair(commitsRehashes, emails)
    }

    private fun filterEmails(emails: HashSet<String>): HashSet<String> {
        if (localRepo.hashAllContributors) {
            return emails
        }

        val knownEmails = hashSetOf<String>()
        knownEmails.add(localRepo.author.email)
        knownEmails.add(serverRepo.userEmail)
        knownEmails.addAll(serverRepo.emails)

        return knownEmails.filter { emails.contains(it) }.toHashSet()
    }
}
