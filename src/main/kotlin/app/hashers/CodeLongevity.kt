// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.hashers

import app.FactCodes
import app.Logger
import app.api.Api
import app.model.Author
import app.model.Repo
import app.model.Fact
import app.utils.FileHelper
import io.reactivex.Observable
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.diff.RawText
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.lib.AnyObjectId
import org.eclipse.jgit.lib.Repository
import org.eclipse.jgit.revwalk.RevCommit
import org.eclipse.jgit.revwalk.RevWalk
import org.eclipse.jgit.treewalk.TreeWalk

import java.io.FileInputStream
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.ObjectOutputStream
import java.io.ObjectInputStream
import java.io.Serializable
import java.lang.Exception
import java.text.SimpleDateFormat
import java.util.Date

/**
 * Represents a code line in a file revision.
 */
class RevCommitLine(val commit: RevCommit, val fileId: AnyObjectId,
                    val file: String, val line: Int,
                    val isDeleted: Boolean) {

    val id : String
        get() = "${fileId.name}:$line"
}

/**
 * Represents a code line in repo's history.
 *
 * TODO(Alex): the text arg is solely for testing proposes (remove it)
 */
class CodeLine(val repo: Repository,
               val from: RevCommitLine, val to: RevCommitLine) {

    // TODO(alex): oldId and newId may be computed as a hash built from commit,
    // file name and line number, if we are going to send the data outside a
    // local machine.

    /**
     * Id of the code line in a revision when the line was added. Used to
     * identify a line and update its lifetime computed at the previous
     * iteration.
     */
    val oldId : String
        get() = from.id

    /**
     * Id of the code line in a revision, where the line was deleted, or a head
     * revision, if the line is alive.
     */
    val newId : String
        get() = to.id

    /**
     * The code line's age in seconds.
     */
    var age : Long = 0
        get() {
            if (field == 0L) {
                field = (to.commit.commitTime - from.commit.commitTime).toLong()
            }
            return field
        }

    /**
     * The code line text.
     */
    val text : String
        get() = RawText(repo.open(from.fileId).bytes).getString(from.line)

    /**
     * Email address of the line's author.
     */
    val authorEmail : String
        get() = from.commit.authorIdent.emailAddress

    /**
     * Email address of the line's changer.
     */
    val editorEmail : String?
      get() = if (isDeleted) to.commit.authorIdent.emailAddress else null

    /**
     * A date when the line was changed.
     */
    val editDate : Date
        get() = Date(to.commit.commitTime.toLong() * 1000)

    /**
     * True if the line is deleted.
     */
    val isDeleted : Boolean
        get() = to.isDeleted

    /**
     * A pretty print of a code line; debugging.
     */
    override fun toString() : String {
        val df = SimpleDateFormat("yyyy-MM-dd HH:mm z")
        val fd = df.format(Date(from.commit.commitTime.toLong() * 1000))
        val td = df.format(Date(to.commit.commitTime.toLong() * 1000))
        val fc = "${from.commit.name} '${from.commit.shortMessage}'"
        val tc = "${to.commit.name} '${to.commit.shortMessage}'"
        val revState = if (isDeleted) "deleted in" else "last known as"
        val state = if (isDeleted) "deleted" else "alive"
        return "Line '$text' - '${from.file}:${from.line}' added in $fc $fd\n" +
            "  $revState '${to.file}:${to.line}' in $tc $td,\n" +
            "  age: $age s - $state"
    }
}

/**
 * Detects colleagues and their 'work vicinity' from commits.
 */
class Colleagues(private val serverRepo: Repo) {
    // A map of <colleague_email1, colleague_email2> pairs to pairs of
    // <month, time>, which indicates to a minimum time in ms between all line
    // changes for these two colleagues in a given month (yyyy-mm).
    private val map: HashMap<Pair<String, String>,
                             HashMap<String, Long>> = hashMapOf()

    fun collect(line: CodeLine) {
        // TODO(alex): ignore same user emails
        val authorEmail = line.authorEmail
        val editorEmail = line.editorEmail
        if (editorEmail == null || authorEmail == editorEmail) {
            return
        }
        val emails = Pair(authorEmail, editorEmail)

        val dates = map.getOrPut(emails, { hashMapOf() })
        val month = SimpleDateFormat("yyyy-MM").format(line.editDate)

        Logger.trace { "collected colleague, age: ${line.age}" }
        val vicinity = dates.getOrPut(month, { line.age })
        if (vicinity > line.age) {
            dates[month] = line.age
        }
    }

    fun calculateAndSendFacts(api: Api) {
        // Expose colleagues iff colleague1 edited colleague2 code and
        // colleague2 edited colleauge1 code.
        val auxHash = hashSetOf<Pair<String, String>>()
        for ((pair, dates) in map) {
            val email1 = pair.first
            val email2 = pair.second
            if (auxHash.contains(Pair(email2, email1))) {
                continue
            }

            val min1 = dates.minBy { (_, vicinity) -> vicinity }!!
            val dates2 = map[Pair(email2, email1)]
            if (dates2 != null) {
                auxHash.add(Pair(email1, email2))

                val min2 = dates2.minBy { (_, vicinity) -> vicinity }!!
                val min: Long =
                    if (min1.value < min2.value) { min1.value }
                    else { min2.value }

                val stats = mutableListOf<Fact>()
                stats.add(Fact(serverRepo,
                               FactCodes.COLLEAGUES,
                               value = email1,
                               value2 = email2,
                               value3 = min.toString()))

                api.postFacts(stats).onErrorThrow()
            }
        }
    }

    /**
     * Return colleagues in a form of <email, month, time> for the given
     * email, where time indicates a minimal time in ms between all line edits
     * by these colleagues in a given month (yyyy-mm).
     */
    fun get(email: String) : List<Triple<String, String, Long>> {
        return map
        .filter { (pair, _) -> pair.first == email || pair.second == email }
        .flatMap { (pair, dates) ->
            val colleagueEmail =
                if (email == pair.first) pair.second else pair.first

            val list = mutableListOf<Triple<String, String, Long>>()
            dates.forEach { month, vicinity ->
                list.add(Triple(colleagueEmail, month, vicinity))
            }
            return list
        }
    }
}

/**
 * A data class used to store line age information.
 */
class CodeLineAges : Serializable, Cloneable {
    /**
     * A pair of (line age sum, line count) representing an aggregated line
     * ages.
     */
    data class AggrAge(var sum: Long = 0L, var count: Int = 0) : Serializable

    /**
     * A code line info: an (age, email) pair.
     */
    data class LineInfo(var age: Long, var email: String) : Serializable

    /**
     * Aggregated code line ages for user emails, collected from all deleted
     * lines.
     */
    var aggrAges: HashMap<String, AggrAge> = hashMapOf()

    /**
     * A map of existing code lines ids to their ages at the revision.
     */
    var lastingLines: HashMap<String, LineInfo> = hashMapOf()

    public override fun clone(): CodeLineAges {
        val clone = CodeLineAges()
        aggrAges.forEach { (email, age) ->
            clone.aggrAges[email] = age.copy() }
        lastingLines.forEach { (email, line) ->
            clone.lastingLines[email] = line.copy() }
        return clone
    }
}

/**
 * Used to compute age of code lines in the repo.
 */
class CodeLongevity(
    private val serverRepo: Repo,
    private val emails: HashSet<String>,
    private val git: Git) {

    val repo: Repository = git.repository
    val revWalk = RevWalk(repo)
    val head: RevCommit =
        try { revWalk.parseCommit(CommitCrawler.getDefaultBranchHead(git)) }
        catch(e: Exception) { throw Exception("No branch") }

    val dataPath = FileHelper.getPath(serverRepo.rehash, "longevity")
    val colleagues = Colleagues(serverRepo)

    /**
     * Updates code line age statistics on the server.
     */
    private fun calculateAndSendFacts(ages: CodeLineAges, api: Api) {
        var repoTotal = 0
        var repoSum: Long = 0
        val aggrAges : HashMap<String, CodeLineAges.AggrAge> = hashMapOf()

        ages.aggrAges.forEach { (email, aggrAge) ->
            repoSum += aggrAge.sum
            repoTotal += aggrAge.count
            if (emails.contains(email)) {
                aggrAges[email] = aggrAge
            }
        }

        ages.lastingLines.forEach { (_, info) ->
            val aggrAge =
                aggrAges.getOrPut(info.email, { CodeLineAges.AggrAge() })
            aggrAge.sum += info.age
            aggrAge.count += 1

            repoSum += info.age
            repoTotal += 1
        }

        val secondsInDay = 86400
        val repoAvg = if (repoTotal > 0) { repoSum / repoTotal } else 0
        val stats = mutableListOf<Fact>()
        stats.add(Fact(repo = serverRepo,
                       code = FactCodes.LINE_LONGEVITY_REPO,
                       value = repoAvg.toString()))
        val repoAvgDays = repoAvg / secondsInDay
        Logger.info { "Repo average code line age is $repoAvgDays days, " +
            "lines total: $repoTotal" }

        for (email in emails) {
            val aggrAge = aggrAges[email] ?: CodeLineAges.AggrAge()
            val avg = if (aggrAge.count > 0) { aggrAge.sum / aggrAge.count }
                      else 0
            stats.add(Fact(repo = serverRepo,
                           code = FactCodes.LINE_LONGEVITY,
                           value = avg.toString(),
                           author = Author(email = email)))
        }

        if (stats.size > 0) {
            api.postFacts(stats).onErrorThrow()
            Logger.info { "Sent ${stats.size} facts to server" }
        }

        colleagues.calculateAndSendFacts(api)
    }

    /**
     * Scans the repo to extract code line ages.
     */
    fun updateFromObservable(diffObservable: Observable<JgitData> =
                                CommitCrawler.getJGitObservable(git),
                             onError: (Throwable) -> Unit = {},
                             api: Api,
                             onDataComplete: (CodeLineAges) -> Unit = {}) {
        var storedHead: RevCommit? = null
        var ageData = CodeLineAges()

        // Load existing age data if any. Expected format: commit id and
        // CodeLineAges structure following it.
        try {
            val file = dataPath.toFile()
            val iStream = ObjectInputStream(FileInputStream(file))
            val storedHeadId = iStream.readUTF()
            Logger.debug { "Stored repo head: $storedHeadId" }
            storedHead = revWalk.parseCommit(repo.resolve(storedHeadId))
            if (storedHead == head) {
                return  // TODO(anatoly): Send saved stats in such case.
            }
            ageData = (iStream.readObject() ?: CodeLineAges()) as CodeLineAges
        }
        catch(e: FileNotFoundException) { }
        catch(e: Exception) { Logger.error(e, "Failed to read longevity " +
            "data. CAUTION: data will be recomputed.") }

        // Update ages.
        getLinesObservable(storedHead, diffObservable, onError).subscribe({
            line ->
            Logger.trace { "Scanning: $line" }
            if (line.isDeleted) {
                if (ageData.lastingLines.contains(line.oldId)) {
                    line.age += ageData.lastingLines.remove(line.oldId)!!.age
                }
                val aggrAge = ageData.aggrAges.getOrPut(line.authorEmail,
                        { CodeLineAges.AggrAge() } )
                aggrAge.sum += line.age
                aggrAge.count += 1

                colleagues.collect(line)
            } else {
                var age = line.age
                if (ageData.lastingLines.contains(line.oldId)) {
                    age += ageData.lastingLines.remove(line.oldId)!!.age
                }
                ageData.lastingLines[line.newId] = CodeLineAges.LineInfo(age,
                        line.authorEmail)
            }
        }, onError, {
            // Store ages for subsequent runs.
            try {
                val file = dataPath.toFile()
                val oStream = ObjectOutputStream(FileOutputStream(file))
                oStream.writeUTF(head.name)
                oStream.writeObject(ageData)
            }
            catch(e: Exception) {
                Logger.error(e, "Failed to save longevity data. " +
                    "CAUTION: data will be recomputed on a next run.")
            }
            onDataComplete(ageData)
            calculateAndSendFacts(ageData, api)
        })
    }

    /**
     * Clears the stored age data if any.
     */
    fun dropSavedData() {
        dataPath.toFile().delete()
    }

    /**
     * Returns a list of code lines, both alive and deleted, between
     * the revisions of the repo.
     */
    fun getLinesList(tail : RevCommit? = null,
                     diffObservable: Observable<JgitData> =
                        CommitCrawler.getJGitObservable(git),
                     onError: (Throwable) -> Unit = {}) : List<CodeLine> {
        val codeLines: MutableList<CodeLine> = mutableListOf()
        getLinesObservable(tail, diffObservable, onError).blockingSubscribe {
            line -> codeLines.add(line)
        }
        return codeLines
    }

    /**
     * Returns an observable for for code lines, both alive and deleted, between
     * the revisions of the repo.
     */
    fun getLinesObservable(tail : RevCommit? = null,
                           diffObservable: Observable<JgitData>,
                           onError: (Throwable) -> Unit)
        : Observable<CodeLine> =
        Observable.create { subscriber ->

        val headWalk = TreeWalk(repo)
            headWalk.isRecursive = true
        headWalk.addTree(head.tree)

        val files: MutableMap<String, ArrayList<RevCommitLine>> = mutableMapOf()

        // Build a map of file names and their code lines.
        while (headWalk.next()) {
            try {
                val path = headWalk.pathString
                val fileId = headWalk.getObjectId(0)
                val fileLoader = repo.open(fileId)
                if (!RawText.isBinary(fileLoader.openStream())) {
                    val fileText = RawText(fileLoader.bytes)
                    val lines = ArrayList<RevCommitLine>(fileText.size())
                    for (idx in 0 until fileText.size()) {
                        lines.add(RevCommitLine(head, fileId, path, idx, false))
                    }
                    files[path] = lines
                }
            } catch (e: Exception) {
                // TODO(anatoly): better fix of exceptions.
            }
        }

        diffObservable
        .takeWhile { (commit, _) -> commit != tail }
        .subscribe( { (commit, diffs) ->
            // A step back in commits history. Update the files map according
            // to the diff. Traverse the diffs backwards to handle double
            // renames properly.
            // TODO(alex): cover file renames by tests (see APP-132 issue).
            for ((diff, editList) in diffs!!.asReversed()) {
                val oldPath = diff.oldPath
                val oldId = diff.oldId.toObjectId()
                val newPath = diff.newPath
                val newId = diff.newId.toObjectId()
                Logger.trace { "old: '$oldPath', new: '$newPath'" }

                // File was deleted, initialize the line array in the files map.
                if (diff.changeType == DiffEntry.ChangeType.DELETE) {
                    val fileLoader = repo.open(oldId)
                    val fileText = RawText(fileLoader.bytes)
                    files[oldPath] = ArrayList(fileText.size())
                }

                // If a file was deleted, then the new path is /dev/null.
                val path = if (newPath != DiffEntry.DEV_NULL) {
                    newPath
                } else {
                    oldPath
                }
                val lines = files[path]!!


                // Update the lines array according to diff insertions.
                // Traverse the edit list backwards to keep indices of
                // the edit list and the lines array in sync.
                for (edit in editList.asReversed()) {
                    // Insertion case: track the lines.
                    val insCount = edit.lengthB
                    if (insCount > 0) {
                        val insStart = edit.beginB
                        val insEnd = edit.endB
                        Logger.trace { "ins ($insStart, $insEnd)" }

                        for (idx in insStart until insEnd) {
                            val from = RevCommitLine(commit!!, newId,
                                                     newPath, idx, false)
                            try {
                                val to = lines[idx]
                                val cl = CodeLine(repo, from, to)
                                Logger.trace { "Collected: $cl" }
                                subscriber.onNext(cl)
                            }
                            catch(e: IndexOutOfBoundsException) {
                                Logger.error(e, "No line at $idx; commit: " +
                                    "${commit.name}; " +
                                    "'${commit.shortMessage}'")
                                throw e
                            }
                        }
                        lines.subList(insStart, insEnd).clear()
                    }
                }

                // Update the lines array according to diff deletions.
                for (edit in editList) {
                    // Deletion case. Chase down the deleted lines through the
                    // history.
                    val delCount = edit.lengthA
                    if (delCount > 0) {
                        val delStart = edit.beginA
                        val delEnd = edit.endA
                        Logger.trace { "del ($delStart, $delEnd)" }

                        val tmpLines = ArrayList<RevCommitLine>(delCount)
                        for (idx in delStart until delEnd) {
                            tmpLines.add(RevCommitLine(commit!!, oldId,
                                                       oldPath, idx, true))
                        }
                        lines.addAll(delStart, tmpLines)
                    }
                }

                // File was renamed, tweak the files map.
                if (diff.changeType == DiffEntry.ChangeType.RENAME) {
                    files[oldPath] = files.remove(newPath)!!
                }
            }
        }, onError, {
            // If a tail revision was given then the map has to contain
            // unclaimed code lines, i.e. the lines added before the tail
            // revision. Push them all into the result lines list, so the
            // caller can update their ages properly.
            if (tail != null) {
                val tailWalk = TreeWalk(repo)
                tailWalk.isRecursive = true
                tailWalk.addTree(tail.tree)

                while (tailWalk.next()) {
                    val filePath = tailWalk.pathString
                    val lines = files[filePath]
                    if (lines != null) {
                        val fileId = tailWalk.getObjectId(0)
                        for (idx in 0 until lines.size) {
                            val from = RevCommitLine(tail, fileId,
                                filePath, idx, false)
                            val cl = CodeLine(repo, from, lines[idx])
                            Logger.trace { "Collected (tail): $cl" }
                            subscriber.onNext(cl)
                        }
                    }
                }
            }
            subscriber.onComplete()
        })
    }
}
