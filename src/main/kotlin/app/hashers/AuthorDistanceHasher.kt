// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.hashers

import app.api.Api
import app.model.AuthorDistance
import app.model.Repo
import io.reactivex.Observable
import java.util.concurrent.TimeUnit

class AuthorDistanceHasher(
        private val serverRepo: Repo,
        private val api: Api,
        private val emails: HashSet<String>,
        private val userEmails: HashSet<String>) {
    fun updateFromObservable(observable: Observable<JgitData>,
                             onError: (Throwable) -> Unit) {
        val authorScores = hashMapOf<String, Double>()
        emails.forEach { authorScores[it] = 0.0 }

        // Store the time of the earliest commit for a path by user.
        val authorPathLastContribution = hashMapOf<String, Long>()

        observable.subscribe({
            val email =  it.email!!
            val paths = it.paths!!
            val time = it.date!!
            if (email in userEmails) {
                paths.forEach { path ->
                    authorPathLastContribution[path] = time
                }
            }
            else {
                val score = paths
                     .filter { path -> path in authorPathLastContribution }
                     .filter { path ->
                        val authorTime = authorPathLastContribution[path]!!
                        val timeDelta = TimeUnit.DAYS.convert(
                                authorTime - time, TimeUnit.SECONDS)
                         timeDelta < 365
                     }.size
                authorScores[email] = authorScores[email]!! + score
            }
        }, onError, {
            val stats = mutableListOf<AuthorDistance>()
            authorScores.forEach { email, value ->
                if (email !in userEmails) {
                    stats.add(AuthorDistance(serverRepo, email, value))
                }
            }
            postDistancesToServer(stats)
        })
    }

    private fun postDistancesToServer(stats: List<AuthorDistance>) {
        if (stats.isNotEmpty()) {
            api.postAuthorDistances(stats).onErrorThrow()
        }
    }
}
