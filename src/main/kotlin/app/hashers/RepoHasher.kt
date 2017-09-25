// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.hashers

import app.Logger
import app.api.Api
import app.config.Configurator
import app.model.Author
import app.model.LocalRepo
import app.model.Repo
import app.utils.RepoHelper
import org.apache.commons.codec.digest.DigestUtils
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.revwalk.RevCommit
import org.eclipse.jgit.revwalk.RevWalk
import java.io.File
import java.io.IOException
import java.util.*

class RepoHasher(private val localRepo: LocalRepo, private val api: Api,
                 private  val configurator: Configurator) {
    var serverRepo: Repo = Repo()

    init {
        if (!RepoHelper.isValidRepo(localRepo.path)) {
            throw IllegalArgumentException("Invalid repo $localRepo")
        }

        println("Hashing $localRepo...")
        val git = loadGit(localRepo.path)
        try {
            val (rehashes, authors) = fetchRehashesAndAuthors(git)

            localRepo.parseGitConfig(git.repository.config)
            if (localRepo.author.email.isBlank()) {
                throw IllegalStateException("Can't load email from Git config")
            }

            initServerRepo(rehashes.last)

            if (!isKnownRepo()) {
                // Notify server about new contributor and his email.
                postRepoToServer()
            }
            // Get repo setup (commits, emails to hash) from server.
            getRepoFromServer()

            // Hash by all plugins.
            val observable = CommitCrawler.getObservable(git, serverRepo)
                                             .publish()
            CommitHasher(localRepo, serverRepo, api, rehashes)
                .updateFromObservable(observable)
            FactHasher(localRepo, serverRepo, api)
                .updateFromObservable(observable)
            // Start and synchronously wait until all subscribers complete.
            observable.connect()

            // TODO(anatoly): CodeLongevity hash from observable.
            CodeLongevity(localRepo, serverRepo, api, git)

            // Confirm hashing completion.
            postRepoToServer()
        }
        finally {
            closeGit(git)
        }
        println("Hashing $localRepo successfully finished.")
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
        serverRepo = api.getRepo(serverRepo.rehash)
        Logger.debug("Received repo from server with " +
            serverRepo.commits.size + " commits")
    }

    private fun postRepoToServer() {
        api.postRepo(serverRepo)
    }

    private fun initServerRepo(initCommitRehash: String) {
        serverRepo = Repo(userEmail = localRepo.author.email)
        serverRepo.initialCommitRehash = initCommitRehash
        serverRepo.rehash = RepoHelper.calculateRepoRehash(
            serverRepo.initialCommitRehash, localRepo)
    }

    private fun fetchRehashesAndAuthors(git: Git):
        Pair<LinkedList<String>, HashMap<String, Author>> {
        val head: RevCommit = RevWalk(git.repository)
            .parseCommit(git.repository.resolve(RepoHelper.MASTER_BRANCH))

        val revWalk = RevWalk(git.repository)
        revWalk.markStart(head)

        val commitsRehashes = LinkedList<String>()
        val contributors = hashMapOf<String, Author>()

        var commit: RevCommit? = revWalk.next()
        while (commit != null) {
            commitsRehashes.add(DigestUtils.sha256Hex(commit.name))
            if (!contributors.containsKey(commit.authorIdent.emailAddress)) {
                val author = Author(commit.authorIdent.name,
                                    commit.authorIdent.emailAddress)
                contributors.put(commit.authorIdent.emailAddress, author)
            }
            commit.disposeBody()
            commit = revWalk.next()
        }
        revWalk.dispose()

        return Pair(commitsRehashes, contributors)
    }
}
