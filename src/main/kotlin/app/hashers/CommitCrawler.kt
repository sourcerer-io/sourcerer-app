// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.hashers

import app.Logger
import app.model.Commit
import app.model.DiffContent
import app.model.DiffFile
import app.model.DiffRange
import app.model.Repo
import app.utils.RepoHelper
import io.reactivex.Observable
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.diff.DiffFormatter
import org.eclipse.jgit.diff.RawText
import org.eclipse.jgit.errors.MissingObjectException
import org.eclipse.jgit.lib.ObjectId
import org.eclipse.jgit.revwalk.RevCommit
import org.eclipse.jgit.revwalk.RevWalk
import org.eclipse.jgit.util.io.DisabledOutputStream

object CommitCrawler {
    fun getObservable(git: Git, repo: Repo,
                      numCommits: Int = 0): Observable<Commit> {
        var curNumCommits = 0
        return Observable
            .create<Commit> { subscriber ->
                try {
                    val revWalk = RevWalk(git.repository)
                    val commitId = git.repository.resolve(RepoHelper.MASTER_BRANCH)
                    revWalk.markStart(revWalk.parseCommit(commitId))
                    for (revCommit in revWalk) {
                        subscriber.onNext(Commit(revCommit))
                    }
                    // Commits are combined in pairs, an empty commit concatenated
                    // to calculate the diff of the initial commit.
                    subscriber.onNext(Commit())
                } catch (e: Exception) {
                    Logger.error(e, "Commit producing error")
                    subscriber.onError(e)
                }
                subscriber.onComplete()
            }  // TODO(anatoly): Rewrite diff calculation in non-weird way.
            .pairWithNext()  // Pair commits to get diff.
            .map { (new, old) ->
                curNumCommits++
                // Mapping and stats extraction.
                val message = new.raw?.shortMessage ?: ""
                val hash = new.raw?.name ?: ""
                val perc = if (numCommits != 0) {
                    (curNumCommits.toDouble() / numCommits) * 100
                } else 0.0
                Logger.printCommit(message, hash, perc)
                new.diffs = getDiffFiles(git, new, old)
                Logger.debug { "Diff: ${new.diffs.size} entries" }
                // Count lines on all non-binary files. This is additional
                // statistics to CommitStats because not all file extensions
                // may be supported.
                new.numLinesAdded = new.diffs.fold(0) { total, file ->
                    total + file.getAllAdded().size
                }
                new.numLinesDeleted = new.diffs.fold(0) { total, file ->
                    total + file.getAllDeleted().size
                }
                new.repo = repo
                new
            }
    }

    private fun getDiffFiles(git: Git,
                             commitNew: Commit,
                             commitOld: Commit): List<DiffFile> {
        val revCommitNew: RevCommit? = commitNew.raw
        val revCommitOld: RevCommit? = commitOld.raw

        return DiffFormatter(DisabledOutputStream.INSTANCE).use { formatter ->
            formatter.setRepository(git.repository)
            formatter.setDetectRenames(true)
            formatter.scan(revCommitOld?.tree, revCommitNew?.tree)
                // Skip binary files.
                .filter {
                    val id = if (it.changeType == DiffEntry.ChangeType.DELETE) {
                        it.oldId.toObjectId()
                    } else {
                        it.newId.toObjectId()
                    }
                    val stream = try {
                        git.repository.open(id).openStream()
                    } catch (e: Exception) { null }
                    stream != null && !RawText.isBinary(stream)
                }
                .map { diff ->
                    // TODO(anatoly): Can produce exception for large object.
                    // Investigate for size.
                    val new = try {
                        getContentByObjectId(git, diff.newId.toObjectId())
                    } catch (e: Exception) {
                        Logger.error(e)
                        null
                    }
                    val old = try {
                        getContentByObjectId(git, diff.oldId.toObjectId())
                    } catch (e: Exception) {
                        Logger.error(e)
                        null
                    }

                    val diffFiles = mutableListOf<DiffFile>()
                    if (new != null && old != null) {
                        val header = try {
                            formatter.toFileHeader(diff)
                        } catch (e: Exception) {
                            Logger.error(e)
                            null
                        }

                        if (header != null) {
                            val edits = header.toEditList()
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
                                })))
                        }
                    }

                    diffFiles
                }
                .flatten()
        }
    }

    private fun getContentByObjectId(git: Git,
                                     objectId: ObjectId): List<String> {
        return try {
            val obj = git.repository.open(objectId)
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

    private fun <T> Observable<T>.pairWithNext(): Observable<Pair<T, T>> {
        return this.map { emit -> Pair(emit, emit) }
            // Accumulate emits by prev-next pair.
            .scan { pairAccumulated, pairNext ->
                Pair(pairAccumulated.second, pairNext.second)
            }
            .skip(1)  // Skip initial not paired emit.
    }
}
