// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import com.fasterxml.jackson.annotation.JsonIgnore
import org.eclipse.jgit.lib.Config

data class LocalRepo(var path: String = "") {
    var hashAllContributors: Boolean = false

    @JsonIgnore var author: Author = Author()
    @JsonIgnore var remoteOrigin: String = ""
    @JsonIgnore var meta = RepoMeta()
    @JsonIgnore var processEntryId: Int? = 0

    fun parseGitConfig(config: Config) {
        author = Author(
            name = config.getString("user", null, "name") ?: "",
            email = config.getString("user", null, "email") ?: "")
        remoteOrigin = config.getString("remote", "origin", "url") ?: ""
    }

    override fun toString(): String {
        return path
    }
}
