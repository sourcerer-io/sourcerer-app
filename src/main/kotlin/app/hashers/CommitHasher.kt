// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.hashers

import app.Logger
import app.api.Api
import app.extractors.Extractor
import app.model.Commit
import app.model.Repo
import io.reactivex.Observable
import java.util.concurrent.TimeUnit

/**
 * CommitHasher hashes repository and uploads stats to server.
 */
class CommitHasher(private val serverRepo: Repo = Repo(),
                   private val api: Api,
                   private val rehashes: List<String>,
                   private val emails: HashSet<String>) {

    init {
        // Delete locally missing commits from server. If found at least one
        // common commit then preceding commits are not deleted because hash of
        // a commit calculated including hashes of its parents.
        val firstOverlapCommitRehash = findFirstOverlappingCommitRehash()
        val deletedCommits = serverRepo.commits
            .takeWhile { it.rehash != firstOverlapCommitRehash }
        deleteCommitsOnServer(deletedCommits)
    }

    // Hash added and missing server commits and send them to server.
    fun updateFromObservable(observable: Observable<Commit>,
                             onError: (Throwable) -> Unit) {
        val lastKnownCommit = serverRepo.commits.lastOrNull()
        val knownCommits = serverRepo.commits.toHashSet()

        observable
            .takeWhile { new ->  // Hash until last known commit.
                new.rehash != lastKnownCommit?.rehash
            }
            // Don't hash known to server commits.
            .filter { commit -> !knownCommits.contains(commit) }
            // Hash only commits made by authors with specified emails.
            .filter { commit -> emails.contains(commit.author.email) }
            .map { commit ->
                Logger.info { "Extracting stats" }

                // Mapping and stats extraction.
                commit.stats = Extractor().extract(commit.diffs)
                Logger.info { "Stats: ${commit.stats.size} entries" }
                Logger.debug { commit.stats.toString() }

                commit
            }
            // Group ready commits by time and count. Max payload 10 mb,
            // one commit with stats takes around 1 kb, so pack by max 1000
            // with 10x margin of safety.
            .buffer(20, TimeUnit.SECONDS, 1000)
            .subscribe({ commitsBundle ->  // OnNext.
                postCommitsToServer(commitsBundle)  // Send ready commits.
            }, onError)
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
            api.postCommits(commits).onErrorThrow()
            Logger.info { "Sent ${commits.size} added commits to server" }
        }
    }

    private fun deleteCommitsOnServer(commits: List<Commit>) {
        if (commits.isNotEmpty()) {
            api.deleteCommits(commits).onErrorThrow()
            Logger.info { "Sent ${commits.size} deleted commits to server" }
        }
    }
}
