// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package test.utils

import app.model.Author
import app.model.Fact
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

fun getFact(code: Int, key: Int, author: Author? = null,
            facts: List<Fact>): Fact {
    val fact = facts.find { fact -> fact.code == code && fact.key == key &&
        (author == null || fact.author == author) }
    assertNotNull(fact)
    return fact!!
}

fun assertFactInt(code: Int, key: Int, value: Int, author: Author? = null,
                  facts: List<Fact>) {
    val fact = getFact(code, key, author, facts)
    assertEquals(value, fact.value.toInt())
}

fun assertNoFact(code: Int, key: Int, author: Author? = null,
                 facts: List<Fact>) {
    val fact = facts.find { fact -> fact.code == code && fact.key == key &&
        (author == null || fact.author == author) }
    assertNull(fact)
}

fun assertFactDouble(code: Int, key: Int, value: Double, author: Author? = null,
                     facts: List<Fact>) {
    val fact = getFact(code, key, author, facts)
    assertTrue(Math.abs(value - fact.value.toDouble()) < 0.1,
        "Expected approximately <$value>, actual <${fact.value}>")
}
