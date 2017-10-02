// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.config

import app.model.LocalRepo
import app.utils.Options

/**
 * Config data class.
 */
class Config (
        var uuid: String = "",
        var username: String = "",
        var password: String = "",
        var localRepos: MutableSet<LocalRepo> = mutableSetOf()
) {
    fun addRepo(repo: LocalRepo) {
        localRepos.remove(repo)  // Fields may be updated.
        localRepos.add(repo)
    }

    fun removeRepo(repo: LocalRepo) {
        localRepos.remove(repo)
    }

    fun merge(config: Config): Config {
        if (config.username.isNotEmpty()) {
            username = config.username
        }
        if (config.password.isNotEmpty()) {
            password = config.password
        }
        if (config.localRepos.isNotEmpty()) {
            localRepos = config.localRepos
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
