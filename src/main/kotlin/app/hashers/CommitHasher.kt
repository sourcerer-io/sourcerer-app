// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.hashers

import app.Logger
import app.api.Api
import app.extractors.Extractor
import app.model.Commit
import app.model.LocalRepo
import app.model.Repo
import io.reactivex.Observable
import java.util.concurrent.TimeUnit

/**
 * CommitHasher hashes repository and uploads stats to server.
 */
class CommitHasher(private val localRepo: LocalRepo,
                   private val serverRepo: Repo = Repo(),
                   private val api: Api,
                   private val rehashes: List<String>) {

    init {
        // Delete locally missing commits from server. If found at least one
        // common commit then preceding commits are not deleted because hash of
        // a commit calculated including hashes of its parents.
        val firstOverlapCommitRehash = findFirstOverlappingCommitRehash()
        val deletedCommits = serverRepo.commits
            .takeWhile { it.rehash != firstOverlapCommitRehash }
        deleteCommitsOnServer(deletedCommits)
    }

    private fun findFirstOverlappingCommitRehash(): String? {

        val serverHistoryRehashes = serverRepo.commits
                                              .map { commit -> commit.rehash }
                                              .toHashSet()
        return rehashes.firstOrNull { rehash ->
            serverHistoryRehashes.contains(rehash)
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

    private val emailFilter: (Commit) -> Boolean = {
        val email = it.author.email
        localRepo.hashAllContributors || (email == localRepo.author.email ||
            serverRepo.emails.contains(email))
    }

    // Hash added and missing server commits and send them to server.
    fun updateFromObservable(observable: Observable<Commit>) {
        val lastKnownCommit = serverRepo.commits.lastOrNull()
        val knownCommits = serverRepo.commits.toHashSet()

        val throwables = mutableListOf<Throwable>()

        observable
            .takeWhile { new ->  // Hash until last known commit.
                new.rehash != lastKnownCommit?.rehash
            }
            .filter { commit ->  // Don't hash known.
                knownCommits.isEmpty() || !knownCommits.contains(commit)
            }
            .filter { commit -> emailFilter(commit) }  // Email filtering.
            .map { commit ->
                // Mapping and stats extraction.
                commit.stats = Extractor().extract(commit.diffs)
                Logger.debug("Stats: ${commit.stats.size} entries")

                // Count lines on all non-binary files. This is additional
                // statistics to CommitStats because not all file extensions
                // may be supported.
                commit.numLinesAdded = commit.diffs.fold(0) { total, file ->
                    total + file.getAllAdded().size
                }
                commit.numLinesDeleted = commit.diffs.fold(0) { total, file ->
                    total + file.getAllDeleted().size
                }
                commit
            }
            .buffer(20, TimeUnit.SECONDS)  // Group ready commits by time.
            .subscribe({ commitsBundle ->  // OnNext.
                postCommitsToServer(commitsBundle)  // Send ready commits.
            }, { e ->  // OnError.
                Logger.error("Hashing error: " + e.message)
                throwables.add(e)  // TODO(anatoly): Top-class handling errors.
            })
    }
}
