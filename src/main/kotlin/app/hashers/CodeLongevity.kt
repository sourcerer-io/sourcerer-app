// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.hashers

import app.FactCodes
import app.Logger
import app.api.Api
import app.model.Author
import app.model.LocalRepo
import app.model.Repo
import app.model.Fact
import app.utils.RepoHelper
import io.reactivex.Observable
import org.eclipse.jgit.diff.DiffFormatter
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.diff.RawText
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.lib.AnyObjectId
import org.eclipse.jgit.lib.Repository
import org.eclipse.jgit.revwalk.RevCommit
import org.eclipse.jgit.revwalk.RevWalk
import org.eclipse.jgit.treewalk.TreeWalk
import org.eclipse.jgit.util.io.DisabledOutputStream

import java.text.SimpleDateFormat
import java.util.Date

/**
 * Represents a code line in a file revision.
 */
class RevCommitLine(val commit: RevCommit, val fileId: AnyObjectId,
                    val file: String, val line: Int,
                    val isDeleted: Boolean) {

    val id : String
        get() = "${fileId.getName()}:$line"
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
    val age : Long
        get() = (to.commit.commitTime - from.commit.commitTime).toLong()

    /**
     * The code line text.
     */
    val text : String
        get() = RawText(repo.open(from.fileId).getBytes()).getString(from.line)

    /**
     * Email address of the line's author.
     */
    val email : String
        get() = to.commit.authorIdent.emailAddress

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
        val fd = df.format(Date(from.commit.getCommitTime().toLong() * 1000))
        val td = df.format(Date(to.commit.getCommitTime().toLong() * 1000))
        val fc = "${from.commit.getName()} '${from.commit.getShortMessage()}'"
        val tc = "${to.commit.getName()} '${to.commit.getShortMessage()}'"
        val state = if (isDeleted) "deleted in" else "last known as"
        return "Line '$text' - '${from.file}:${from.line}' added in $fc $fd\n" +
            "  ${state} '${to.file}:${to.line}' in $tc $td"
    }
}

/**
 * Used to compute age of code lines in the repo.
 */
class CodeLongevity(private val localRepo: LocalRepo,
                    private val serverRepo: Repo,
                    private val api: Api,
                    git: Git) {
    val repo: Repository = git.repository
    val head: RevCommit =
        RevWalk(repo).parseCommit(repo.resolve(RepoHelper.MASTER_BRANCH))
    val df = DiffFormatter(DisabledOutputStream.INSTANCE)

    init {
        df.setRepository(repo)
        df.setDetectRenames(true)
    }

    fun update() {
        // TODO(anatoly): Add emails from server or hashAll.
        val emails = hashSetOf(localRepo.author.email)

        val sums: MutableMap<String, Long> = emails.associate { Pair(it, 0L) }
                                                   .toMutableMap()
        val totals: MutableMap<String, Int> = emails.associate { Pair(it, 0) }
                                                    .toMutableMap()

        var repoTotal = 0
        var repoSum: Long = 0
        getLinesObservable().blockingSubscribe { line ->
            repoTotal++
            repoSum += line.age

            val email = line.from.commit.authorIdent.emailAddress
            if (emails.contains(email)) {
                Logger.debug(line.toString())
                Logger.debug("Age: ${line.age} secs")

                sums[email] = sums[email]!! + line.age
                totals[email] = totals[email]!! + 1
            }
        }

        val secondsInDay = 86400
        val repoAvg = if (repoTotal > 0) { repoSum / repoTotal } else 0
        val stats = mutableListOf<Fact>()
        stats.add(Fact(repo = serverRepo,
                       code = FactCodes.LINE_LONGEVITY_REPO,
                       value = repoAvg.toDouble()))
        val repoAvgDays = repoAvg / secondsInDay
        Logger.info("Repo average code line age is $repoAvgDays days, "
              + "lines total: $repoTotal")

        for (email in emails) {
            val total = totals[email] ?: 0
            val avg = if (total > 0) { sums[email]!! / total } else 0
            stats.add(Fact(repo = serverRepo,
                           code = FactCodes.LINE_LONGEVITY,
                           value = avg.toDouble(),
                           author = Author(email = email)))
            if (email == localRepo.author.email) {
                val avgDays = avg / secondsInDay
                Logger.info("Your average code line age is $avgDays days, "
                      + "lines total: $total")
            }
        }

        if (stats.size > 0) {
            api.postFacts(stats)
            Logger.debug("Sent ${stats.size} stats to server")
        }
    }

    /**
     * Returns a list of code lines, both alive and deleted, between
     * the revisions of the repo.
     */
    fun getLinesList(tail : RevCommit? = null) : List<CodeLine> {
        val codeLines: MutableList<CodeLine> = mutableListOf()
        getLinesObservable(tail).blockingSubscribe { line ->
            codeLines.add(line)
        }
        return codeLines
    }

    /**
     * Returns an observable for for code lines, both alive and deleted, between
     * the revisions of the repo.
     */
    fun getLinesObservable(tail : RevCommit? = null) : Observable<CodeLine> =
        Observable.create { subscriber ->

        val headWalk = TreeWalk(repo)
        headWalk.setRecursive(true)
        headWalk.addTree(head.getTree())

        val files: MutableMap<String, ArrayList<RevCommitLine>> = mutableMapOf()

        // Build a map of file names and their code lines.
        while (headWalk.next()) {
            val path = headWalk.getPathString()
            val fileId = headWalk.getObjectId(0)
            val fileLoader = repo.open(fileId)
            if (!RawText.isBinary(fileLoader.openStream())) {
                val fileText = RawText(fileLoader.getBytes())
                val lines = ArrayList<RevCommitLine>(fileText.size())
                for (idx in 0 .. fileText.size() - 1) {
                    lines.add(RevCommitLine(head, fileId, path, idx, false))
                }
                files.put(path, lines)
            }
        }

        getDiffsObservable(tail).blockingSubscribe { (commit, diffs) ->
            // A step back in commits history. Update the files map according
            // to the diff.
            for (diff in diffs) {
                val oldPath = diff.getOldPath()
                val oldId = diff.getOldId().toObjectId()
                val newPath = diff.getNewPath()
                val newId = diff.getNewId().toObjectId()
                Logger.debug("old: '$oldPath', new: '$newPath'")

                // Skip binary files.
                val fileId = if (newPath != DiffEntry.DEV_NULL) newId else oldId
                if (RawText.isBinary(repo.open(fileId).openStream())) {
                    continue
                }

                // TODO(alex): does it happen in the wilds?
                if (diff.changeType == DiffEntry.ChangeType.COPY) {
                    continue
                }

                // File was deleted, initialize the line array in the files map.
                if (diff.changeType == DiffEntry.ChangeType.DELETE) {
                    val fileLoader = repo.open(oldId)
                    val fileText = RawText(fileLoader.getBytes())
                    files.put(oldPath, ArrayList(fileText.size()))
                }

                // If a file was deleted, then the new path is /dev/null.
                val path = if (newPath != DiffEntry.DEV_NULL) {
                    newPath
                } else {
                    oldPath
                }
                val lines = files.get(path)!!

                // Update the lines array according to diff insertions.
                // Traverse the edit list backwards to keep indices of
                // the edit list and the lines array in sync.
                val editList = df.toFileHeader(diff).toEditList()
                for (edit in editList.asReversed()) {
                    // Insertion case: track the lines.
                    val insCount = edit.getLengthB()
                    if (insCount > 0) {
                        val insStart = edit.getBeginB()
                        val insEnd = edit.getEndB()
                        Logger.debug("ins ($insStart, $insEnd)")

                        for (idx in insStart .. insEnd - 1) {
                            val from = RevCommitLine(commit, newId,
                                                     newPath, idx, false)
                            val to = lines.get(idx)
                            val cl = CodeLine(repo, from, to)
                            Logger.debug("Collected: ${cl}")
                            subscriber.onNext(cl)
                        }
                        lines.subList(insStart, insEnd).clear()
                    }
                }

                // Update the lines array according to diff deletions.
                for (edit in editList) {
                    // Deletion case. Chase down the deleted lines through the
                    // history.
                    val delCount = edit.getLengthA()
                    if (delCount > 0) {
                        val delStart = edit.getBeginA()
                        val delEnd = edit.getEndA()
                        Logger.debug("del ($delStart, $delEnd)")

                        val tmpLines = ArrayList<RevCommitLine>(delCount)
                        for (idx in delStart .. delEnd - 1) {
                            tmpLines.add(RevCommitLine(commit, oldId,
                                                       oldPath, idx, true))
                        }
                        lines.addAll(delStart, tmpLines)
                    }
                }

                // File was renamed, tweak the files map.
                if (diff.changeType == DiffEntry.ChangeType.RENAME) {
                    files.set(oldPath, files.remove(newPath)!!)
                }
            }
        }

        // If a tail revision was given then the map has to contain unclaimed
        // code lines, i.e. the lines added before the tail revision. Push
        // them all into the result lines list, so the caller can update their
        // ages properly.
        if (tail != null) {
            val tailWalk = TreeWalk(repo)
            tailWalk.setRecursive(true)
            tailWalk.addTree(tail.getTree())

            while (tailWalk.next()) {
                val filePath = tailWalk.getPathString()
                val lines = files.get(filePath)
                if (lines != null) {
                    val fileId = tailWalk.getObjectId(0)
                    for (idx in 0 .. lines.size - 1) {
                        val from = RevCommitLine(tail, fileId,
                                                 filePath, idx, false)
                        val cl = CodeLine(repo, from, lines[idx])
                        Logger.debug("Collected (tail): $cl")
                        subscriber.onNext(cl)
                    }
                }
            }
        }

        subscriber.onComplete()
    }

    /**
     * Iterates over the diffs between commits in the repo's history.
     */
    private fun getDiffsObservable(tail : RevCommit?) :
        Observable<Pair<RevCommit, List<DiffEntry>>> =
        Observable.create { subscriber ->

        val revWalk = RevWalk(repo)
        revWalk.markStart(head)

        var commit: RevCommit? = revWalk.next()  // Move the walker to the head.
        while (commit != null && commit != tail) {
            val parentCommit: RevCommit? = revWalk.next()

            Logger.debug("commit: ${commit.getName()}; " +
                "'${commit.getShortMessage()}'")
            if (parentCommit != null) {
                Logger.debug("parent commit: ${parentCommit.getName()}; "
                    + "'${parentCommit.getShortMessage()}'")
            }
            else {
                Logger.debug("parent commit: null")
            }

            subscriber.onNext(Pair(commit, df.scan(parentCommit, commit)))
            commit = parentCommit
        }

        subscriber.onComplete()
    }
}
