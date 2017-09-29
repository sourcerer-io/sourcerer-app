// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package test.tests.hashers

import app.FactCodes
import app.api.MockApi
import app.hashers.CommitCrawler
import app.hashers.FactHasher
import app.model.Author
import app.model.Fact
import app.model.LocalRepo
import app.model.Repo
import org.jetbrains.spek.api.Spek
import org.jetbrains.spek.api.dsl.given
import org.jetbrains.spek.api.dsl.it
import test.utils.TestRepo
import java.util.*
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class FactHasherTest : Spek({
    val userName = "Contributor"
    val userEmail = "test@domain.com"

    val repoPath = "../testrepo-fact-hasher-"
    val localRepo = LocalRepo(repoPath)
    localRepo.author = Author(userName, userEmail)

    given("test of commits date facts") {
        val testRepo = TestRepo(repoPath + "date-facts")
        val author1 = Author("Test1", "test@domain.com")
        val author2 = Author("Test2", "test@domain.com")

        val repo = Repo(rehash = "rehash", commits = listOf())
        val mockApi = MockApi(mockRepo = repo)
        val facts = mockApi.receivedFacts

        fun createDate(year: Int = 2017, month: Int = 1, day: Int = 1,
                       hour: Int = 0, minute: Int = 0, seconds: Int = 0): Date {
            val cal = Calendar.getInstance()
            // Month in calendar is 0-based.
            cal.set(year, month - 1, day, hour, minute, seconds)
            return cal.time
        }

        afterEachTest {
            facts.clear()
        }

        it("send two facts") {
            testRepo.createFile("test1.txt", listOf("line1", "line2"))
            testRepo.commit(message = "initial commit",
                author = author1,
                date = createDate(year = 2017, month = 1, day = 1,  // Sunday.
                    hour = 13, minute = 0, seconds = 0))

            val errors = mutableListOf<Throwable>()
            val observable = CommitCrawler.getObservable(testRepo.git, repo)
            FactHasher(localRepo, repo, mockApi)
                .updateFromObservable(observable, { e -> errors.add(e) })

            assertEquals(0, errors.size)
            assertEquals(2, facts.size)
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMITS_DAY_TIME, 13,
                1.0, author1)))
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMITS_DAY_WEEK, 6,
                1.0, author1)))
        }

        it("send more facts") {
            testRepo.createFile("test2.txt", listOf("line1", "line2"))
            testRepo.commit(message = "second commit",
                author = author2,
                date = createDate(year=2017, month = 1, day = 2,  // Monday.
                    hour = 18, minute = 0, seconds = 0))

            testRepo.createFile("test3.txt", listOf("line1", "line2"))
            testRepo.commit(message = "third commit",
                author = author1,
                date = createDate(year=2017, month = 1, day = 2,  // Monday.
                    hour = 13, minute = 0, seconds = 0))

            val errors = mutableListOf<Throwable>()
            val observable = CommitCrawler.getObservable(testRepo.git, repo)
            FactHasher(localRepo, repo, mockApi)
                .updateFromObservable(observable, { e -> errors.add(e) })

            assertEquals(0, errors.size)
            assertEquals(5, facts.size)
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMITS_DAY_TIME, 18,
                1.0, author2)))
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMITS_DAY_WEEK, 0,
                1.0, author2)))
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMITS_DAY_TIME, 13,
                2.0, author1)))
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMITS_DAY_WEEK, 0,
                1.0, author1)))
        }

        afterGroup {
            testRepo.destroy()
        }
    }
})
