// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.hashers

import app.FactCodes
import app.Logger
import app.api.Api
import app.model.Author
import app.model.Fact
import app.model.Repo
import java.util.*
import kotlin.collections.HashSet

/**
 * MetaHasher hashes repository and uploads stats to server.
 */
class MetaHasher(private val serverRepo: Repo = Repo(),
                 private val api: Api) {
    fun calculateAndSendFacts(authors: HashSet<Author>,
                              commitsCount: HashMap<String, Int>,
                              userEmails: List<String>) {
        // Sometimes contributors use multiple emails to contribute to single
        // project, as we don't know exactly who is who (except current user),
        // let's at least filter authors by similarity.
        val otherAuthors = authors.filter { author ->
            !userEmails.contains(author.email)
        }
        // Current user may not be a contributor of repo.
        val isUserAuthor = otherAuthors.size < authors.size
        val numAuthors = getAuthorsNum(otherAuthors) +
            if (isUserAuthor) 1 else 0

        val facts = mutableListOf<Fact>()

        // Repository facts: team size.
        facts.add(FactCodes.REPO_TEAM_SIZE, 0, numAuthors)

        // Repository facts: commit share.
        val numAllCommits = commitsCount.values.fold(0) { acc, i -> acc + i  }
        val avgCommits = Math.round(numAllCommits.toDouble() / numAuthors)
            .toInt()
        facts.add(FactCodes.COMMIT_SHARE_REPO_AVG, 0, avgCommits)

        if (isUserAuthor) {
            val numUserCommits = userEmails
                .mapNotNull { email -> commitsCount[email] }
                .fold(0) { acc, i -> acc + i }
            val userEmail = userEmails.first()
            facts.add(FactCodes.COMMIT_SHARE, 0, numUserCommits, userEmail)
        }

        postFactsToServer(facts)
    }

    private fun getAuthorsNum(authors: List<Author>): Int {
        val names = authors.map { it.name }
        val emails = authors.map { it.email.split("@")[0] }
        val namesQgrams = names.map { getThreegrams(it) }
        val emailsQgrams = emails.map { getThreegrams(it) }

        val results = Array(authors.size) { Array(authors.size) {0} }

        for (i in 0..authors.size-2) {
            for (j in i+1 until authors.size) {
                if (isSameAuthor(namesQgrams[i], namesQgrams[j])) {
                    results[j][i] = 1
                }
                if (isSameAuthor(emailsQgrams[i], emailsQgrams[j])) {
                    results[j][i] = 1
                }
            }
        }

        return results.filter { it.sum() == 0 }.size
    }

    private fun isSameAuthor(firstThreegrams: Set<String>,
                             secondThreegrams: Set<String>): Boolean {
        val intersectionSize = firstThreegrams.intersect(secondThreegrams).size
        val unionSize = firstThreegrams.union(secondThreegrams).size
        val jaccardValue = intersectionSize.toFloat() / unionSize
        return jaccardValue >= 0.3
    }

    private fun getThreegrams(str: String): Set<String> {
        val threegrams = mutableSetOf<String>()
        for (i in 0..str.length-3) {
            threegrams.add(listOf(str[i], str[i+1], str[i+2]).joinToString(""))
        }
        return threegrams
    }

    private fun postFactsToServer(facts: List<Fact>) {
        if (facts.isNotEmpty()) {
            api.postFacts(facts).onErrorThrow()
            Logger.info { "Sent ${facts.size} facts to server" }
        }
    }

    private fun MutableList<Fact>.add(code: Int, key: Int, value: Any,
                                      email: String? = null) {
        val fact = if (email != null) {
            Fact(serverRepo, code, key, value.toString(), Author(email = email))
        } else {
            Fact(serverRepo, code, key, value.toString())
        }

        this.add(fact)
    }
}
