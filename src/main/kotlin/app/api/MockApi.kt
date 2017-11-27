// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.api

import app.Logger
import app.model.Author
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
    var receivedAuthors: MutableList<Author> = mutableListOf()
    var receivedUsers: MutableList<User> = mutableListOf()
    var receivedComplete: Int = 0

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

    override fun postUser(user: User): Result<Unit> {
        Logger.debug { "MockApi: postUser request" }
        receivedUsers.add(user)
        return Result()
    }

    override fun postRepo(repo: Repo): Result<Repo> {
        Logger.debug { "MockApi: postRepo request" }
        receivedRepos.add(repo)
        return Result(mockRepo)
    }

    override fun postComplete(): Result<Unit> {
        Logger.debug { "MockApi: postComplete request " }
        receivedComplete++
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
        Logger.debug { "MockApi: postFacts request (${factsList.size} facts)" }
        receivedFacts.addAll(factsList)
        return Result()
    }

    override fun postAuthors(authorsList: List<Author>): Result<Unit> {
        Logger.debug { "MockApi: postAuthors request (${authorsList.size} " +
            "stats)" }
        receivedAuthors.addAll(authorsList)
        return Result()
    }
}
