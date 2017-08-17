// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.api

import app.model.Commit
import app.model.Repo
import app.model.User

interface Api {
    fun authorize()
    fun getUser(): User
    fun getRepo(repoRehash: String): Repo
    fun postRepo(repo: Repo)
    fun postCommits(commitsList: List<Commit>)
    fun deleteCommits(commitsList: List<Commit>)
}
