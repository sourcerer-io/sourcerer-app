// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.hashers

import app.FactCodes
import app.Logger
import app.api.Api
import app.extractors.Extractor
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
                 private val rehashes: List<String>,
                 private val emails: HashSet<String>) {
    private val fsDayWeek = hashMapOf<String, Array<Int>>()
    private val fsDayTime = hashMapOf<String, Array<Int>>()
    private val fsRepoDateStart = hashMapOf<String, Long>()
    private val fsRepoDateEnd = hashMapOf<String, Long>()
    private val fsCommitLineNumAvg = hashMapOf<String, Double>()
    private val fsCommitNum = hashMapOf<String, Int>()
    private val fsLineLenAvg = hashMapOf<String, Double>()
    private val fsLineNum = hashMapOf<String, Long>()
    private val fsLinesPerCommits = hashMapOf<String, Array<Int>>()
    private val fsVariableNaming = hashMapOf<String, Array<Int>>()
    private val fsIndentation = hashMapOf<String, Array<Int>>()

    private val varNamingRegex = Regex("[a-z][A-Z]")

    init {
        for (author in emails) {
            fsDayWeek[author] = Array(7) { 0 }
            fsDayTime[author] = Array(24) { 0 }
            fsRepoDateStart[author] = -1
            fsRepoDateEnd[author] = -1
            fsCommitLineNumAvg[author] = 0.0
            fsCommitNum[author] = 0
            fsLineLenAvg[author] = 0.0
            fsLineNum.put(author, 0)
            // TODO(anatoly): Do the bin computations on the go.
            fsLinesPerCommits[author] = Array(rehashes.size) {0}
            fsVariableNaming.put(author, Array(3) { 0 })
            fsIndentation.put(author, Array(2) { 0 })
        }
    }

    fun updateFromObservable(observable: Observable<Commit>,
                             onError: (Throwable) -> Unit) {
        observable
            .filter { commit -> emails.contains(commit.author.email) }
            .subscribe(onNext, onError, {  // OnComplete.
                try {
                    postFactsToServer(createFacts())
                } catch (e: Throwable) {
                    onError(e)
                }
            })
    }

    private val onNext: (Commit) -> Unit =  { commit ->
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
        if (fsRepoDateEnd[email]!! == -1L) {
            fsRepoDateEnd[email] = timestamp
        }

        // Commits.
        val numCommits = fsCommitNum[email]!! + 1
        val numLinesCurrent = commit.numLinesAdded + commit.numLinesDeleted

        fsCommitNum[email] = numCommits
        fsCommitLineNumAvg[email] = calcIncAvg(fsCommitLineNumAvg[email]!!,
            numLinesCurrent.toDouble(), numCommits.toLong())

        val lines = commit.getAllAdded() + commit.getAllDeleted()
        lines.forEachIndexed { index, line ->
            fsLineLenAvg[email] = calcIncAvg(fsLineLenAvg[email]!!,
                line.length.toDouble(), fsLineNum[email]!! + index + 1)
        }
        fsLineNum[email] = fsLineNum[email]!! + lines.size

        fsLinesPerCommits[email]!![numCommits - 1] += lines.size

        // Variable naming.
        lines.forEach { line ->
            val tokens = Extractor().tokenize(line)
            val underscores = tokens.count { it.contains('_') }
            val camelCases = tokens.count {
                !it.contains('_') && it.contains(varNamingRegex)
            }
            val others = tokens.size - underscores - camelCases
            fsVariableNaming[email]!![FactCodes.VARIABLE_NAMING_SNAKE_CASE] +=
                underscores
            fsVariableNaming[email]!![FactCodes.VARIABLE_NAMING_CAMEL_CASE] +=
                camelCases
            fsVariableNaming[email]!![FactCodes.VARIABLE_NAMING_OTHER] +=
                others
        }

        // Indentation.
        fsIndentation[email]!![FactCodes.INDENTATION_SPACES] +=
            lines.count { it.isNotBlank() && it.startsWith(" ") &&
                !it.contains("\t")}
        fsIndentation[email]!![FactCodes.INDENTATION_TABS] +=
            lines.count { it.startsWith("\t") }
    }

    private fun createFacts(): List<Fact> {
        val fs = mutableListOf<Fact>()
        emails.forEach { email ->
            val author = Author(email = email)
            fsDayTime[email]?.forEachIndexed { hour, count -> if (count > 0) {
                fs.add(Fact(serverRepo, FactCodes.COMMIT_DAY_TIME, hour,
                            count.toString(), author))
            }}
            fsDayWeek[email]?.forEachIndexed { day, count -> if (count > 0) {
                fs.add(Fact(serverRepo, FactCodes.COMMIT_DAY_WEEK, day,
                            count.toString(), author))
            }}
            fsVariableNaming[email]?.forEachIndexed { naming, count ->
                if (count > 0) {
                    fs.add(Fact(serverRepo, FactCodes.VARIABLE_NAMING, naming,
                            count.toString(), author))
                }
            }
            fsIndentation[email]?.forEachIndexed { indentation, count ->
                if (count > 0) {
                    fs.add(Fact(serverRepo, FactCodes.INDENTATION, indentation,
                            count.toString(), author))
                }
            }

            fs.add(Fact(serverRepo, FactCodes.REPO_DATE_START, 0,
                        fsRepoDateStart[email].toString(), author))
            fs.add(Fact(serverRepo, FactCodes.REPO_DATE_END, 0,
                        fsRepoDateEnd[email].toString(), author))
            fs.add(Fact(serverRepo, FactCodes.COMMIT_NUM, 0,
                        fsCommitNum[email].toString(), author))
            fs.add(Fact(serverRepo, FactCodes.COMMIT_LINE_NUM_AVG, 0,
                        fsCommitLineNumAvg[email].toString(), author))
            fs.add(Fact(serverRepo, FactCodes.LINE_NUM, 0,
                        fsLineNum[email].toString(), author))
            fs.add(Fact(serverRepo, FactCodes.LINE_LEN_AVG, 0,
                        fsLineLenAvg[email].toString(), author))
            val linesPerCommits = fsLinesPerCommits[email]!!
                .sliceArray(IntRange(0, fsCommitNum[email]!! - 1))
            addCommitsPerLinesFacts(fs, linesPerCommits, author)
        }
        return fs
    }

    private fun postFactsToServer(facts: List<Fact>) {
        if (facts.isNotEmpty()) {
            api.postFacts(facts).onErrorThrow()
            Logger.info { "Sent ${facts.size} facts to server" }
        }
    }

    /**
     * Computes the average of a numerical sequence.
     * Calculated numbers is never bigger than maximum element of sequence.
     * No overflow due to summing of elements.
     * @param prev previous value of average
     * @param element new element of sequence
     * @param count number of element in sequence
     * @return new value of average with considering of new element
     */
    private fun calcIncAvg(prev: Double, element: Double,
                           count: Long): Double {
        return prev * (1 - 1.0 / count) + element / count
    }

    private fun addCommitsPerLinesFacts(fs: MutableList<Fact>,
                                        linesPerCommits: Array<Int>,
                                        author: Author) {
        if (linesPerCommits.isEmpty()) return

        var max = linesPerCommits[0]
        var min = linesPerCommits[0]
        for (lines in linesPerCommits) {
            if (lines > max) {
                max = lines
            }
            if (lines < min) {
                min = lines
            }
        }

        val numBins = Math.min(10, max - min + 1)
        val binSize = (max - min + 1) / numBins.toDouble()
        val bins = Array(numBins) { 0 }
        for (numLines in linesPerCommits) {
            if (numLines == 0) {
                continue
            }

            val binId = Math.floor((numLines - min) / binSize).toInt()
            bins[binId]++
        }

        for ((binId, numCommits) in bins.withIndex()) {
            if (numCommits == 0) {
                continue
            }

            val numLines = Math.floor(min + binId * binSize).toInt()
            fs.add(Fact(serverRepo, FactCodes.COMMIT_NUM_TO_LINE_NUM,
                numLines, numCommits.toString(), author))
        }
    }
}
