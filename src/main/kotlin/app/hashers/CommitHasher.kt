// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.hashers

import app.FactKey
import app.Logger
import app.api.Api
import app.extractors.Extractor
import app.model.Author
import app.model.Commit
import app.model.DiffContent
import app.model.DiffFile
import app.model.DiffRange
import app.model.Fact
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
import org.eclipse.jgit.diff.RawText
import org.eclipse.jgit.lib.ObjectId
import org.eclipse.jgit.errors.MissingObjectException
import org.eclipse.jgit.revwalk.RevCommit
import org.eclipse.jgit.util.io.DisabledOutputStream
import java.time.LocalDateTime
import java.time.ZoneOffset
import java.util.concurrent.TimeUnit

/**
 * CommitHasher hashes repository and uploads stats to server.
 */
class CommitHasher(private val localRepo: LocalRepo,
                   private val repo: Repo = Repo(),
                   private val api: Api,
                   private val git: Git) {

    private val gitRepo: Repository = git.repository

    private fun findFirstOverlappingCommit(): Commit? {
        val serverHistoryCommits = repo.commits.toHashSet()
        return getCommitsAsObservable()
            .skipWhile { commit -> !serverHistoryCommits.contains(commit) }
            .blockingFirst(null)
    }

    private fun hashAndSendCommits() {
        val lastKnownCommit = repo.commits.lastOrNull()
        val knownCommits = repo.commits.toHashSet()

        val factsDayWeek = hashMapOf<Author, Array<Int>>()
        val factsDayTime = hashMapOf<Author, Array<Int>>()

        // Commits are combined in pairs, an empty commit concatenated to
        // calculate the diff of the initial commit.
        Observable.concat(getCommitsAsObservable()
            .doOnNext { commit ->
                Logger.debug("Commit: ${commit.raw?.name ?: ""}: "
                    + commit.raw?.shortMessage)
                commit.repo = repo

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
            }, Observable.just(Commit()))
            .pairWithNext()  // Pair commits to get diff.
            .takeWhile { (new, _) ->  // Hash until last known commit.
                new.rehash != lastKnownCommit?.rehash }
            .filter { (new, _) -> knownCommits.isEmpty()  // Don't hash known.
                || !knownCommits.contains(new) }
            .filter { (new, _) -> emailFilter(new) }  // Email filtering.
            .map { (new, old) ->  // Mapping and stats extraction.
                val diffFiles = getDiffFiles(new, old)
                Logger.debug("Diff: ${diffFiles.size} entries")
                new.stats = Extractor().extract(diffFiles)
                Logger.debug("Stats: ${new.stats.size} entries")

                // Count lines on all non-binary files. This is additional
                // statistics to CommitStats because not all file extensions
                // may be supported.
                new.numLinesAdded = diffFiles.fold(0) { total, file ->
                    total + file.getAllAdded().size }
                new.numLinesDeleted = diffFiles.fold(0) { total, file ->
                    total + file.getAllDeleted().size }
                new
            }
            .observeOn(Schedulers.io())  // Different thread for data sending.
            .buffer(20, TimeUnit.SECONDS)  // Group ready commits by time.
            .blockingSubscribe({ commitsBundle ->  // OnNext.
                postCommitsToServer(commitsBundle)  // Send ready commits.
            }, { e ->  // OnError.
                Logger.error("Error while hashing: $e")
            }, {  // OnComplete.
                val facts = mutableListOf<Fact>()
                factsDayTime.map { (author, list) ->
                    list.forEachIndexed { hour, count ->
                        if (count > 0) {
                            facts.add(Fact(repo, FactKey.COMMITS_DAY_TIME +
                                hour, count.toDouble(), author))
                        }
                    }
                }
                factsDayWeek.map { (author, list) ->
                    list.forEachIndexed { day, count ->
                        if (count > 0) {
                            facts.add(Fact(repo, FactKey.COMMITS_DAY_WEEK +
                                day, count.toDouble(), author))
                        }
                    }
                }
                postFactsToServer(facts)
            })
    }

    private fun getDiffFiles(commitNew: Commit,
                             commitOld: Commit): List<DiffFile> {
        val revCommitNew:RevCommit? = commitNew.raw
        val revCommitOld:RevCommit? = commitOld.raw

        return DiffFormatter(DisabledOutputStream.INSTANCE).use { formatter ->
            formatter.setRepository(gitRepo)
            formatter.setDetectRenames(true)
            formatter.scan(revCommitOld?.tree, revCommitNew?.tree)
                // RENAME change type doesn't change file content.
                .filter { it.changeType != DiffEntry.ChangeType.RENAME }
                // Skip binary files.
                .filter {
                    val id = if (it.changeType == DiffEntry.ChangeType.DELETE) {
                        it.oldId.toObjectId()
                    } else {
                        it.newId.toObjectId()
                    }
                    !RawText.isBinary(gitRepo.open(id).openStream())
                }
                .map { diff ->
                    val new = getContentByObjectId(diff.newId.toObjectId())
                    val old = getContentByObjectId(diff.oldId.toObjectId())

                    val edits = formatter.toFileHeader(diff).toEditList()
                    val path = when (diff.changeType) {
                        DiffEntry.ChangeType.DELETE -> diff.oldPath
                        else -> diff.newPath
                    }
                    DiffFile(path = path,
                             old = DiffContent(old, edits.map { edit ->
                                 DiffRange(edit.beginA, edit.endA) }),
                             new = DiffContent(new, edits.map { edit ->
                                 DiffRange(edit.beginB, edit.endB) }))
                }
        }
    }

    private fun getContentByObjectId(objectId: ObjectId): List<String> {
       return try {
           gitRepo.open(objectId).bytes.toString(Charset.defaultCharset())
                   .split('\n')
       } catch (e: MissingObjectException) {
           listOf()
       }
    }

    private fun postCommitsToServer(commits: List<Commit>) {
        if (commits.isNotEmpty()) {
            api.postCommits(commits)
            Logger.debug("Sent ${commits.size} added commits to server")
        }
    }

    private fun postFactsToServer(facts: List<Fact>) {
        if (facts.isNotEmpty()) {
            api.postFacts(facts)
            Logger.debug("Sent ${facts.size} facts to server")
        }
    }

    private fun deleteCommitsOnServer(commits: List<Commit>) {
        if (commits.isNotEmpty()) {
            api.deleteCommits(commits)
            Logger.debug("Sent ${commits.size} deleted commits to server")
        }
    }

    private fun getCommitsAsObservable(): Observable<Commit> =
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

    private fun <T> Observable<T>.pairWithNext(): Observable<Pair<T, T>> {
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
