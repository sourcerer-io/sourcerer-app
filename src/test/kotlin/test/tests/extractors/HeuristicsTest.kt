// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package test.tests.extractors

import app.model.DiffFile
import app.model.DiffContent
import app.extractors.*
import app.model.DiffRange
import org.apache.commons.io.FilenameUtils
import org.eclipse.jgit.diff.DiffEntry.ChangeType
import org.jetbrains.spek.api.Spek
import org.jetbrains.spek.api.dsl.given
import org.jetbrains.spek.api.dsl.it
import java.io.File
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

const val LANG_SAMPLES_PATH = "src/test/resources/samples/langs/"
const val DEVOPS_SAMPLES_PATH = "src/test/resources/samples/devops/"

fun assertLang(file: File, expectedLang: String) {
    val diffFile = DiffFile(
        file.path,
        changeType = ChangeType.ADD,
        new = DiffContent(content = file.readLines())
        // TODO(anatoly): Should we specify ranges here?
    )
    Extractor().extract(listOf(diffFile))

    val actualLang = diffFile.lang

    // TODO(anatoly): Add support for all languages of samples.
    var todoSample = false
    for (wc in ignoredSamplesWildcards) {
        if (FilenameUtils.wildcardMatchOnSystem(file.path, wc)) {
            todoSample = true
            break
        }
    }

    if (todoSample) {
        assertNotEquals(expectedLang, actualLang, "Unexpected lang for ${file.path}")
    }
    else {
        assertEquals(expectedLang, actualLang, "Unexpected lang for ${file.path}")
    }
}

fun assertTech(file: File, expectedTech: String) {
    val content = file.readLines()
    val diffFile = DiffFile(
        file.path,
        changeType = ChangeType.ADD,
        new = DiffContent(
            content = content,
            ranges = listOf(DiffRange(start = 0, end = content.size))
        )
    )

    val stats = Extractor().extract(listOf(diffFile))

    assertFalse("No stats for $file") {
        stats.isEmpty()
    }

    assertTrue("Wrong type for $file") {
        stats.first().type == ExtractorInterface.TYPE_LIBRARY
    }

    val actualTech = stats.first().tech

    assertEquals(expectedTech, actualTech, "Unexpected tech for ${file.path}")
}

class HeuristicsTest : Spek({
    given("heuristics test") {
        it("all language samples") {
            for (dir in File(LANG_SAMPLES_PATH).listFiles()) {
                val expectedLang = dirToLangMap.getOrDefault(
                    dir.name, dir.name.toLowerCase()
                )
                for (file in dir.walkTopDown()) {
                    if (file.isFile) assertLang(file, expectedLang)
                }
            }
        }
        it("all devops samples") {
            for (dir in File(DEVOPS_SAMPLES_PATH).listFiles()) {
                val expectedTech = DevopsExtractor.DEVOPS + dir.name

                for (file in dir.walkTopDown()) {
                    if (!file.isFile) continue

                    var skip = false
                    for (wc in ignoredSamplesWildcards) {
                        if (FilenameUtils.wildcardMatchOnSystem(file.path,
                                wc)) {
                            skip = true
                            break
                        }
                    }
                    if (skip) break

                    assertTech(file, expectedTech)
                }
            }
        }
    }
})
