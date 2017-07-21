// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app

import app.utils.Options

/**
 * Config data class.
 */
class Config (
        var username: String = "",
        var password: String = "",
        var repos: MutableList<Repo> = mutableListOf<Repo>()
) {
    fun addRepo(repo: Repo) {
        // Add without duplicates.
        if (!repos.contains(repo)) {
            repos.add(repo)
        }
    }

    fun removeRepo(repo: Repo) {
        repos.remove(repo)
    }

    fun merge(config: Config): Config {
        if (config.username.isNotEmpty()) {
            username = config.username
        }
        if (config.password.isNotEmpty()) {
            password = config.password
        }
        if (config.repos.isNotEmpty()) {
            repos = config.repos
        }

        return this
    }

    fun merge(options: Options): Config {
        if (options.username.isNotEmpty()) {
            username = options.username
        }
        if (options.password.isNotEmpty()) {
            password = options.password
        }

        return this
    }
}
