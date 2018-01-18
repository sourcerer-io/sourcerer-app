// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package test.tests.hashers

import app.api.MockApi
import app.FactCodes
import app.hashers.CodeLine
import app.hashers.CodeLineAges
import app.hashers.CodeLongevity
import app.hashers.CommitCrawler
import app.hashers.RevCommitLine
import app.model.*

import test.utils.TestRepo

import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.test.fail

import org.eclipse.jgit.revwalk.RevCommit

import org.jetbrains.spek.api.Spek
import org.jetbrains.spek.api.dsl.given
import org.jetbrains.spek.api.dsl.it

import java.util.Calendar
import kotlin.test.assertNotNull

/**
 * Testing class.
 */
class ColleaguesTest : Spek({
    given("'colleagues #1'") {
        val testRepoPath = "../colleagues1"
        val testRepo = TestRepo(testRepoPath)
        val testRehash = "rehash_colleagues1"
        val fileName = "test1.txt"
        val author1 = Author(testRepo.userName, testRepo.userEmail)
        val author2 = Author("Vasya Pupkin", "vasya@pupkin.me")
        val emails = hashSetOf(author1.email, author2.email)

        val serverRepo = Repo(rehash = testRehash)

        it("'t1'") {
            val mockApi = MockApi(mockRepo = serverRepo)

            testRepo.createFile(fileName, listOf("line1", "line2"))
            testRepo.commit(message = "initial commit",
                author = author1,
                date = Calendar.Builder().setTimeOfDay(0, 0, 0)
                    .build().time)

            testRepo.deleteLines(fileName, 1, 1)
            testRepo.commit(message = "delete line",
                author = author1,
                date = Calendar.Builder().setTimeOfDay(0, 1, 0)
                    .build().time)

            testRepo.deleteLines(fileName, 0, 0)
            testRepo.commit(message = "delete line #2",
                author = author2,
                date = Calendar.Builder().setTimeOfDay(0, 1, 0)
                    .build().time)

            val cl = CodeLongevity(serverRepo, emails, testRepo.git)
            cl.updateFromObservable(onError = { _ -> fail("exception") },
                api = mockApi)

            val triple1 = cl.colleagues.get(author1.email)[0]
            assertEquals(triple1.first, author2.email,
                "Wrong colleague email #1")
            assertEquals(triple1.second, "1970-01", "Wrong colleague month #1")
            assertEquals(triple1.third, 60, "Wrong colleague vicinity #1")

            val triple2 = cl.colleagues.get(author2.email)[0]
            assertEquals(triple2.first, author1.email,
                "Wrong colleague email #1")
            assertEquals(triple2.second, "1970-01", "Wrong colleague month #1")
            assertEquals(triple2.third, 60, "Wrong colleague vicinity #1")
        }

        afterGroup {
            CodeLongevity(Repo(rehash = testRehash), emails, testRepo.git)
                .dropSavedData()
            testRepo.destroy()
        }
    }

    given("'colleagues stats'") {
        val testRepoPath = "../colleagues_stats"
        val testRepo = TestRepo(testRepoPath)
        val testRehash = "rehash_colleagues_stats"
        val fileName = "test1.txt"
        val author1 = Author(testRepo.userName, testRepo.userEmail)
        val author2 = Author("Vasya Pupkin", "vasya@pupkin.me")
        val emails = hashSetOf(author1.email, author2.email)

        val serverRepo = Repo(rehash = testRehash)

        it("'t1'") {
            val mockApi = MockApi(mockRepo = serverRepo)

            testRepo.createFile(fileName, listOf("line1", "line2"))
            testRepo.commit(message = "initial commit",
                author = author1,
                date = Calendar.Builder().setTimeOfDay(0, 0, 0)
                    .build().time)

            testRepo.deleteLines(fileName, 1, 1)
            testRepo.commit(message = "delete line",
                author = author2,
                date = Calendar.Builder().setTimeOfDay(0, 1, 0)
                    .build().time)

            testRepo.insertLines(fileName, 1, listOf("line in the end"))
            testRepo.commit(message = "insert line",
                author = author2,
                date = Calendar.Builder().setTimeOfDay(0, 10, 0)
                    .build().time)

            testRepo.deleteLines(fileName, 1, 1)
            testRepo.commit(message = "delete line #2",
                author = author1,
                date = Calendar.Builder().setTimeOfDay(0, 20, 0)
                    .build().time)

            CodeLongevity(serverRepo, emails, testRepo.git)
                .updateFromObservable(
                    onError = { _ -> fail("exception") },
                    api = mockApi)

            assertTrue(mockApi.receivedFacts.contains(
                Fact(repo = serverRepo,
                     code = FactCodes.COLLEAGUES,
                     value = author2.email,
                     value2 = author1.email,
                     value3 = (60).toString())
            ))
        }

        afterGroup {
            CodeLongevity(Repo(rehash = testRehash), emails, testRepo.git)
                .dropSavedData()
            testRepo.destroy()
        }
    }
})
