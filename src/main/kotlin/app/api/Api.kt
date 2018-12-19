// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.api

import app.model.*

interface Api {
    companion object {
        val OUT_OF_DATE = 1
        val STATUS_CLONING = 80
        val PROCESS_STATUS_START = 100
        val PROCESS_STATUS_COMPLETE = 200
        val PROCESS_STATUS_FAIL = 1000
        val CODE_SUCCESS = 0
        val PROCESS_ERROR_TOO_MUCH_COMMITS = 4
        val PROCESS_ERROR_NO_COMMITS = 5
        val PROCESS_ERROR_PROCESSOR = 6
        val PROCESS_ERROR_EMPTY_REPO = 8
        val PROCESS_ERROR_NO_ACCESS = 9
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
    fun postAuthorDistances(authorDistanceList: List<AuthorDistance>):
            Result<Unit>
}
