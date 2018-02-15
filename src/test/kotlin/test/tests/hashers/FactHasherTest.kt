// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

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
import test.utils.assertFactDouble
import test.utils.assertFactInt
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
            FactHasher(repo, mockApi, listOf("r1"), emails)
                .updateFromObservable(observable, { e -> errors.add(e) })

            assertEquals(0, errors.size)
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMIT_DAY_TIME, 13,
                                           "1", author1)))
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMIT_DAY_WEEK, 6,
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
            FactHasher(repo, mockApi, listOf("r1", "r2"), emails)
                .updateFromObservable(observable, { e -> errors.add(e) })

            assertEquals(0, errors.size)
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMIT_DAY_TIME, 18,
                                           "1", author2)))
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMIT_DAY_WEEK, 0,
                                           "1", author2)))
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMIT_DAY_TIME, 13,
                                           "2", author1)))
            assertTrue(facts.contains(Fact(repo, FactCodes.COMMIT_DAY_WEEK, 0,
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
            FactHasher(repo, mockApi,
                listOf("r1", "r2", "r3", "r4", "r5", "r6"), emails)
                .updateFromObservable(observable, { e -> errors.add(e) })

            assertEquals(0, errors.size)
            assertTrue(facts.contains(Fact(repo, FactCodes.REPO_DATE_START, 0,
                (startAuthor1.time/1000).toString(), author1)))
            assertTrue(facts.contains(Fact(repo, FactCodes.REPO_DATE_START, 0,
                (startAuthor2.time/1000).toString(), author2)))
            assertTrue(facts.contains(Fact(repo, FactCodes.REPO_DATE_END, 0,
                (endAuthor1.time/1000).toString(), author1)))
            assertTrue(facts.contains(Fact(repo, FactCodes.REPO_DATE_END, 0,
                (endAuthor2.time/1000).toString(), author2)))
        }

        afterGroup {
            testRepo.destroy()
        }
    }

    given("test of commit facts") {
        val testRepo = TestRepo(repoPath + "commit-facts")
        val emails = hashSetOf(authorEmail1, authorEmail2)
        val mockApi = MockApi(mockRepo = repo)
        val facts = mockApi.receivedFacts
        val lines = listOf(
            "All my rap, if shortly, is about the thing that",
            "For so many years so many cities have been under hoof",
            "To go uphill when gets lucky. Then downhill when feels sick",
            "I'm not really a Gulliver, but still the city is under hoof",
            "City under hoof, city under hoof",
            "Traffic lights, state duties, charges and customs",
            "I don't know whether this path is wade or to the bottom",
            "You live under a thumb, I have a city under my hoof",
            "All my rap, if shortly, is about the thing that",
            "For so many years so many cities have been under hoof",
            "To go uphill when gets lucky. Then downhill when feels sick",
            "I'm not really a Gulliver, but still the city is under hoof",
            "City under hoof, city under hoof",
            "Traffic lights, state duties, charges and customs",
            "I don't know whether this path is wade or to the bottom",
            "You live under a thumb, I have a city under my hoof",
            "All my rap, if shortly, is about the thing that",
            "For so many years so many cities have been under hoof",
            "To go uphill when gets lucky. Then downhill when feels sick",
            "I'm not really a Gulliver, but still the city is under hoof",
            "City under hoof, city under hoof",
            "Traffic lights, state duties, charges and customs",
            "I don't know whether this path is wade or to the bottom",
            "You live under a thumb, I have a city under my hoof"
        )
        val linesLenAvg = lines.fold (0) { acc, s -> acc + s.length } /
            lines.size.toDouble()

        afterEachTest {
            facts.clear()
        }

        it("sends facts") {
            testRepo.createFile("test1.txt", listOf())

            testRepo.insertLines("test1.txt", 0, lines.subList(0, 3))
            testRepo.commit(message = "Commit 1", author = author1)

            testRepo.insertLines("test1.txt", 0, lines.subList(3, 6))
            testRepo.commit(message = "Commit 2", author = author1)

            testRepo.insertLines("test1.txt", 0, lines.subList(6, 9))
            testRepo.commit(message = "Commit 3", author = author1)

            testRepo.insertLines("test1.txt", 0, lines.subList(9, 12))
            testRepo.commit(message = "Commit 4", author = author1)

            testRepo.insertLines("test1.txt", 0, lines.subList(12, 16))
            testRepo.commit(message = "Commit 5", author = author1)

            testRepo.insertLines("test1.txt", 0, lines.subList(16, 24))
            testRepo.commit(message = "Commit 6", author = author1)

            val errors = mutableListOf<Throwable>()
            val observable = CommitCrawler.getObservable(testRepo.git, repo)
            FactHasher(repo, mockApi,
                listOf("r1", "r2", "r3", "r4", "r5", "r6"), emails)
                .updateFromObservable(observable, { e -> errors.add(e) })

            assertEquals(0, errors.size)
            assertFactInt(FactCodes.COMMIT_NUM, 0, 6, author1, facts)
            assertFactDouble(FactCodes.COMMIT_LINE_NUM_AVG, 0, 4.0, author1,
                facts)
            assertFactInt(FactCodes.LINE_NUM, 0, 24, author1, facts)
            assertFactDouble(FactCodes.LINE_LEN_AVG, 0, linesLenAvg, author1,
                facts)
            assertFactInt(FactCodes.COMMIT_NUM_TO_LINE_NUM, 3, 4, author1,
                facts)
            assertFactInt(FactCodes.COMMIT_NUM_TO_LINE_NUM, 4, 1, author1,
                facts)
            assertFactInt(FactCodes.COMMIT_NUM_TO_LINE_NUM, 8, 1, author1,
                facts)
        }

        afterGroup {
            testRepo.destroy()
        }
    }

    given("commits for naming convention facts") {
        val testRepo = TestRepo(repoPath + "file-facts")
        val emails = hashSetOf(authorEmail1)
        val mockApi = MockApi(mockRepo = repo)
        val facts = mockApi.receivedFacts

        afterEachTest {
            facts.clear()
        }

        val lines = listOf("camelCase1", "camelCase2", "snake_case", "fn()")

        it("sends facts") {
            for (i in 0..lines.size - 1) {
                val line = lines[i]
                val fileName = "file$i.txt"
                testRepo.createFile(fileName, listOf(line))
                testRepo.commit(message = "$line in $fileName",
                                author = author1)
            }

            val errors = mutableListOf<Throwable>()
            val observable = CommitCrawler.getObservable(testRepo.git, repo)
            val rehashes = (0..lines.size - 1).map { "r$it" }

            FactHasher(repo, mockApi, rehashes, emails)
                    .updateFromObservable(observable, { e -> errors.add(e) })
            assertEquals(0, errors.size)

            assertFactInt(FactCodes.VARIABLE_NAMING,
                FactCodes.VARIABLE_NAMING_SNAKE_CASE, 1, author1, facts)
            assertFactInt(FactCodes.VARIABLE_NAMING,
                FactCodes.VARIABLE_NAMING_CAMEL_CASE, 2, author1, facts)
            assertFactInt(FactCodes.VARIABLE_NAMING,
                FactCodes.VARIABLE_NAMING_OTHER, 1, author1, facts)
        }

        afterGroup {
            testRepo.destroy()
        }
    }

    given("commits for indentation facts") {
        val testRepo = TestRepo(repoPath + "indentation-facts")
        val emails = hashSetOf(authorEmail1)
        val mockApi = MockApi(mockRepo = repo)
        val facts = mockApi.receivedFacts

        afterEachTest {
            facts.clear()
        }

        val lines = listOf("\tdef test()", "\t\tdef fn()", "a b c d", "    ",
            "    def fn()")

        it("sends facts") {
            for (i in 0..lines.size - 1) {
                val line = lines[i]
                val fileName = "file$i.txt"
                testRepo.createFile(fileName, listOf(line))
                testRepo.commit(message = "$line in $fileName",
                                author = author1)
            }

            val errors = mutableListOf<Throwable>()
            val observable = CommitCrawler.getObservable(testRepo.git, repo)
            val rehashes = (0..lines.size - 1).map { "r$it" }

            FactHasher(repo, mockApi, rehashes, emails)
                    .updateFromObservable(observable, { e -> errors.add(e) })
            assertEquals(0, errors.size)

            assertFactInt(FactCodes.INDENTATION,
                    FactCodes.INDENTATION_TABS, 2, author1, facts)
            assertFactInt(FactCodes.INDENTATION,
                    FactCodes.INDENTATION_SPACES, 1, author1, facts)
        }

        afterGroup {
            testRepo.destroy()
        }
    }
})
