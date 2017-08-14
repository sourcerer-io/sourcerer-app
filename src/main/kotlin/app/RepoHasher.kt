// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app

import app.extractors.Extractor
import app.model.Commit
import app.model.DiffContent
import app.model.LocalRepo
import app.model.Repo
import app.utils.RepoHelper
import io.reactivex.Observable
import io.reactivex.schedulers.Schedulers
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.lib.Repository
import org.eclipse.jgit.revwalk.RevWalk
import java.io.File
import java.io.IOException
import java.nio.charset.Charset
import org.eclipse.jgit.diff.DiffFormatter
import org.eclipse.jgit.lib.ObjectId
import org.eclipse.jgit.errors.MissingObjectException
import org.eclipse.jgit.util.io.DisabledOutputStream
import java.nio.file.Paths
import java.util.concurrent.TimeUnit

/**
 * RepoHasher hashes repository and uploads stats to server.
 */
class RepoHasher(val localRepo: LocalRepo) {
    private var repo: Repo = Repo()
    private val git: Git = loadGit() ?:
            throw IllegalStateException("Git failed to load")
    private val gitRepo: Repository = git.repository

    private fun loadGit(): Git? {
        return try {
            Git.open(File(localRepo.path))
        } catch (e: IOException) {
            Logger.error("Cannot access repository at path "
                    + "$localRepo.path", e)
            null
        }
    }

    private fun closeGit() {
        gitRepo.close()
        git.close()
    }

    private fun calculateRepoRehashes() {
        val initialCommit = getObservableCommits().blockingLast()
        repo.initialCommitRehash  = initialCommit.rehash
        repo.rehash = RepoHelper.calculateRepoRehash(initialCommit.rehash,
                                                     localRepo)
    }

    private fun isKnownRepo(): Boolean {
        return Configurator.getRepos()
            .find { it.rehash == repo.rehash } != null
    }

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
                val diffContents = getDiffContents(new, old)
                Logger.debug("Commit: ${new.raw?.name ?: ""}: "
                    + new.raw?.shortMessage)
                Logger.debug("Diff: ${diffContents.size} entries")
                new.stats = Extractor.extract(diffContents)
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

    fun getDiffContents(commitNew: Commit,
                        commitOld: Commit): List<DiffContent> {
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
                    val added = mutableListOf<String>()
                    val deleted = mutableListOf<String>()

                    val new = getContentByObjectId(diff.newId.toObjectId())
                    val old = getContentByObjectId(diff.oldId.toObjectId())

                    formatter.toFileHeader(diff).toEditList().forEach { edit ->
                        val addBegin = edit.beginB
                        val addEnd = edit.endB - 1
                        val delBegin = edit.beginA
                        val delEnd = edit.endA - 1
                        added.addAll(new.filterIndexed(
                            inRange(addBegin, addEnd)))
                        deleted.addAll(old.filterIndexed(
                            inRange(delBegin, delEnd)))
                    }

                    val path = when (diff.changeType) {
                        DiffEntry.ChangeType.DELETE -> diff.oldPath
                        else -> diff.newPath
                    }

                    DiffContent(Paths.get(path), added, deleted)
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

    private fun getRepoFromServer() {
        repo = SourcererApi.getRepo(repo.rehash)
    }

    private fun postRepoToServer() {
        SourcererApi.postRepo(repo)
    }

    private fun postCommitsToServer(commits: List<Commit>) {
        if (commits.isNotEmpty()) {
            Logger.debug("${commits.size} hashed commits sending")
            SourcererApi.postCommits(commits)
        }
    }

    private fun deleteCommitsOnServer(commits: List<Commit>) {
        if (commits.isNotEmpty()) {
            Logger.debug("${commits.size} deleted commits sending")
            SourcererApi.deleteCommits(commits)
        }
    }

    private fun getObservableCommits(): Observable<Commit> =
        Observable.create { subscriber ->
        try {
            val revWalk = RevWalk(gitRepo)
            val commitId = gitRepo.resolve(RepoHelper.MASTER_BRANCH)
            revWalk.markStart(revWalk.parseCommit(commitId))
            for (revCommit in revWalk) {
                Logger.debug("Commit produced: ${revCommit.name}")
                subscriber.onNext(Commit(revCommit))
            }
        } catch (e: Exception) {
            Logger.error("Commit producing error", e)
            subscriber.onError(e)
        }

        Logger.debug("Commit producing completed")
        subscriber.onComplete()
    }

    private val emailFilter: (Commit) -> Boolean = {
        val email = it.author.email
        localRepo.hashAllContributors || (email == localRepo.author.email ||
            repo.emails.contains(email))
    }

    private fun inRange(indexFrom: Int, indexTo: Int) = { index: Int, _: Any ->
        index >= indexFrom && index <= indexTo
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
        if (!RepoHelper.isValidRepo(localRepo.path)) {
            Logger.error("Invalid repo $localRepo")
            return
        }

        println("Hashing $localRepo...")
        localRepo.parseGitConfig(gitRepo.config)
        calculateRepoRehashes()

        if (isKnownRepo()) {
            getRepoFromServer()

            // Delete missing commits. If found at least one common commit
            // then next commits are not deleted because hash of a commit
            // calculated including hashes of its parents.
            val firstOverlapCommit = findFirstOverlappingCommit()
            val deletedCommits = repo.commits
                .takeWhile { it.rehash != firstOverlapCommit?.rehash }
            deleteCommitsOnServer(deletedCommits)
        }

        hashAndSendCommits()
        postRepoToServer()

        println("Hashing $localRepo successfully finished.")
        closeGit()
    }
}
