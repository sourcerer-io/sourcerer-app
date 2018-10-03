// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package test.tests.hashers

import app.api.MockApi
import app.FactCodes
import app.hashers.CodeLine
import app.hashers.CodeLineAges
import app.hashers.CodeLongevity
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
class CodeLongevityTest : Spek({

    /**
     * Assert function to test RevCommitLine object.
     */
    fun assertRevCommitLine(expectedCommit: RevCommit,
                            expectedFile: String,
                            expectedLineNum: Int,
                            actualLine: RevCommitLine,
                            messsage: String = "") {

        assertEquals(expectedCommit, actualLine.commit, "$messsage commit")
        assertEquals(expectedFile, actualLine.file, "$messsage file name")
        assertEquals(expectedLineNum, actualLine.line, "$messsage line num")
    }

    /**
     * Assert function to test CodeLine object.
     */
    fun assertCodeLine(lineText: String, isDeleted: Boolean,
                       fromCommit: RevCommit, fromFile: String,
                       fromLineNum: Int, toCommit: RevCommit, toFile: String,
                       toLineNum: Int, actualLine: CodeLine) {

        assertRevCommitLine(fromCommit, fromFile, fromLineNum, actualLine.from,
                            "'$lineText' from_commit")
        assertRevCommitLine(toCommit, toFile, toLineNum, actualLine.to,
                            "'$lineText' to_commit")

        assertEquals(lineText, actualLine.text, "line text")
        assertEquals(isDeleted, actualLine.isDeleted, "'$lineText' " +
            "line is deleted")
    }

    Runtime.getRuntime().exec("rm -r ./.sourcerer/longevity").waitFor()

    given("'line collecting #1'") {
        val testRepoPath = "../CodeLongevity_lc1"
        val testRepo = TestRepo(testRepoPath)
        val fileName = "test1.txt"
        val emails = hashSetOf(testRepo.userEmail)

        // t1: initial insertion
        testRepo.createFile(fileName, listOf("line1", "line2"))
        val rev1 = testRepo.commit("initial commit")
        val lines1 = CodeLongevity(Repo(), emails, testRepo.git)
            .getLinesList(onError = { _ -> fail("exception") })

        it("'t1: initial insertion'") {
            assertEquals(2, lines1.size)
            assertCodeLine("line1", false,
                           rev1, fileName, 0,
                           rev1, fileName, 0,
                           lines1[0])
            assertCodeLine("line2", false,
                           rev1, fileName, 1,
                           rev1, fileName, 1,
                           lines1[1])
        }

        // t2: subsequent insertion
        testRepo.insertLines(fileName, 1, listOf("line in the middle"))
        val rev2 = testRepo.commit("insert line")
        val lines2 = CodeLongevity(Repo(), emails, testRepo.git)
            .getLinesList(onError = { _ -> fail("exception") })

        it("'t2: subsequent insertion'") {
            assertEquals(3, lines2.size)
            assertCodeLine("line in the middle", false,
                           rev2, fileName, 1,
                           rev2, fileName, 1,
                           lines2[0])
            assertCodeLine("line1", false,
                           rev1, fileName, 0,
                           rev2, fileName, 0,
                           lines2[1])
            assertCodeLine("line2", false,
                           rev1, fileName, 1,
                           rev2, fileName, 2,
                           lines2[2])
        }

        // t3: subsequent deletion
        testRepo.deleteLines(fileName, 2, 2)
        val rev3 = testRepo.commit("delete line")
        val lines3 = CodeLongevity(Repo(), emails, testRepo.git)
            .getLinesList(onError = { _ -> fail("exception") })

        it("'t3: subsequent deletion'") {
            assertEquals(3, lines3.size)
            assertCodeLine("line in the middle", false,
                           rev2, fileName, 1,
                           rev3, fileName, 1,
                           lines3[0])
            assertCodeLine("line1", false,
                           rev1, fileName, 0,
                           rev3, fileName, 0,
                           lines3[1])
            assertCodeLine("line2", true,
                           rev1, fileName, 1,
                           rev3, fileName, 2,
                           lines3[2])
        }

        // t4: file deletion
        testRepo.deleteFile(fileName)
        val rev4 = testRepo.commit("delete file")
        val lines4 = CodeLongevity(Repo(), emails, testRepo.git)
            .getLinesList(onError = { _ -> fail("exception") })

        it("'t4: file deletion'") {
            assertEquals(3, lines4.size)
            assertCodeLine("line in the middle", true,
                           rev2, fileName, 1,
                           rev4, fileName, 1,
                           lines4[0])
            assertCodeLine("line1", true,
                           rev1, fileName, 0,
                           rev4, fileName, 0,
                           lines4[1])

            assertCodeLine("line2", true,
                           rev1, fileName, 1,
                           rev3, fileName, 2,
                           lines4[2])
        }

        afterGroup {
            testRepo.destroy()
        }
    }

    given("'line collecting #2'") {
        val testRepoPath = "../CodeLongevity_lc2"
        val testRepo = TestRepo(testRepoPath)
        val fileName = "test1.txt"
        val emails = hashSetOf(testRepo.userEmail)

        // t2.1: initial insertion
        val fileContent = listOf(
          "line0",
          "line1",
          "line2",
          "line3",
          "line4",
          "line5",
          "line6",
          "line7",
          "line8",
          "line9",
          "line10",
          "line11",
          "line12",
          "line13",
          "line14",
          "line15",
          "line16",
          "line17",
          "line18"
        )
        testRepo.createFile(fileName, fileContent)
        val rev1 = testRepo.commit("initial commit")
        val lines1 = CodeLongevity(Repo(), emails, testRepo.git)
            .getLinesList(onError = { _ -> fail("exception") })

        it("'t2.1: initial insertion'") {
            assertEquals(fileContent.size, lines1.size)
            for (idx in 0 .. fileContent.size - 1) {
                assertCodeLine(fileContent[idx], false,
                               rev1, fileName, idx,
                               rev1, fileName, idx,
                               lines1[idx])
            }
        }

        // t2.2: ins+del

        // Diff:
        // 0  0     line0
        // 1  1     line1
        // 2  2     line2
        // 3     -  line3
        // 4     -  line4
        // 5     -  line5
        //    3  +  Proof addition 1
        // 6  4     line6
        // 7  5     line7
        // 8  6     line8
        // 9     -  line9
        // 10    -  line10
        // 11    -  line11
        //    7  +  Proof addition 2
        // 12 8     line12
        // 13 9     line13
        // 14 10    line14
        // 15    -  line15
        // 16    -  line16
        // 17    -  line17
        // 18    -  line18
        //    11 +  Proof addition 3

        testRepo.deleteLines(fileName, 15, 18)
        testRepo.deleteLines(fileName, 9, 11)
        testRepo.deleteLines(fileName, 3, 5)
        testRepo.insertLines(fileName, 3, listOf("Proof addition 1"))
        testRepo.insertLines(fileName, 7, listOf("Proof addition 2"))
        testRepo.insertLines(fileName, 11, listOf("Proof addition 3"))
        val rev2 = testRepo.commit("insert+delete")

        val lines2 = CodeLongevity(Repo(), emails, testRepo.git)
            .getLinesList(onError = { _ -> fail("exception") })

        it("'t2.2: ins+del'") {
            assertEquals(22, lines2.size)
            assertCodeLine("Proof addition 3", false,
                           rev2, fileName, 11, rev2,
                           fileName, 11, lines2[0])
            assertCodeLine("Proof addition 2", false,
                           rev2, fileName, 7,
                           rev2, fileName, 7, lines2[1])
            assertCodeLine("Proof addition 1", false,
                           rev2, fileName, 3,
                           rev2, fileName, 3, lines2[2])
            assertCodeLine("line0", false,
                           rev1, fileName, 0,
                           rev2, fileName, 0, lines2[3])
            assertCodeLine("line1", false,
                           rev1, fileName, 1,
                           rev2, fileName, 1, lines2[4])
            assertCodeLine("line2", false,
                           rev1, fileName, 2,
                           rev2, fileName, 2, lines2[5])
            assertCodeLine("line3", true,
                           rev1, fileName, 3,
                           rev2, fileName, 3, lines2[6])
            assertCodeLine("line4", true,
                           rev1, fileName, 4,
                           rev2, fileName, 4, lines2[7])
            assertCodeLine("line5", true,
                           rev1, fileName, 5,
                           rev2, fileName, 5, lines2[8])
            assertCodeLine("line6", false,
                           rev1, fileName, 6,
                           rev2, fileName, 4, lines2[9])
            assertCodeLine("line7", false,
                           rev1, fileName, 7,
                           rev2, fileName, 5, lines2[10])
            assertCodeLine("line8", false,
                           rev1, fileName, 8,
                           rev2, fileName, 6, lines2[11])
            assertCodeLine("line9", true,
                           rev1, fileName, 9,
                           rev2, fileName, 9, lines2[12])
            assertCodeLine("line10", true,
                           rev1, fileName, 10,
                           rev2, fileName, 10, lines2[13])
            assertCodeLine("line11", true,
                           rev1, fileName, 11,
                           rev2, fileName, 11, lines2[14])
            assertCodeLine("line12", false,
                           rev1, fileName, 12,
                           rev2, fileName, 8, lines2[15])
        }

        afterGroup {
            testRepo.destroy()
        }
    }

    given("'line collecting #3: between revisions'") {
        val testRepoPath = "../CodeLongevity_lc3"
        val testRepo = TestRepo(testRepoPath)
        val fileName = "test1.txt"
        val emails = hashSetOf(testRepo.userEmail)

        testRepo.createFile(fileName, listOf("line1", "line2"))
        val rev1 = testRepo.commit("initial commit")
        testRepo.insertLines(fileName, 1, listOf("line15"))
        val rev2 = testRepo.commit("insert line")
        testRepo.deleteLines(fileName, 2, 2)
        val rev3 = testRepo.commit("delete line2")

        val lines1 = CodeLongevity(Repo(), emails, testRepo.git)
            .getLinesList(onError = { _ -> fail("exception") })
        val lines1_line15 = lines1[0]
        val lines1_line1 = lines1[1]
        val lines1_line2 = lines1[2]

        it("'before'") {
            assertEquals(3, lines1.size)
            assertCodeLine("line15", false,
                           rev2, fileName, 1,
                           rev3, fileName, 1,
                           lines1_line15)
            assertCodeLine("line1", false,
                           rev1, fileName, 0,
                           rev3, fileName, 0,
                           lines1_line1)
            assertCodeLine("line2", true,
                           rev1, fileName, 1,
                           rev3, fileName, 2,
                           lines1_line2)
        }

        testRepo.deleteLines(fileName, 0, 0)
        val rev4 = testRepo.commit("delete line1")

        val lines2 = CodeLongevity(Repo(), emails, testRepo.git)
            .getLinesList(rev3, onError = { _ -> fail("exception") })
        val lines2_line1 = lines2[0]
        val lines2_line15 = lines2[1]

        it("'after'") {
            assertEquals(2, lines2.size)
            assertCodeLine("line1", true,
                           rev3, fileName, 0,
                           rev4, fileName, 0,
                           lines2_line1)
            assertEquals(lines1_line1.newId, lines2_line1.oldId,
                         "line1 old and new ids matching")

            assertCodeLine("line15", false,
                           rev3, fileName, 1,
                           rev4, fileName, 0,
                           lines2_line15)
            assertEquals(lines1_line15.newId, lines2_line15.oldId,
                         "line15 old and new ids matching")

        }

        afterGroup {
            testRepo.destroy()
        }
    }

    given("'line storage #1'") {
        val testRepoPath = "../CodeLongevity_ls1"
        val testRepo = TestRepo(testRepoPath)
        val testRehash = "rehash_ls1"
        val fileName = "test1.txt"
        val email = testRepo.userEmail
        val emails = hashSetOf(email)
        val api = MockApi()

        testRepo.createFile(fileName, listOf("line1", "line2"))
        testRepo.commit(message = "initial commit",
            date = Calendar.Builder().setTimeOfDay(0, 0, 0).build().time)
        testRepo.insertLines(fileName, 1, listOf("line15"))
        testRepo.commit(message = "insert line",
            date = Calendar.Builder().setTimeOfDay(0, 1, 0).build().time)

        var t1Ages: CodeLineAges? = null
        CodeLongevity(Repo(rehash = testRehash), emails, testRepo.git)
            .updateFromObservable(onError = { _ -> fail("exception") },
                                  onDataComplete = { t1Ages = it.clone() },
                                  api = api)
        val t1Lines = CodeLongevity(Repo(rehash = testRehash), emails,
            testRepo.git).getLinesList(onError = { _ -> fail("exception") })

        it("'t1'") {
            assertNotNull(t1Ages)
            assertTrue(t1Ages!!.aggrAges.isEmpty(),
                "t1_ages: aggr ages is empty")
            assertEquals(3, t1Ages!!.lastingLines.count(),
                "t1_ages: lasting lines count")
            for (line in t1Lines) {
                assertEquals(t1Ages!!.lastingLines[line.newId]!!.age, line.age,
                    "t1_ages: line age at '${line.newId}'")
            }
        }

        testRepo.deleteLines(fileName, 2, 2)
        testRepo.commit(message = "delete line2",
            date = Calendar.Builder().setTimeOfDay(0, 3, 0).build().time)

        var t2Ages: CodeLineAges? = null
        CodeLongevity(Repo(rehash = testRehash), emails, testRepo.git)
            .updateFromObservable(onError = { _ -> fail("exception") },
                                  onDataComplete = { t2Ages = it.clone() },
                                  api = api)
        val t2Lines = CodeLongevity(Repo(rehash = testRehash), emails,
            testRepo.git).getLinesList(onError = { _ -> fail("exception") })

        it("'t2'") {
            assertNotNull(t2Ages)
            assertEquals(1, t2Ages!!.aggrAges[email]!!.count,
                "t2_ages: aggr ages count")
            assertEquals(180, t2Ages!!.aggrAges[email]!!.sum,
                "t2_ages: aggr ages sum") // line2
            assertEquals(2, t2Ages!!.lastingLines.count(),
                "t2_ages: lasting lines count")

            val line1 = t2Lines.find { line -> line.text == "line1" }!!
            val line15 = t2Lines.find { line -> line.text == "line15" }!!
            assertEquals(180, t2Ages!!.lastingLines[line1.newId]!!.age,
                "t2_ages: 'line1' line age")
            assertEquals(120, t2Ages!!.lastingLines[line15.newId]!!.age,
                "t2_ages: 'line15' line age")
        }

        afterGroup {
            CodeLongevity(Repo(rehash = testRehash), emails, testRepo.git)
                .dropSavedData()
            testRepo.destroy()
        }
    }

    given("'longevity stats #1'") {
        val testRepoPath = "../CodeLongevity_lngstats1"
        val testRepo = TestRepo(testRepoPath)
        val testRehash = "rehash_lngstats1"
        val fileName = "test1.txt"
        val author1 = Author(testRepo.userName, testRepo.userEmail)
        val author2 = Author("Vasya Pupkin", "vasya@pupkin.me")
        val emails = hashSetOf(testRepo.userEmail)

        val serverRepo = Repo(rehash = testRehash)
        val api = MockApi(mockRepo = serverRepo)

        testRepo.createFile(fileName, listOf("line1", "line2"))
        testRepo.commit(message = "initial commit",
                        author = author1,
                        date = Calendar.Builder().setTimeOfDay(0, 0, 0)
                            .build().time)

        testRepo.insertLines(fileName, 1, listOf("line15"))
        testRepo.commit(message = "insert line",
                        author = author2,
                        date = Calendar.Builder().setTimeOfDay(0, 1, 0)
                            .build().time)

        testRepo.insertLines(fileName, 2, listOf("line17"))
        testRepo.commit(message = "insert line2",
                        author = author1,
                        date = Calendar.Builder().setTimeOfDay(0, 3, 0)
                            .build().time)

        testRepo.deleteLines(fileName, 2, 2)
        testRepo.commit(message = "delete line",
                        author = author1,
                        date = Calendar.Builder().setTimeOfDay(0, 4, 0)
                            .build().time)

        CodeLongevity(serverRepo, emails, testRepo.git).updateFromObservable(
            onError = { _ -> fail("exception") }, api = api)

        it("'t1'") {
            assertTrue(api.receivedFacts.contains(
                Fact(repo = serverRepo,
                     code = FactCodes.LINE_LONGEVITY_REPO,
                     value = (720 / 4).toString())
            ))

            assertTrue(api.receivedFacts.contains(
                Fact(repo = serverRepo,
                     code = FactCodes.LINE_LONGEVITY,
                     author = author1,
                     value = (540 / 3).toString())
            ))
        }

        afterGroup {
            CodeLongevity(Repo(rehash = testRehash), emails, testRepo.git)
                .dropSavedData()
            testRepo.destroy()
        }
    }

    given("'longevity stats #2'") {
        val testRepoPath = "../CodeLongevity_lngstats2"
        val testRepo = TestRepo(testRepoPath)
        val testRehash = "rehash_lngstats2"
        val fileName = "test1.txt"
        val author1 = Author(testRepo.userName, testRepo.userEmail)
        val author2 = Author("Vasya Pupkin", "vasya@pupkin.me")
        val emails = hashSetOf(author1.email, author2.email)

        val serverRepo = Repo(rehash = testRehash)
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

        CodeLongevity(serverRepo, emails, testRepo.git)
            .updateFromObservable(onError = { _ -> fail("exception") },
                                  api = mockApi)

        it("'t1'") {
            assertTrue(mockApi.receivedFacts.contains(
                Fact(repo = serverRepo,
                     code = FactCodes.LINE_LONGEVITY_REPO,
                     value = (60).toString())
            ))

            assertTrue(mockApi.receivedFacts.contains(
                Fact(repo = serverRepo,
                     code = FactCodes.LINE_LONGEVITY,
                     author = author1,
                     value = (60).toString())
            ))

            assertTrue(mockApi.receivedFacts.contains(
                Fact(repo = serverRepo,
                     code = FactCodes.LINE_LONGEVITY,
                     author = author2,
                     value = (0).toString())
            ))
        }

        afterGroup {
            CodeLongevity(Repo(rehash = testRehash), emails, testRepo.git)
                .dropSavedData()
            testRepo.destroy()
        }
    }
})
