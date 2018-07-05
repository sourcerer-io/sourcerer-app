// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package test.tests.hashers

import app.api.MockApi
import app.extractors.ExtractorInterface
import app.hashers.CommitHasher
import app.hashers.CommitCrawler
import app.model.*
import org.jetbrains.spek.api.Spek
import org.jetbrains.spek.api.dsl.given
import org.jetbrains.spek.api.dsl.it
import test.utils.TestRepo
import kotlin.test.assertEquals

class IgnorePathsTest : Spek({
    fun cleanRepos() {
        Runtime.getRuntime().exec("src/test/delete_repo.sh").waitFor()
    }

    val userName = "Contributor"
    val userEmail = "test@domain.com"

    // Creation of test repo.
    cleanRepos()

    given("commits with syntax stats") {
        val lines = listOf("x = [i**2 for i range(9999)]", "def fn()", "x = 1",
                "x = map(lambda x: x**2, range(9999))",
                "x = map(lambda x: x**2, map(lambda x: x**3, range(10))",
                "x = map(lambda x: x**2, range(10))," +
                        "map(lambda x: x**3, range(10)))")

        val author = Author(userName, userEmail)
        val emails = hashSetOf(userEmail)

        val testRepoPath = "../IgnorePaths_t1"
        val testRepo = TestRepo(testRepoPath)

        val testRehash = "rehash_IgnorePaths_t1"
        val serverRepo = Repo(rehash = testRehash)

        val mockApi = MockApi(mockRepo = serverRepo)
        val observable = CommitCrawler.getObservable(testRepo.git, serverRepo)

        it("t1") {
            testRepo.createFile("test.py", lines)
            testRepo.commit(message = "commit1", author = author)

            testRepo.createFile("ignore.py", lines)
            testRepo.commit(message = "commit2", author = author)

            // Add config, ignore.py from previous commit should be
            // ignored for stats.
            testRepo.createFile(".sourcerer-conf",
                                listOf("[ignore]", "ignore.py", "#test.py"))
            testRepo.commit(message = "commit3", author = author)

            // Uncomment test.py file in config and delete it. The change
            // should be ignored for statistics.
            testRepo.deleteLines(".sourcerer-conf", 1, 1)
            testRepo.insertLines(".sourcerer-conf", 1, listOf("test.py"))
            testRepo.commit(message = "commit4", author = author)

            testRepo.deleteFile("test.py")
            testRepo.commit(message = "commit5", author = author)

            val errors = mutableListOf<Throwable>()
            CommitHasher(serverRepo, mockApi, listOf("rehashes"), emails)
                .updateFromObservable(observable, { e -> errors.add(e) })
            if (errors.size > 0) {
                println(errors[0].message)
            }
            assertEquals(0, errors.size)

            val syntaxStats = mockApi.receivedAddedCommits
                .fold(mutableListOf<CommitStats>()) { allStats, commit ->
                    allStats.addAll(commit.stats)
                    allStats
                }.filter { it.type == ExtractorInterface.TYPE_SYNTAX }

            val mapStats = syntaxStats.filter { it.tech == "python>map" }
            assertEquals(1, mapStats.size)
            assertEquals(5, mapStats.map { it.numLinesAdded }.sum())
            assertEquals(0, mapStats.map { it.numLinesDeleted }.sum())
        }

        afterGroup {
            testRepo.destroy()
        }
    }

    cleanRepos()
})
