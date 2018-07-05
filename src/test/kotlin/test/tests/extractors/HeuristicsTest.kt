// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package test.tests.extractors

import app.model.DiffFile
import app.model.DiffContent
import app.extractors.*
import org.apache.commons.io.FilenameUtils
import org.eclipse.jgit.diff.DiffEntry.ChangeType
import org.jetbrains.spek.api.Spek
import org.jetbrains.spek.api.dsl.given
import org.jetbrains.spek.api.dsl.it
import java.io.File
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals

const val LANG_SAMPLES_PATH = "src/test/resources/samples/"

fun assertLang(file: File, expectedLang: String) {
    val diffFile = DiffFile(
        file.path,
        changeType = ChangeType.ADD,
        new = DiffContent(content = file.readLines())
    )
    Extractor().extract(listOf(diffFile))

    val actualLang = diffFile.lang

    // TODO(anatoly): Add support for all languages of samples.
    var todoSample = false;
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
    }
})
