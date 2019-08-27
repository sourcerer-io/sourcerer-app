// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

import app.Logger
import app.hashers.CommitCrawler
import app.model.LocalRepo
import org.apache.commons.codec.digest.DigestUtils
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.lib.ObjectId
import org.eclipse.jgit.lib.Repository
import java.io.File
import java.nio.file.Files
import java.nio.file.InvalidPathException
import java.nio.file.Path
import java.nio.file.Paths

/**
 * Class for utility functions on repos.
 */
object RepoHelper {
    fun isValidRepo(path: Path): Boolean {
        if (!isDirectory(path)) {
            return false
        }

        var git: Git? = null
        var repository: Repository? = null
        val commitId: ObjectId?
        try {
            git = Git.open(path.toFile())
            repository = git.repository
            commitId = CommitCrawler.getDefaultBranchHead(git)
        } catch (e: Exception) {
            Logger.error(e, "Cannot access repository at specified path")
            return false
        } finally {
            repository?.close()
            git?.close()
        }

        if (commitId != null) {
            return true
        }
        return false
    }

    fun isDirectory(path: Path): Boolean {
        return try {
            path.toFile().isDirectory
        } catch (e: InvalidPathException) {
            Logger.error(e, "Invalid path")
            false
        } catch (e: UnsupportedOperationException) {
            Logger.error(e, "Invalid path")
            false
        } catch (e: SecurityException) {
            Logger.error(e, "Cannot access repository at specified path")
            false
        }
    }

    fun isValidGitRepo(p: Path) = (Files.isDirectory(p)
            && p.fileName.toString().equals(".git", ignoreCase = true))

    /* To identify and distinguish different repos we calculate its rehash.
    Repos may have forks. Such repos should be tracked independently.
    Therefore, rehash of repo calculated by values of:
    - Rehash of initial commit;
    - Hash of remote origin;
    - If remote origin not presented: repo local path and username.
    To associate forked repos with primary repo rehash of initial commit
    stored separately too. */
    fun calculateRepoRehash(initialCommitRehash: String,
                            localRepo: LocalRepo): String {
        val username = try { System.getProperty("user.name") }
                       catch (e: Exception) { "" }

        var repoRehash = initialCommitRehash
        if (localRepo.remoteOrigin.isNotBlank()) {
            repoRehash += localRepo.remoteOrigin
        } else {
            repoRehash += localRepo.path + username
        }

        return DigestUtils.sha256Hex(repoRehash)
    }

    fun printRepos(localRepos: List<LocalRepo>)
    {
        for (repo in localRepos) {
            Logger.print(repo)
        }
    }

    fun printRepos(localRepos: List<LocalRepo>, title: String) {
        if (localRepos.isNotEmpty()) {
            Logger.print(title, indentLine = true)
            printRepos(localRepos)
        }
    }

    fun printRepos(localRepos: List<LocalRepo>, title: String, empty: String) {
        if (localRepos.isNotEmpty()) {
            Logger.print(title, indentLine = true)
            printRepos(localRepos)
        } else {
            Logger.print(empty, indentLine = true)
        }
    }
}
