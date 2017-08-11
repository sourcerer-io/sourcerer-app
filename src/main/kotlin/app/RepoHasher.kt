// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app

import app.model.Author
import app.model.Commit
import app.model.LocalRepo
import app.model.Repo
import app.utils.RepoHelper
import io.reactivex.Observable
import org.apache.commons.codec.digest.DigestUtils
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.lib.Repository
import org.eclipse.jgit.revwalk.RevCommit
import org.eclipse.jgit.revwalk.RevWalk
import java.io.File
import java.io.IOException

// TODO(anatoly): Implement commit statistics.

/**
 * RepoHasher hashes repository and uploads stats to server.
 */
class RepoHasher(val localRepo: LocalRepo) {
    private var repo: Repo = Repo()
    private val git: Git? = loadGit()
    private val gitRepo: Repository? = git?.repository

    // Added and removed commits in local repo in comparison to server history.
    private var addedCommits: MutableList<Commit> = mutableListOf()
    private var removedCommits: MutableList<Commit> = mutableListOf()

    private val commitMapper: (RevCommit) -> Commit = { Commit(it) }

    private val emailFilter: (Commit) -> Boolean = {
        val email = it.author.email
        localRepo.hashAllAuthors || (email == localRepo.author.email ||
                repo.emails.contains(email))
    }

    private fun loadGit(): Git? {
        return try {
            Git.open(File(localRepo.path))
        } catch (e: IOException) {
            Logger.error("Cannot access repository at path "
                    + "$localRepo.path", e)
            null
        }
    }

    private fun closeGit() {
        gitRepo?.close()
        git?.close()
    }


    /* To identify and distinguish different repos we calculate its rehash.
    Repos may have forks. Such repos should be tracked independently.
    Therefore, rehash of repo calculated by values of:
    - Rehash of initial commit;
    - Hash of remote origin;
    - If remote origin not presented: repo local path and username.
    To associate forked repos with primary repo rehash of initial commit
    stored separately too. */
    private fun getRepoRehashes() {
        val initialRevCommit = getObservableRevCommits().blockingLast()
        repo.initialCommitRehash  = Commit(initialRevCommit).rehash

        var repoRehash = repo.initialCommitRehash
        if (localRepo.remoteOrigin.isNotBlank()) {
            repoRehash += localRepo.remoteOrigin
        } else {
            repoRehash += localRepo.path + localRepo.userName
        }

        repo.rehash = DigestUtils.sha256Hex(repoRehash)
    }

    private fun getRepoConfig() {
        gitRepo ?: return
        val config = gitRepo.getConfig()
        localRepo.author = Author(
                name = config.getString("user", null, "name") ?: "",
                email = config.getString("user", null, "email") ?: "")
        localRepo.remoteOrigin = config.getString("remote", "origin",
                "url") ?: ""
        localRepo.userName = try { System.getProperty("user.name") }
                             catch (e: Exception) { "" }
    }

    private fun isKnownRepo(): Boolean {
        if (Configurator.getRepos().find { it.rehash == repo.rehash } != null) {
            return true
        }
        return false
    }

    private fun rehashNewCommits() {
        addedCommits = mutableListOf()
        removedCommits = repo.commits.toMutableList()
        val lastServerCommit: Commit = repo.commits.last()
        var isLastServerCommitChecked: Boolean = false

        val commitsObservable = getObservableRevCommits()
        commitsObservable.map(commitMapper).filter(emailFilter)
                .filter { !isLastServerCommitChecked }
                .blockingSubscribe({  // OnNext
            Logger.info("Commit: ${it.rehash}")
            if (it == lastServerCommit) {
                isLastServerCommitChecked = true
            }
            if (removedCommits.contains(it)) {
                removedCommits.remove(it)
            } else {
                addedCommits.add(it)
            }
        }, { t ->  // OnError
            Logger.error("Error while hashing: $t")
        })
    }

    private fun rehashAllCommits() {
        addedCommits = mutableListOf()

        val commitsObservable = getObservableRevCommits()
        commitsObservable.map(commitMapper).filter(emailFilter)
                .blockingSubscribe({  // OnNext
            Logger.info("Commit: ${it.rehash}")
            addedCommits.add(it)
        }, { t ->  // OnError
            Logger.error("Error while hashing: $t")
        })
    }

    private fun getRepoFromServer() {
        repo = SourcererApi.getRepo(repo.rehash)
    }

    private fun sendRepoToServer() {
        SourcererApi.postRepo(repo)
    }

    private fun sendAddedCommits() {
        if (addedCommits.isNotEmpty()) {
            SourcererApi.postCommits(addedCommits)
        }
    }

    private fun sendRemovedCommits() {
        if (removedCommits.isNotEmpty()) {
            SourcererApi.deleteCommits(removedCommits)
        }
    }

    private fun getObservableRevCommits(): Observable<RevCommit> =
            Observable.create { subscriber ->
        if (gitRepo != null) {
            try {
                val revWalk = RevWalk(gitRepo)
                val commitId = gitRepo.resolve(RepoHelper.MASTER_BRANCH)
                revWalk.markStart(revWalk.parseCommit(commitId))
                for (commit in revWalk) {
                    Logger.debug("Commit produced: ${commit.name}")
                    subscriber.onNext(commit)
                }
            } catch (e: Exception) {
                Logger.error("Commit producing error", e)
                subscriber.onError(e)
            }
        } else {
            Logger.error("Repository not loaded")
        }
        Logger.debug("Commit producing completed")
        subscriber.onComplete()
    }

    fun update() {
        if (!RepoHelper.isValidRepo(localRepo.path)) {
            Logger.error("Invalid repo $localRepo")
            return
        }

        println("Hashing $localRepo...")
        getRepoConfig()
        getRepoRehashes()

        if (isKnownRepo()) {
            getRepoFromServer()
            rehashNewCommits()
            sendRemovedCommits()

            // Rehash all if all commits from server history removed.
            if (removedCommits.size == repo.commits.size) {
                rehashAllCommits()
            }
        } else {
            rehashAllCommits()
        }

        sendAddedCommits()
        sendRepoToServer()

        println("Hashing $localRepo successfully finished.")
        closeGit()
    }
}
