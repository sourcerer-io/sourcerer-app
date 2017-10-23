// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.hashers

import app.FactCodes
import app.Logger
import app.api.Api
import app.model.Author
import app.model.Commit
import app.model.Fact
import app.model.Repo
import io.reactivex.Observable
import java.time.LocalDateTime
import java.time.ZoneOffset

/**
 * CommitHasher hashes repository and uploads stats to server.
 */
class FactHasher(private val serverRepo: Repo = Repo(),
                 private val api: Api,
                 private val emails: HashSet<String>) {
    private val fsDayWeek = hashMapOf<String, Array<Int>>()
    private val fsDayTime = hashMapOf<String, Array<Int>>()
    private val fsRepoDateStart = hashMapOf<String, Long>()
    private val fsRepoDateEnd = hashMapOf<String, Long>()
    private val fsRepoTeamSize = hashSetOf<String>()

    init {
        for (author in emails) {
            fsDayWeek.put(author, Array(7) { 0 })
            fsDayTime.put(author, Array(24) { 0 })
            fsRepoDateStart.put(author, -1)
            fsRepoDateEnd.put(author, -1)
        }
    }

    fun updateFromObservable(observable: Observable<Commit>,
                             onError: (Throwable) -> Unit) {
        observable
            .filter { commit -> emails.contains(commit.author.email) }
            .subscribe({ commit ->  // OnNext.
                // Calculate facts.
                val email = commit.author.email
                val timestamp = commit.dateTimestamp
                val dateTime = LocalDateTime.ofEpochSecond(timestamp, 0,
                    ZoneOffset.ofTotalSeconds(commit.dateTimeZoneOffset * 60))

                // DayWeek.
                val factDayWeek = fsDayWeek[email] ?: Array(7) { 0 }
                // The value is numbered from 1 (Monday) to 7 (Sunday).
                factDayWeek[dateTime.dayOfWeek.value - 1] += 1
                fsDayWeek[email] = factDayWeek

                // DayTime.
                val factDayTime = fsDayTime[email] ?: Array(24) { 0 }
                // Hour from 0 to 23.
                factDayTime[dateTime.hour] += 1
                fsDayTime[email] = factDayTime

                // RepoDateStart.
                fsRepoDateStart[email] = timestamp

                // RepoDateEnd.
                if ((fsRepoDateEnd[email] ?: -1) == -1L) {
                    fsRepoDateEnd[email] = timestamp
                }

                // RepoTeamSize.
                fsRepoTeamSize.add(email)
            }, onError, {  // OnComplete.
                try {
                    postFactsToServer(createFacts())
                } catch (e: Throwable) {
                    onError(e)
                }
            })
    }

    private fun createFacts(): List<Fact> {
        val fs = mutableListOf<Fact>()
        emails.forEach { email ->
            val author = Author(email = email)
            fsDayTime[email]?.forEachIndexed { hour, count -> if (count > 0) {
                fs.add(Fact(serverRepo, FactCodes.COMMITS_DAY_TIME, hour,
                            count.toString(), author))
            }}
            fsDayWeek[email]?.forEachIndexed { day, count -> if (count > 0) {
                fs.add(Fact(serverRepo, FactCodes.COMMITS_DAY_WEEK, day,
                            count.toString(), author))
            }}
            fs.add(Fact(serverRepo, FactCodes.REPO_DATE_START, 0,
                        fsRepoDateStart[email].toString(), author))
            fs.add(Fact(serverRepo, FactCodes.REPO_DATE_END, 0,
                        fsRepoDateEnd[email].toString(), author))
        }
        fs.add(Fact(serverRepo, FactCodes.REPO_TEAM_SIZE, 0,
                    fsRepoTeamSize.size.toString()))
        return fs
    }

    private fun postFactsToServer(facts: List<Fact>) {
        if (facts.isNotEmpty()) {
            api.postFacts(facts)
            Logger.info("Sent ${facts.size} facts to server")
        }
    }
}
