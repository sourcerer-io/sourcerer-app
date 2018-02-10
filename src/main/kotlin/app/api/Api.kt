// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.api

import app.model.Author
import app.model.Commit
import app.model.Fact
import app.model.Process
import app.model.ProcessEntry
import app.model.Repo
import app.model.User

interface Api {
    companion object {
        val OUT_OF_DATE = 1
        val PROCESS_STATUS_START = 100
        val PROCESS_STATUS_COMPLETE = 200
        val PROCESS_STATUS_FAIL = 1000
        val PROCESS_ERROR_RESTRICTED = 2
        val PROCESS_ERROR_TOO_BIG = 3
        val PROCESS_ERROR_TOO_MUCH_COMMITS = 4
        val PROCESS_ERROR_NO_COMMITS = 5
    }

    fun authorize(): Result<Unit>
    fun getUser(): Result<User>
    fun postUser(user: User): Result<Unit>
    fun postRepo(repo: Repo): Result<Repo>
    fun postCommits(commitsList: List<Commit>): Result<Unit>
    fun deleteCommits(commitsList: List<Commit>): Result<Unit>
    fun postFacts(factsList: List<Fact>): Result<Unit>
    fun postAuthors(authorsList: List<Author>): Result<Unit>
    fun postProcessCreate(requestNumEntries: Int): Result<Process>
    fun postProcess(processEntries: List<ProcessEntry>): Result<Unit>
}
