// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Ryan Osilla (ryan@sourcerer.io)

package test.tests.utils

import org.jetbrains.spek.api.Spek
import org.jetbrains.spek.api.dsl.given
import org.jetbrains.spek.api.dsl.it
import kotlin.test.assertEquals
import app.utils.FileHelper.toPath
import java.nio.file.Paths

fun testPath(expectedPath: String, actualPath: String) {
    assertEquals(Paths.get(expectedPath), actualPath.toPath())
}

class FileHelperTest : Spek({
    given("relative path test") {
        it("basic") {
            val home = System.getProperty("user.home")
            testPath("/Users/user/repo", "/Users/user/repo")
            testPath("/Users/user/repo", "/Users/user/../user/repo/../repo")
            testPath("$home/test", "~/test")
            testPath("$home/test1", "~/test/../test1")
        }
    }
})
