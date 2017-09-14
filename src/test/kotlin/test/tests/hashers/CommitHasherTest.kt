// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package test.tests.hashers

import app.FactKey
import app.api.MockApi
import app.hashers.CommitHasher
import app.model.*
import app.utils.RepoHelper
import org.eclipse.jgit.api.Git
import org.jetbrains.spek.api.Spek
import org.jetbrains.spek.api.dsl.given
import org.jetbrains.spek.api.dsl.it
import test.utils.TestRepo
import java.io.File
import java.util.*
import java.util.stream.StreamSupport.stream
import kotlin.streams.toList
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

class CommitHasherTest : Spek({
    val userName = "Contributor"
    val userEmail = "test@domain.com"

    // Creation of test repo.
    val repoPath = "./tmp_repo/.git"
    val git = Git.init().setGitDir(File(repoPath)).call()
    val config = git.repository.config
    config.setString("user", null, "name", userName)
    config.setString("user", null, "email", userEmail)
    config.save()

    // Common parameters for CommitHasher.
    val gitHasher = Git.open(File(repoPath))
    val localRepo = LocalRepo(repoPath)
    localRepo.author = Author(userName, userEmail)
    val initialCommit = Commit(git.commit().setMessage("Initial commit").call())
    val repoRehash = RepoHelper.calculateRepoRehash(initialCommit.rehash,
                                                    localRepo)
    val repo = Repo(rehash = repoRehash,
                    initialCommitRehash = initialCommit.rehash)

    fun getRepoRehash(git: Git, localRepo: LocalRepo): String {

        val initialRevCommit = stream(git.log().call().spliterator(), false)
                               .toList().first()
        val initialCommit = Commit(initialRevCommit)
        val repoRehash = RepoHelper.calculateRepoRehash(initialCommit.rehash,
                                                        localRepo)
        return repoRehash
    }

    fun getLastCommit(git: Git): Commit {
        val revCommits = stream(git.log().call().spliterator(), false).toList()
        val lastCommit = Commit(revCommits.first())
        return lastCommit
    }

    fun createDate(year: Int = 2017, month: Int = 1, day: Int = 1,
                   hour: Int = 0, minute: Int = 0, seconds: Int = 0): Date {
        val cal = Calendar.getInstance()
        // Month in calendar is 0-based.
        cal.set(year, month - 1, day, hour, minute, seconds)
        return cal.time
    }

    given("repo with initial commit and no history") {
        repo.commits = listOf()

        val mockApi = MockApi(mockRepo = repo)
        CommitHasher(localRepo, repo, mockApi, gitHasher).update()

        it("send added commits") {
            assertEquals(1, mockApi.receivedAddedCommits.size)
        }

        it("doesn't send deleted commits") {
            assertEquals(0, mockApi.receivedDeletedCommits.size)
        }
    }

    given("repo with initial commit") {
        repo.commits = listOf(getLastCommit(git))

        val mockApi = MockApi(mockRepo = repo)
        CommitHasher(localRepo, repo, mockApi, gitHasher).update()

        it("doesn't send added commits") {
            assertEquals(0, mockApi.receivedAddedCommits.size)
        }

        it("doesn't send deleted commits") {
            assertEquals(0, mockApi.receivedDeletedCommits.size)
        }
    }

    given("happy path: added one commit") {
        repo.commits = listOf(getLastCommit(git))

        val mockApi = MockApi(mockRepo = repo)

        val revCommit = git.commit().setMessage("Second commit.").call()
        val addedCommit = Commit(revCommit)
        CommitHasher(localRepo, repo, mockApi, gitHasher).update()

        it("doesn't send deleted commits") {
            assertEquals(0, mockApi.receivedDeletedCommits.size)
        }

        it("posts one commit as added") {
            assertEquals(1, mockApi.receivedAddedCommits.size)
        }

        it("should be that the posted commit is added one") {
            assertEquals(addedCommit, mockApi.receivedAddedCommits.last())
        }
    }

    given("happy path: added a few new commits") {
        repo.commits = listOf(getLastCommit(git))

        val mockApi = MockApi(mockRepo = repo)

        val otherAuthorsNames = listOf("a", "b", "a")
        val otherAuthorsEmails = listOf("a@a", "b@b", "a@a")
        for (i in 0..2) {
            git.commit().setMessage("Create $i.")
                        .setAuthor(otherAuthorsNames.get(i),
                                   otherAuthorsEmails.get(i))
                        .call()
        }
        val authorCommits = mutableListOf<Commit>()
        for (i in 0..4) {
            val message = "Created $i by author."
            val revCommit = git.commit().setMessage(message).call()
            authorCommits.add(Commit(revCommit))
        }
        CommitHasher(localRepo, repo, mockApi, gitHasher).update()

        it("posts five commits as added") {
            assertEquals(5, mockApi.receivedAddedCommits.size)
        }

        it("doesn't send deleted commits ") {
            assertEquals(0, mockApi.receivedDeletedCommits.size)
        }

        it("processes author's commits") {
            assertEquals(authorCommits.asReversed(),
                         mockApi.receivedAddedCommits)
        }
    }

    given("fork event") {
        val forkedRepoPath = "./forked_repo/"
        val originalRepoPath = "./original_repo/"
        val forked = Git.cloneRepository()
                .setURI("https://github.com/yaronskaya/sourcerer-app.git")
                .setDirectory(File(forkedRepoPath))
                .call()
        val original = Git.cloneRepository()
                .setURI("https://github.com/sourcerer-io/sourcerer-app.git")
                .setDirectory(File(originalRepoPath))
                .call()
        val forkedLocalRepo = LocalRepo(forkedRepoPath)
        val originalLocalRepo = LocalRepo(originalRepoPath)

        val forkedRepoRehash = getRepoRehash(forked, forkedLocalRepo)
        val originalRepoRehash = getRepoRehash(original, originalLocalRepo)

        it("assigns different hashes for the original and the forked repos") {
            assertNotEquals(originalRepoRehash, forkedRepoRehash)
        }

        forked.repository.close()
        forked.close()
        original.repository.close()
        original.close()
    }

    given("lost server") {
        repo.commits = listOf(getLastCommit(git))

        val mockApi = MockApi(mockRepo = repo)

        // Add some commits.
        val addedCommits = mutableListOf<Commit>()
        for (i in 0..3) {
            val message = "Created $i by author."
            val revCommit = git.commit().setMessage(message).call()
            addedCommits.add(Commit(revCommit))
        }

        // Remove one commit from server history.
        val removedCommit = addedCommits.removeAt(1)
        repo.commits = addedCommits.toList().asReversed()

        CommitHasher(localRepo, repo, mockApi, gitHasher).update()

        it("adds posts one commit as added and received commit is lost one") {
            assertEquals(1, mockApi.receivedAddedCommits.size)
            assertEquals(removedCommit, mockApi.receivedAddedCommits.last())
        }

        it("doesn't posts deleted commits") {
            assertEquals(0, mockApi.receivedDeletedCommits.size)
        }
    }

    given("test of commits date facts") {
        val testRepoPath = "../testrepo1"
        val testRepo = TestRepo(testRepoPath)
        val author1 = Author("Test1", "test@domain.com")
        val author2 = Author("Test2", "test@domain.com")

        val repo = Repo(rehash = "rehash", commits = listOf())
        val mockApi = MockApi(mockRepo = repo)
        val facts = mockApi.receivedFacts

        afterEachTest {
            facts.clear()
        }

        it("send two facts") {
            testRepo.createFile("test1.txt", listOf("line1", "line2"))
            testRepo.commit(message = "initial commit",
                            author = author1,
                            // Sunday.
                            date = createDate(year = 2017, month = 1, day = 1,
                                hour = 13, minute = 0, seconds = 0))

            CommitHasher(localRepo, repo, mockApi, testRepo.git).update()

            assertEquals(2, facts.size)
            assertTrue(facts.contains(Fact(repo, FactKey.COMMITS_DAY_TIME + 13,
                1.0, author1)))
            assertTrue(facts.contains(Fact(repo, FactKey.COMMITS_DAY_WEEK + 6,
                1.0, author1)))
        }

        it("send more facts") {
            testRepo.createFile("test2.txt", listOf("line1", "line2"))
            testRepo.commit(message = "second commit",
                            author = author2,
                            // Monday.
                            date = createDate(year=2017, month = 1, day = 2,
                                hour = 18, minute = 0, seconds = 0))

            testRepo.createFile("test3.txt", listOf("line1", "line2"))
            testRepo.commit(message = "third commit",
                            author = author1,
                            // Monday.
                            date = createDate(month = 1, day = 2,
                                hour = 13, minute = 0, seconds = 0))

            CommitHasher(localRepo, repo, mockApi, testRepo.git).update()

            assertEquals(5, facts.size)
            assertTrue(facts.contains(Fact(repo, FactKey.COMMITS_DAY_TIME + 18,
                1.0, author2)))
            assertTrue(facts.contains(Fact(repo, FactKey.COMMITS_DAY_WEEK + 0,
                1.0, author2)))
            assertTrue(facts.contains(Fact(repo, FactKey.COMMITS_DAY_TIME + 13,
                2.0, author1)))
            assertTrue(facts.contains(Fact(repo, FactKey.COMMITS_DAY_WEEK + 0,
                1.0, author1)))
        }

        afterGroup {
            testRepo.destroy()
        }
    }

    Runtime.getRuntime().exec("src/test/delete_repo.sh").waitFor()
})
