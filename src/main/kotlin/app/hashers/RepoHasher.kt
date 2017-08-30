// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.hashers

import app.Logger
import app.api.Api
import app.config.Configurator
import app.model.LocalRepo
import app.model.Repo
import app.utils.RepoHelper
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.revwalk.RevCommit
import org.eclipse.jgit.revwalk.RevWalk
import java.io.File
import java.io.IOException

class RepoHasher(private val localRepo: LocalRepo, private val api: Api,
                 private  val configurator: Configurator) {
    var repo: Repo = Repo()

    init {
        if (!RepoHelper.isValidRepo(localRepo.path)) {
            throw IllegalArgumentException("Invalid repo $localRepo")
        }

        println("Hashing $localRepo...")
        val git = loadGit(localRepo.path)
        try {
            localRepo.parseGitConfig(git.repository.config)
            initializeRepo(git)

            if (!isKnownRepo()) {
                // Notify server about new contributor and his email.
                postRepoToServer()
            }
            // Get repo setup (commits, emails to hash) from server.
            getRepoFromServer()

            // Hash by all plugins.
            CommitHasher(localRepo, repo, api, configurator, git).update()
            CodeLongevity(localRepo, repo, api, configurator, git).update()

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
            .find { it.rehash == repo.rehash } != null
    }

    private fun getRepoFromServer() {
        repo = api.getRepo(repo.rehash)
        Logger.debug("Received repo from server with ${repo.commits.size} " +
            "commits")
    }

    private fun postRepoToServer() {
        api.postRepo(repo)
    }

    private fun initializeRepo(git: Git) {
        repo = Repo(userEmail = localRepo.author.email)
        repo.initialCommitRehash = getInitialCommitRehash(git)
        repo.rehash = RepoHelper.calculateRepoRehash(repo.initialCommitRehash,
            localRepo)
    }

    private fun getInitialCommitRehash(git: Git): String {
        val head: RevCommit = RevWalk(git.repository)
            .parseCommit(git.repository.resolve(RepoHelper.MASTER_BRANCH))

        val revWalk = RevWalk(git.repository)
        revWalk.markStart(head)

        val initialCommit = revWalk.last()
        return initialCommit.id.name
    }
}
