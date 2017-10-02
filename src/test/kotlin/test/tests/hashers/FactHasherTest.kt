// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package test.tests.hashers

import app.FactCodes
import app.api.MockApi
import app.hashers.CommitCrawler
import app.hashers.FactHasher
import app.model.Author
import app.model.Fact
import app.model.Repo
import org.jetbrains.spek.api.Spek
import org.jetbrains.spek.api.dsl.given
import org.jetbrains.spek.api.dsl.it
import test.utils.TestRepo
import java.util.*
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class FactHasherTest : Spek({
    val authorEmail1 = "test1@domain.com"
    val authorEmail2 = "test2@domain.com"
    val author1 = Author("Test1", authorEmail1)
    val author2 = Author("Test2", authorEmail2)

    val repoPath = "../testrepo-fact-hasher-"
    val repo = Repo(rehash = "rehash", commits = listOf())

    fun createDate(year: Int = 2017, month: Int = 1, day: Int = 1,
                   hour: Int = 0, minute: Int = 0, seconds: Int = 0): Date {
        val cal = Calendar.getInstance()
        // Month in calendar is 0-based.
        cal.set(year, month - 1, day, hour, minute, seconds)
        return cal.time
    }

    given("commits for date facts") {
        val testRepo = TestRepo(repoPath + "date-facts")
        val emails = hashSetOf(authorEmail1, authorEmail2)
        val mockApi = MockApi(mockRepo = repo)
        val facts = mockApi.receivedFacts

        afterEachTest {
            facts.clear()
        }

        it("sends initial facts") {
            testRepo.createFile("test1.txt", listOf("line1", "line2"))
            testRepo.commit(message = "initial commit",
                author = author1,
                date = createDate(year = 2017, month = 1, day = 1,  // Sunday.
                    hour = 13, minute = 0, seconds = 0))

            val errors = mutableListOf<Throwable>()
            val observable = CommitCrawler.getObservable(testRepo.git, repo)
            FactHasher(repo, mockApi, emails)
                .updateFromObservable(observable, { e -> errors.add(e) })

            assertEquals(0, errors.size)
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMITS_DAY_TIME, 13,
                                           "1", author1)))
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMITS_DAY_WEEK, 6,
                                           "1", author1)))
        }

        it("sends more facts") {
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
            FactHasher(repo, mockApi, emails)
                .updateFromObservable(observable, { e -> errors.add(e) })

            assertEquals(0, errors.size)
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMITS_DAY_TIME, 18,
                                           "1", author2)))
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMITS_DAY_WEEK, 0,
                                           "1", author2)))
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMITS_DAY_TIME, 13,
                                           "2", author1)))
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMITS_DAY_WEEK, 0,
                                           "1", author1)))
        }

        afterGroup {
            testRepo.destroy()
        }
    }

    given("test of repo facts") {
        val testRepo = TestRepo(repoPath + "repo-facts")
        val emails = hashSetOf(authorEmail1, authorEmail2)
        val mockApi = MockApi(mockRepo = repo)
        val facts = mockApi.receivedFacts

        afterEachTest {
            facts.clear()
        }

        it("sends facts") {
            val startAuthor1 = createDate(year = 2016, month = 2, day = 10,
                                          hour = 13, minute = 0, seconds = 0)
            val midAuthor1 = createDate(year = 2016, month = 10, day = 5,
                                        hour = 10, minute = 0, seconds = 0)
            val startAuthor2 = createDate(year = 2017, month = 1, day = 1,
                                          hour = 12, minute = 10, seconds = 10)
            val midAuthor2 = createDate(year = 2017, month = 2, day = 2,
                                        hour = 15, minute = 0, seconds = 0)
            val endAuthor1 = createDate(year = 2017, month = 4, day = 5,
                                        hour = 13, minute = 0, seconds = 0)
            val endAuthor2 = createDate(year = 2017, month = 5, day = 15,
                                        hour = 15, minute = 0, seconds = 0)

            testRepo.createFile("test1.txt", listOf("line1", "line2"))
            testRepo.commit(message = "author1 -> start",
                            author = author1,
                            date = startAuthor1)

            testRepo.insertLines("test1.txt", 0, listOf("line3"))
            testRepo.commit(message = "author1 -> mid",
                            author = author1,
                            date = midAuthor1)

            testRepo.createFile("test2.txt", listOf("line4"))
            testRepo.commit(message = "author2 -> start",
                            author = author2,
                            date = startAuthor2)

            testRepo.insertLines("test2.txt", 0, listOf("line5"))
            testRepo.commit(message = "author2 -> mid",
                            author = author2,
                            date = midAuthor2)

            testRepo.insertLines("test1.txt", 0, listOf("line6"))
            testRepo.commit(message = "author1 -> end",
                            author = author1,
                            date = endAuthor1)

            testRepo.insertLines("test2.txt", 0, listOf("line7"))
            testRepo.commit(message = "author2 -> end",
                            author = author2,
                            date = endAuthor2)

            val errors = mutableListOf<Throwable>()
            val observable = CommitCrawler.getObservable(testRepo.git, repo)
            FactHasher(repo, mockApi, emails)
                .updateFromObservable(observable, { e -> errors.add(e) })

            assertTrue(facts.contains(Fact(repo, FactCodes.REPO_DATE_START, 0,
                (startAuthor1.time/1000).toString(), author1)))
            assertTrue(facts.contains(Fact(repo, FactCodes.REPO_DATE_START, 0,
                (startAuthor2.time/1000).toString(), author2)))
            assertTrue(facts.contains(Fact(repo, FactCodes.REPO_DATE_END, 0,
                (endAuthor1.time/1000).toString(), author1)))
            assertTrue(facts.contains(Fact(repo, FactCodes.REPO_DATE_END, 0,
                (endAuthor2.time/1000).toString(), author2)))
            assertTrue(facts.contains(Fact(repo, FactCodes.REPO_TEAM_SIZE, 0,
                "2")))
        }


        afterGroup {
            testRepo.destroy()
        }
    }
})
