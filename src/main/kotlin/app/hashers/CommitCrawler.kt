// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.hashers

import app.Logger
import app.model.Author
import app.model.Commit
import app.model.DiffContent
import app.model.DiffFile
import app.model.DiffRange
import app.model.Repo
import app.utils.EmptyRepoException
import io.reactivex.Observable
import org.apache.commons.codec.digest.DigestUtils
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.diff.DiffFormatter
import org.eclipse.jgit.diff.EditList
import org.eclipse.jgit.diff.RawText
import org.eclipse.jgit.lib.ObjectId
import org.eclipse.jgit.lib.Repository
import org.eclipse.jgit.revwalk.RevCommit
import org.eclipse.jgit.revwalk.RevWalk
import org.eclipse.jgit.util.io.DisabledOutputStream
import java.util.LinkedList

data class JgitPair(val commit: RevCommit, val list: List<JgitDiff>)
data class JgitDiff(val diffEntry: DiffEntry, val editList: EditList)

/**
* Iterates over the diffs between commits in the repo's history.
*/
object CommitCrawler {
    private val REMOTE_HEAD = "refs/remotes/origin/HEAD"
    private val REMOTE_MASTER_BRANCH = "refs/remotes/origin/master"
    private val LOCAL_MASTER_BRANCH = "refs/heads/master"
    private val LOCAL_HEAD = "HEAD"
    private val REFS = listOf(REMOTE_HEAD, REMOTE_MASTER_BRANCH,
                              LOCAL_MASTER_BRANCH, LOCAL_HEAD)

    fun getDefaultBranchHead(git: Git): ObjectId {
        for (ref in REFS) {
            val branch = git.repository.resolve(ref) ?: continue

            Logger.debug { "Hashing from $ref" }
            return branch
        }
        throw EmptyRepoException("No remote default, master or HEAD found")
    }

    fun fetchRehashesAndAuthors(git: Git):
        Triple<LinkedList<String>, HashSet<Author>, HashMap<String, Int>> {
        val head: RevCommit = RevWalk(git.repository)
            .parseCommit(getDefaultBranchHead(git))

        val revWalk = RevWalk(git.repository)
        revWalk.markStart(head)

        val commitsRehashes = LinkedList<String>()
        val emails = hashSetOf<String>()
        val names = hashMapOf<String, String>()
        val commitsCount = hashMapOf<String, Int>()

        var commit: RevCommit? = revWalk.next()
        while (commit != null) {
            commitsRehashes.add(DigestUtils.sha256Hex(commit.name))
            val email = commit.authorIdent.emailAddress
            val name = commit.authorIdent.name
            if (!emails.contains(email)) {
                emails.add(email)
                names.put(email, name)
            } else {
                if (name.length > names[email]!!.length) {
                    names[email] = name
                }
            }
            commitsCount[email] = commitsCount.getOrDefault(email, 0) + 1

            commit.disposeBody()
            commit = revWalk.next()
        }
        revWalk.dispose()

        val authors = emails.map { email -> Author(names[email]!!, email) }
            .toHashSet()

        return Triple(commitsRehashes, authors, commitsCount)
    }

    fun getJGitObservable(git: Git,
                          totalCommitCount: Int = 0,
                          filteredEmails: HashSet<String>? = null,
                          tail : RevCommit? = null) : Observable<JgitPair> =
        Observable.create { subscriber ->

        val repo: Repository = git.repository
        val revWalk = RevWalk(repo)
        val head: RevCommit =
            try { revWalk.parseCommit(getDefaultBranchHead(git)) }
            catch(e: Exception) { throw Exception("No head was found!") }

        val df = DiffFormatter(DisabledOutputStream.INSTANCE)
        df.setRepository(repo)
        df.setDetectRenames(true)

        var commitCount = 0
        revWalk.markStart(head)
        var commit: RevCommit? = revWalk.next()  // Move the walker to the head.
        while (commit != null && commit != tail) {
            commitCount++
            val parentCommit: RevCommit? = revWalk.next()

            // Smart casts are not yet supported for a mutable variable captured
            // in an inline lambda, see
            // https://youtrack.jetbrains.com/issue/KT-7186.
            if (Logger.isDebug) {
                val commitName = commit.getName()
                val commitMsg = commit.getShortMessage()
                Logger.debug { "commit: $commitName; '$commitMsg'" }
                if (parentCommit != null) {
                    val parentCommitName = parentCommit.getName()
                    val parentCommitMsg = parentCommit.getShortMessage()
                    Logger.debug { "parent commit: $parentCommitName; " +
                        "'$parentCommitMsg'" }
                }
                else {
                    Logger.debug { "parent commit: null" }
                }
            }

            val perc = if (totalCommitCount != 0) {
                (commitCount.toDouble() / totalCommitCount) * 100
            } else 0.0
            Logger.printCommit(commit.shortMessage, commit.name, perc)

            val email = commit.authorIdent.emailAddress
            if (filteredEmails != null && !filteredEmails.contains(email)) {
                commit = parentCommit
                continue
            }

            val diffEntries = df.scan(parentCommit, commit)
            val diffEdits = diffEntries
            .filter { diff ->
                diff.changeType != DiffEntry.ChangeType.COPY
            }
            .filter { diff ->
                val fileId =
                    if (diff.getNewPath() != DiffEntry.DEV_NULL) {
                        diff.getNewId().toObjectId()
                    } else {
                        diff.getOldId().toObjectId()
                    }
                val stream = try { repo.open(fileId).openStream() }
                catch (e: Exception) { null }
                stream != null && !RawText.isBinary(stream)
            }
            .map { diff ->
                JgitDiff(diff, df.toFileHeader(diff).toEditList())
            }
            subscriber.onNext(JgitPair(commit, diffEdits))
            commit = parentCommit
        }

        subscriber.onComplete()
    }

    fun getObservable(git: Git,
                      repo: Repo): Observable<Commit> {
        return getObservable(git, getJGitObservable(git), repo)
    }

    fun getObservable(git: Git,
                      jgitObservable: Observable<JgitPair>,
                      repo: Repo): Observable<Commit> {
        return jgitObservable.map( { (jgitCommit, jgitDiffs) ->
            // Mapping and stats extraction.
            val commit = Commit(jgitCommit)
            commit.diffs = getDiffFiles(git.repository, jgitDiffs)

            // Count lines on all non-binary files. This is additional
            // statistics to CommitStats because not all file extensions
            // may be supported.
            commit.numLinesAdded = commit.diffs.fold(0) { total, file ->
                total + file.getAllAdded().size
            }
            commit.numLinesDeleted = commit.diffs.fold(0) { total, file ->
                total + file.getAllDeleted().size
            }
            commit.repo = repo

            commit
        })
    }

    private fun getDiffFiles(jgitRepo: Repository,
                             jgitDiffs: List<JgitDiff>) : List<DiffFile> {
        return jgitDiffs
            .map { (diff, edits) ->
                // TODO(anatoly): Can produce exception for large object.
                // Investigate for size.
                val new = try {
                    getContentByObjectId(jgitRepo, diff.newId.toObjectId())
                } catch (e: Exception) {
                    Logger.error(e)
                    null
                }
                val old = try {
                    getContentByObjectId(jgitRepo, diff.oldId.toObjectId())
                } catch (e: Exception) {
                    Logger.error(e)
                    null
                }

                val diffFiles = mutableListOf<DiffFile>()
                if (new != null && old != null) {
                    val path = when (diff.changeType) {
                        DiffEntry.ChangeType.DELETE -> diff.oldPath
                        else -> diff.newPath
                    }
                    diffFiles.add(DiffFile(path = path,
                        changeType = diff.changeType,
                        old = DiffContent(old, edits.map { edit ->
                            DiffRange(edit.beginA, edit.endA)
                        }),
                        new = DiffContent(new, edits.map { edit ->
                            DiffRange(edit.beginB, edit.endB)
                        })
                    ))
                }
                diffFiles
            }
            .flatten()
    }

    private fun getContentByObjectId(repo: Repository,
                                     objectId: ObjectId): List<String> {
        return try {
            val obj = repo.open(objectId)
            val rawText = RawText(obj.bytes)
            val content = ArrayList<String>(rawText.size())
            for (i in 0..(rawText.size() - 1)) {
                content.add(rawText.getString(i))
            }
            return content
        } catch (e: Exception) {
            listOf()
        }
    }
}
