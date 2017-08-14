// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import org.eclipse.jgit.lib.Config

data class LocalRepo(var path: String = "") {
    var hashAllContributors: Boolean = false
    var author: Author = Author()
    var remoteOrigin: String = ""

    val userName: String by lazy {
        try { System.getProperty("user.name") } catch (e: Exception) { "" }
    }

    fun parseGitConfig(config: Config) {
        author = Author(
            name = config.getString("user", null, "name") ?: "",
            email = config.getString("user", null, "email") ?: "")
        remoteOrigin = config.getString("remote", "origin", "url") ?: ""
    }
}
