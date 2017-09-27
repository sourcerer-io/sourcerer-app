// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.hashers

import app.FactCodes
import app.Logger
import app.api.Api
import app.model.Author
import app.model.Commit
import app.model.Fact
import app.model.LocalRepo
import app.model.Repo
import io.reactivex.Observable
import java.time.LocalDateTime
import java.time.ZoneOffset

/**
 * CommitHasher hashes repository and uploads stats to server.
 */
class FactHasher(private val localRepo: LocalRepo,
                 private val serverRepo: Repo = Repo(),
                 private val api: Api) {

    private fun postFactsToServer(facts: List<Fact>) {
        if (facts.isNotEmpty()) {
            api.postFacts(facts)
            Logger.debug("Sent ${facts.size} facts to server")
        }
    }

    fun updateFromObservable(observable: Observable<Commit>) {
        val factsDayWeek = hashMapOf<Author, Array<Int>>()
        val factsDayTime = hashMapOf<Author, Array<Int>>()

        val throwables = mutableListOf<Throwable>()

        // TODO(anatoly): Filter hashing by email as in CommitHasher.
        observable
            .subscribe({ commit ->  // OnNext.
                // Calculate facts.
                val author = commit.author
                val factDayWeek = factsDayWeek[author] ?: Array(7) { 0 }
                val factDayTime = factsDayTime[author] ?: Array(24) { 0 }
                val timestamp = commit.dateTimestamp
                val dateTime = LocalDateTime.ofEpochSecond(timestamp, 0,
                    ZoneOffset.ofTotalSeconds(commit.dateTimeZoneOffset * 60))
                // The value is numbered from 1 (Monday) to 7 (Sunday).
                factDayWeek[dateTime.dayOfWeek.value - 1] += 1
                // Hour from 0 to 23.
                factDayTime[dateTime.hour] += 1
                factsDayWeek[author] = factDayWeek
                factsDayTime[author] = factDayTime
            }, { e ->  // OnError.
                throwables.add(e)  // TODO(anatoly): Top-class handling errors.
            }, {  // OnComplete.
                try {
                    val facts = mutableListOf<Fact>()
                    factsDayTime.map { (author, list) ->
                        list.forEachIndexed { hour, count ->
                            if (count > 0) {
                                facts.add(Fact(serverRepo,
                                    FactCodes.COMMITS_DAY_TIME, hour,
                                    count.toDouble(), author))
                            }
                        }
                    }
                    factsDayWeek.map { (author, list) ->
                        list.forEachIndexed { day, count ->
                            if (count > 0) {
                                facts.add(Fact(serverRepo,
                                    FactCodes.COMMITS_DAY_WEEK, day,
                                    count.toDouble(), author))
                            }
                        }
                    }
                    postFactsToServer(facts)
                } catch (e: Throwable) {
                    throwables.add(e)
                }
            })
    }
}
