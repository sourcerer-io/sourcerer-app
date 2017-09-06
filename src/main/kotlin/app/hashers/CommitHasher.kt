// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.hashers

import app.Logger
import app.api.Api
import app.config.Configurator
import app.extractors.Extractor
import app.model.Commit
import app.model.DiffEdit
import app.model.DiffFile
import app.model.LocalRepo
import app.model.Repo
import app.utils.RepoHelper
import io.reactivex.Observable
import io.reactivex.schedulers.Schedulers
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.lib.Repository
import org.eclipse.jgit.revwalk.RevWalk
import java.nio.charset.Charset
import org.eclipse.jgit.diff.DiffFormatter
import org.eclipse.jgit.lib.ObjectId
import org.eclipse.jgit.errors.MissingObjectException
import org.eclipse.jgit.util.io.DisabledOutputStream
import java.util.concurrent.TimeUnit

/**
 * CommitHasher hashes repository and uploads stats to server.
 */
class CommitHasher(private val localRepo: LocalRepo,
                   private val repo: Repo = Repo(),
                   private val api: Api,
                   private val configurator: Configurator,
                   private val git: Git) {
    private val gitRepo: Repository = git.repository

    private fun findFirstOverlappingCommit(): Commit? {
        val serverHistoryCommits = repo.commits.toHashSet()
        return getObservableCommits()
            .skipWhile { commit -> !serverHistoryCommits.contains(commit) }
            .blockingFirst(null)
    }

    private fun hashAndSendCommits() {
        val lastKnownCommit = repo.commits.lastOrNull()
        val knownCommits = repo.commits.toHashSet()
        getObservableCommits()
            .pairWithNext()  // Pair commits to get diff.
            .takeWhile { (new, _) ->  // Hash until last known commit.
                new.rehash != lastKnownCommit?.rehash }
            .filter { (new, _) -> knownCommits.isEmpty()  // Don't hash known.
                || !knownCommits.contains(new) }
            .filter { (new, _) -> emailFilter(new) }  // Email filtering.
            .map { (new, old) ->  // Mapping and stats extraction.
                new.repo = repo
                val diffFiles = getDiffFiles(new, old)
                Logger.debug("Commit: ${new.raw?.name ?: ""}: "
                    + new.raw?.shortMessage)
                Logger.debug("Diff: ${diffFiles.size} entries")
                new.stats = Extractor().extract(diffFiles)
                Logger.debug("Stats: ${new.stats.size} entries")
                new
            }
            .observeOn(Schedulers.io())  // Different thread for data sending.
            .buffer(20, TimeUnit.SECONDS)  // Group ready commits by time.
            .doOnNext { commitsBundle ->  // Send ready commits.
                postCommitsToServer(commitsBundle) }
            .blockingSubscribe({
                // OnNext
            }, { t ->  // OnError
                Logger.error("Error while hashing: $t")
            })
    }

    private fun getDiffFiles(commitNew: Commit,
                             commitOld: Commit): List<DiffFile> {
        // TODO(anatoly): Binary files.
        val revCommitNew = commitNew.raw
        val revCommitOld = commitOld.raw
        if (revCommitNew == null || revCommitOld == null) {
            return listOf()
        }

        return DiffFormatter(DisabledOutputStream.INSTANCE).use { formatter ->
            formatter.setRepository(gitRepo)
            formatter.scan(revCommitOld.tree, revCommitNew.tree)
                // RENAME change type doesn't change file content.
                .filter { it.changeType != DiffEntry.ChangeType.RENAME }
                .map { diff ->
                    val new = getContentByObjectId(diff.newId.toObjectId())
                    val old = getContentByObjectId(diff.oldId.toObjectId())

                    val edits = formatter.toFileHeader(diff).toEditList()

                    val path = when (diff.changeType) {
                        DiffEntry.ChangeType.DELETE -> diff.oldPath
                        else -> diff.newPath
                    }

                    DiffFile(path = path,
                             contentOld = old,
                             contentNew = new,
                             edits = edits.map { DiffEdit(it) })
                }
        }
    }

    private fun getContentByObjectId(objectId: ObjectId): List<String> {
       return try {
           gitRepo.open(objectId).bytes.toString(Charset.defaultCharset())
                   .split('\n')
       } catch (e: MissingObjectException) {
           listOf<String>()
       }
    }

    private fun postCommitsToServer(commits: List<Commit>) {
        if (commits.isNotEmpty()) {
            api.postCommits(commits)
            Logger.debug("Sent ${commits.size} added commits to server")
        }
    }

    private fun deleteCommitsOnServer(commits: List<Commit>) {
        if (commits.isNotEmpty()) {
            api.deleteCommits(commits)
            Logger.debug("Sent ${commits.size} deleted commits to server")
        }
    }

    private fun getObservableCommits(): Observable<Commit> =
        Observable.create { subscriber ->
        try {
            val revWalk = RevWalk(gitRepo)
            val commitId = gitRepo.resolve(RepoHelper.MASTER_BRANCH)
            revWalk.markStart(revWalk.parseCommit(commitId))
            for (revCommit in revWalk) {
                subscriber.onNext(Commit(revCommit))
            }
        } catch (e: Exception) {
            Logger.error("Commit producing error", e)
            subscriber.onError(e)
        }
        subscriber.onComplete()
    }

    private val emailFilter: (Commit) -> Boolean = {
        val email = it.author.email
        localRepo.hashAllContributors || (email == localRepo.author.email ||
            repo.emails.contains(email))
    }

    fun <T> Observable<T>.pairWithNext(): Observable<Pair<T, T>> {
        return this.map { emit -> Pair(emit, emit) }
            // Accumulate emits by prev-next pair.
            .scan { pairAccumulated, pairNext ->
                Pair(pairAccumulated.second, pairNext.second)
            }
            .skip(1)  // Skip initial not paired emit.
    }

    fun update() {
        // Delete locally missing commits from server. If found at least one
        // common commit then next commits are not deleted because hash of a
        // commit calculated including hashes of its parents.
        val firstOverlapCommit = findFirstOverlappingCommit()
        val deletedCommits = repo.commits
            .takeWhile { it.rehash != firstOverlapCommit?.rehash }
        deleteCommitsOnServer(deletedCommits)

        // Hash added and missing server commits and send them to server.
        hashAndSendCommits()
    }
}
