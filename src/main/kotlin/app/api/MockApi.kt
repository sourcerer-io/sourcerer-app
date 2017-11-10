// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.api

import app.Logger
import app.model.Commit
import app.model.Repo
import app.model.Fact
import app.model.User

class MockApi(  // GET requests.
    var mockUser: User = User(),
    var mockRepo: Repo = Repo()) : Api {
    // POST requests.
    // In case of multiple requests.
    var receivedRepos: MutableList<Repo> = mutableListOf()
    var receivedAddedCommits: MutableList<Commit> = mutableListOf()
    var receivedFacts: MutableList<Fact> = mutableListOf()

    // DELETE requests.
    var receivedDeletedCommits: MutableList<Commit> = mutableListOf()

    override fun authorize(): Result<Unit> {
        Logger.debug { "MockApi: authorize request" }
        return Result()
    }

    override fun getUser(): Result<User> {
        Logger.debug { "MockApi: getUser request" }
        return Result(mockUser)
    }

    override fun getRepo(repoRehash: String): Result<Repo> {
        Logger.debug { "MockApi: getRepo request" }
        return Result(mockRepo)
    }

    override fun postRepo(repo: Repo): Result<Unit> {
        Logger.debug { "MockApi: postRepo request ($repo)" }
        receivedRepos.add(repo)
        return Result()
    }

    override fun postCommits(commitsList: List<Commit>): Result<Unit> {
        Logger.debug {
            "MockApi: postCommits request (${commitsList.size} commits)"
        }
        receivedAddedCommits.addAll(commitsList)
        return Result()
    }

    override fun deleteCommits(commitsList: List<Commit>): Result<Unit> {
        Logger.debug {
            "MockApi: deleteCommits request (${commitsList.size} commits)" }
        receivedDeletedCommits.addAll(commitsList)
        return Result()
    }

    override fun postFacts(factsList: List<Fact>): Result<Unit> {
        Logger.debug { "MockApi: postStats request (${factsList.size} stats)" }
        receivedFacts.addAll(factsList)
        return Result()
    }
}
