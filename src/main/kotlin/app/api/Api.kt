// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.api

import app.model.Commit
import app.model.Fact
import app.model.Repo
import app.model.User

interface Api {
    companion object {
        val OUT_OF_DATE = 1
    }

    fun authorize(): Result<Unit>
    fun getUser(): Result<User>
    fun getRepo(repoRehash: String): Result<Repo>
    fun postRepo(repo: Repo): Result<Unit>
    fun postCommits(commitsList: List<Commit>): Result<Unit>
    fun deleteCommits(commitsList: List<Commit>): Result<Unit>
    fun postFacts(factsList: List<Fact>): Result<Unit>
}
