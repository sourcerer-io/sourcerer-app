// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

import app.Logger
import app.model.LocalRepo
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.lib.ObjectId
import org.eclipse.jgit.lib.Repository
import java.io.File
import java.nio.file.InvalidPathException
import java.nio.file.Paths

/**
 * Class for utility functions on repos.
 */
object RepoHelper {
    val MASTER_BRANCH = "refs/heads/master"

    fun isValidRepo(path: String): Boolean {
        if (!isDirectory(path)) {
            return false
        }

        var git: Git? = null
        var repository: Repository? = null
        var commitId: ObjectId? = null
        try {
            git = Git.open(File(path))
            repository = git.repository
            commitId = repository.resolve(MASTER_BRANCH)
        } catch (e: Exception) {
            Logger.error("Cannot access repository at path $path", e)
            return false
        } finally {
            repository?.close()
            git?.close()
        }

        if (commitId != null) {
            return true
        }
        Logger.error("Repository at path $path is empty")
        return false
    }

    fun isDirectory(path: String): Boolean {
        return try {
            Paths.get(path).toFile().isDirectory
        } catch (e: InvalidPathException) {
            Logger.error("Invalid path $path", e)
            false
        } catch (e: UnsupportedOperationException) {
            Logger.error("Invalid path $path", e)
            false
        } catch (e: SecurityException) {
            Logger.error("Cannot access repository at path $path", e)
            false
        }
    }

    fun printRepos(localRepos: List<LocalRepo>)
    {
        for (repo in localRepos) {
            println(repo)
        }
    }

    fun printRepos(localRepos: List<LocalRepo>, title: String) {
        if (localRepos.isNotEmpty()) {
            println(title)
            printRepos(localRepos)
        }
    }

    fun printRepos(localRepos: List<LocalRepo>, title: String, empty: String) {
        if (localRepos.isNotEmpty()) {
            println(title)
            printRepos(localRepos)
        } else {
            println(empty)
        }
    }
}
