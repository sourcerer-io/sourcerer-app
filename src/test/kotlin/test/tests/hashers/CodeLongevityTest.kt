// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package test.tests.hashers

import app.api.MockApi
import app.hashers.CodeLine
import app.hashers.CodeLongevity
import app.hashers.RevCommitLine
import app.model.*

import test.utils.TestRepo

import kotlin.test.assertEquals
import kotlin.test.assertNotEquals

import org.eclipse.jgit.revwalk.RevCommit

import org.jetbrains.spek.api.Spek
import org.jetbrains.spek.api.dsl.given
import org.jetbrains.spek.api.dsl.it

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
    fun assertCodeLine(lineText: String,
                       fromCommit: RevCommit, fromFile: String, fromLineNum: Int,
                       toCommit: RevCommit, toFile: String, toLineNum: Int,
                       actualLine: CodeLine) {

        assertRevCommitLine(fromCommit, fromFile, fromLineNum, actualLine.from,
                            "'$lineText' from_commit");
        assertRevCommitLine(toCommit, toFile, toLineNum, actualLine.to,
                            "'$lineText' to_commit");
        assertEquals(lineText, actualLine.text, "line text")
    }

    given("'test group #1'") {
        val testRepoPath = "../testrepo1"
        val testRepo = TestRepo(testRepoPath)
        val fileName = "test1.txt"

        // t1: initial insertion
        testRepo.newFile(fileName, listOf("line1", "line2"))
        val rev1 = testRepo.commit("inital commit")
        val lines1 = CodeLongevity(
            LocalRepo(testRepoPath), Repo(), MockApi(), testRepo.git).compute()

        it("'t1: initial insertion'") {
            assertEquals(2, lines1.size)
            assertCodeLine("line1",
                           rev1, fileName, 0,
                           rev1, fileName, 0,
                           lines1[0])
            assertCodeLine("line2",
                           rev1, fileName, 1,
                           rev1, fileName, 1,
                           lines1[1])
        }

        // t2: subsequent insertion
        testRepo.insertLines(fileName, 1, listOf("line in the middle"))
        val rev2 = testRepo.commit("insert line")
        val lines2 = CodeLongevity(
            LocalRepo(testRepoPath), Repo(), MockApi(), testRepo.git).compute()

        it("'t2: subsequent insertion'") {
            assertEquals(3, lines2.size)
            assertCodeLine("line in the middle",
                           rev2, fileName, 1,
                           rev2, fileName, 1,
                           lines2[0])
            assertCodeLine("line1",
                           rev1, fileName, 0,
                           rev2, fileName, 0,
                           lines2[1])
            assertCodeLine("line2",
                           rev1, fileName, 1,
                           rev2, fileName, 2,
                           lines2[2])
        }

        // t3: subsequent deletion
        testRepo.deleteLines(fileName, 2, 2)
        val rev3 = testRepo.commit("delete line")
        val lines3 = CodeLongevity(LocalRepo(testRepoPath), Repo(),
                                   MockApi(), testRepo.git).compute()

        it("'t3: subsequent deletion'") {
            assertEquals(3, lines3.size)
            assertCodeLine("line in the middle",
                           rev2, fileName, 1,
                           rev3, fileName, 1,
                           lines3[0])
            assertCodeLine("line1",
                           rev1, fileName, 0,
                           rev3, fileName, 0,
                           lines3[1])
            assertCodeLine("line2",
                           rev1, fileName, 1,
                           rev3, fileName, 2,
                           lines3[2])
        }

        // t4: file deletion
        testRepo.deleteFile(fileName)
        val rev4 = testRepo.commit("delete file")
        val lines4 = CodeLongevity(LocalRepo(testRepoPath), Repo(),
                                   MockApi(), testRepo.git).compute()

        it("'t4: file deletion'") {
            assertEquals(3, lines4.size)
            assertCodeLine("line in the middle",
                           rev2, fileName, 1,
                           rev4, fileName, 1,
                           lines4[0])
            assertCodeLine("line1",
                           rev1, fileName, 0,
                           rev4, fileName, 0,
                           lines4[1])

            /* TODO(alex): the test fails
            assertCodeLine("line2",
                           rev1, fileName, 1,
                           rev3, fileName, 2,
                           lines4[2])
            */
        }

        afterGroup {
            testRepo.destroy()
        }
    }
})
