// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.hashers

import app.Logger
import app.api.Api
import app.config.Configurator
import app.model.Author
import app.model.LocalRepo
import app.model.Repo
import app.model.Fact
import app.utils.RepoHelper
import org.eclipse.jgit.diff.DiffFormatter
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.diff.RawText
import org.eclipse.jgit.api.Git
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
class RevCommitLine(val commit: RevCommit, val file: String, val line: Int)

/**
 * Represents a code line in repo's history.
 *
 * TODO(Alex): the text arg is solely for testing proposes (remove it)
 */
class CodeLine(val from: RevCommitLine, val to: RevCommitLine,
               val text: String) {

    // TODO(alex): oldId and newId may be computed as a hash built from commit,
    // file name and line number, if we are going to send the data outside a
    // local machine.

    /**
     * Id of the code line in a revision when the line was added. Used to
     * identify a line and update its lifetime computed at the previous
     * iteration.
     */
    val oldId: String = ""

    /**
     * Id of the code line in a revision, where the line was deleted, or a head
     * revision, if the line is alive.
     */
    val newId: String = ""

    /**
     * The code line's age in seconds.
     */
    val age = to.commit.getCommitTime() - from.commit.getCommitTime()

    /**
     * A pretty print of a code line; debugging.
     */
    override fun toString() : String {
        val df = SimpleDateFormat("yyyy-MM-dd HH:mm z")
        val fd = df.format(Date(from.commit.getCommitTime().toLong() * 1000))
        val td = df.format(Date(to.commit.getCommitTime().toLong() * 1000))
        val fc = "${from.commit.getName()} '${from.commit.getShortMessage()}'"
        val tc = "${to.commit.getName()} '${to.commit.getShortMessage()}'"
        return "Line '$text' - '${from.file}:${from.line}' added in $fc $fd\n" +
            "  last known as '${to.file}:${to.line}' in $tc $td"
    }
}

/**
 * Used to compute age of code lines in the repo.
 */
class CodeLongevity(private val localRepo: LocalRepo,
                    private val serverRepo: Repo,
                    private val api: Api,
                    private val git: Git, tailRev: String = "") {
    val CODE_LONGEVITY_KEY = "line-longevity-avg"
    val CODE_LONGEVITY_REPO_KEY = "line-longevity-repo-avg"

    val repo: Repository = git.repository
    val head: RevCommit =
        RevWalk(repo).parseCommit(repo.resolve(RepoHelper.MASTER_BRANCH))
    val tail: RevCommit? =
        if (tailRev != "") RevWalk(repo).parseCommit(repo.resolve(tailRev))
        else null

    fun update() {
        val codeLines = compute()

        // TODO(anatoly): Add emails from server or hashAll.
        val emails = hashSetOf(localRepo.author.email)

        val sums: MutableMap<String, Long> = emails.associate { Pair(it, 0L) }
                                                   .toMutableMap()
        val totals: MutableMap<String, Int> = emails.associate { Pair(it, 0) }
                                                    .toMutableMap()

        val repoTotal: Int = codeLines.size
        var repoSum: Long = 0
        for (line in codeLines) {
            repoSum += line.age

            val email = line.from.commit.authorIdent.emailAddress
            if (!emails.contains(email)) {
                continue
            }
            Logger.debug(line.toString())
            Logger.debug("Age: ${line.age} secs")

            sums[email] = sums[email]!! + line.age
            totals[email] = totals[email]!! + 1
        }

        val secondsInDay = 86400
        val repoAvg = if (repoTotal > 0) { repoSum / repoTotal } else 0
        val stats = mutableListOf<Fact>()
        stats.add(Fact(repo = serverRepo,
                       key = CODE_LONGEVITY_REPO_KEY,
                       value = repoAvg.toDouble()))
        val repoAvgDays = repoAvg / secondsInDay
        Logger.info("Repo average code line age is $repoAvgDays days, "
              + "lines total: $repoTotal")

        for (email in emails) {
            val total = totals[email] ?: 0
            val avg = if (total > 0) { sums[email]!! / total } else 0
            stats.add(Fact(repo = serverRepo,
                           key = CODE_LONGEVITY_KEY,
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
     * Scans through the repo for alive and deleted code lines and returns
     * a list of all code lines, both alive and deleted, between the given
     * revisions.
     */
    fun compute() : List<CodeLine> {
        val codeLines: MutableList<CodeLine> = mutableListOf()

        val treeWalk = TreeWalk(repo)
        treeWalk.setRecursive(true)
        treeWalk.addTree(head.getTree())

        val files: MutableMap<String, ArrayList<RevCommitLine>> = mutableMapOf()

        // Build a map of file names and their code lines.
        while (treeWalk.next()) {
            val path = treeWalk.getPathString()
            val fileLoader = repo.open(treeWalk.getObjectId(0))
            if (!RawText.isBinary(fileLoader.openStream())) {
                val fileText = RawText(fileLoader.getBytes())
                var lines = ArrayList<RevCommitLine>(fileText.size())
                for (idx in 0 .. fileText.size() - 1) {
                    lines.add(RevCommitLine(head, path, idx))
                }
                files.put(path, lines)
            }
        }
  
        val df = DiffFormatter(DisabledOutputStream.INSTANCE)
        df.setRepository(repo)
        df.setDetectRenames(true)

        val revWalk = RevWalk(repo)
        revWalk.markStart(head)

        var commit: RevCommit? = revWalk.next()  // move the walker to the head
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

            // A step back in commits history. Update the files map according
            // to the diff.
            val diffs = df.scan(parentCommit, commit)
            for (diff in diffs) {
                val oldPath = diff.getOldPath()
                val oldId = diff.getOldId().toObjectId()
                val newPath = diff.getNewPath()
                val newId = diff.getNewId().toObjectId()
                Logger.debug("old: '$oldPath', new: '$newPath'")

                // Skip binary files.
                var fileId = if (newPath != DiffEntry.DEV_NULL) newId else oldId
                if (RawText.isBinary(repo.open(fileId).openStream())) {
                    continue
                }

                // TODO(alex): does it happen in the wilds?
                if (diff.changeType == DiffEntry.ChangeType.COPY) {
                    continue
                }

                // File was deleted, put its lines into the files map.
                if (diff.changeType == DiffEntry.ChangeType.DELETE) {
                    val fileLoader = repo.open(oldId)
                    val fileText = RawText(fileLoader.getBytes())
                    var lines = ArrayList<RevCommitLine>(fileText.size())
                    for (idx in 0 .. fileText.size() - 1) {
                        lines.add(RevCommitLine(commit, oldPath, idx))
                    }
                    files.put(oldPath, lines)
                }

                // If a file was deleted, then the new path is /dev/null.
                val path = if (newPath != DiffEntry.DEV_NULL) {
                    newPath
                } else {
                    oldPath
                }
                val lines = files.get(path)!!

                // Update the lines array to match the diff's edit list changes.
                // Traverse the edit list backwards to keep indices of the edit
                // list and the lines array in sync.
                val editList = df.toFileHeader(diff).toEditList().asReversed()
                for (edit in editList) {
                    val delStart = edit.getBeginA()
                    val delEnd = edit.getEndA()
                    val delCount = edit.getLengthA()
                    var insStart = edit.getBeginB()
                    var insEnd = edit.getEndB()
                    val insCount = edit.getLengthB()
                    Logger.debug("del ($delStart, $delEnd), "
                        + "ins ($insStart, $insEnd)")

                    // Deletion case. Chase down the deleted lines through the
                    // history.
                    if (delCount > 0) {
                        var tmpLines = ArrayList<RevCommitLine>(delCount)
                        for (idx in delStart .. delEnd - 1) {
                            tmpLines.add(RevCommitLine(commit, oldPath, idx))
                        }
                        
                        // TODO(alex): Approve code change.
                        // delStart index caused IndexOutOfBoundException.
                        lines.addAll(tmpLines)
                    }

                    // Insertion case. Track it.
                    if (insCount > 0) {
                        val fileLoader = repo.open(newId)
                        val fileText = RawText(fileLoader.getBytes())

                        for (idx in insStart .. insEnd - 1) {
                            val from = RevCommitLine(commit, newPath, idx)
                            var to = lines.get(idx)
                            val cl = CodeLine(from, to, fileText.getString(idx))
                            codeLines.add(cl)
                            Logger.debug("Collected: ${cl.toString()}")
                        }
                        lines.subList(insStart, insEnd).clear()
                    }
                }

                // File was renamed, tweak the files map.
                if (diff.changeType == DiffEntry.ChangeType.RENAME) {
                    files.set(oldPath, files.remove(newPath)!!)
                }
            }
            commit = parentCommit
        }

        // If a tail revision was given then the map has to contain unclaimed
        // code lines, i.e. the lines added before the tail revision. Push
        // them all into the result lines list, so the caller can update their
        // ages properly.
        if (tail != null) {
            for ((file, lines) in files) {
                for (idx in 0 .. lines.size - 1) {
                    val from = RevCommitLine(tail, file, idx)
                    val cl = CodeLine(from, lines[idx],
                        "no data (too lazy to compute)")
                    codeLines.add(cl)
                }
            }
        }

        return codeLines
    }
}
