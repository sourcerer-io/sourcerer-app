// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

import app.Repo
import java.lang.UnsupportedOperationException
import java.nio.file.InvalidPathException
import java.nio.file.Paths

/**
 * Class for utility functions on repos.
 */
object RepoHelper {
    // TODO(anatoly): Check repo.
    fun isValidRepo(path: String): Boolean {
        return try {
            Paths.get(path).toFile().isDirectory
        } catch (e: InvalidPathException) {
            false  // Thrown when path string cannot be converted into a Path.
        } catch (e: UnsupportedOperationException) {
            false  // If this Path is not associated with the default provider.
        } catch (e: SecurityException) {
            false  // Read access denied.
        }
    }

    fun printRepos(repos: List<Repo>)
    {
        for (repo in repos) {
            println(repo)
        }
    }

    fun printRepos(repos: List<Repo>, title: String) {
        if (repos.isNotEmpty()) {
            println(title)
            printRepos(repos)
        }
    }

    fun printRepos(repos: List<Repo>, title: String, empty: String) {
        if (repos.isNotEmpty()) {
            println(title)
            printRepos(repos)
        } else {
            println(empty)
        }
    }
}
