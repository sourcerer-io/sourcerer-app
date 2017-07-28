// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app

import app.model.Commit
import app.model.Repo
import app.utils.RepoHelper
import io.reactivex.Observable
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.revwalk.RevCommit
import org.eclipse.jgit.revwalk.RevWalk
import java.io.File
import java.io.IOException

/**
 * RepoHasher hashes repository and uploads stats to server.
 */
class RepoHasher(val repo: Repo) {
    fun update() {
        //TODO(anatoly): Implement repository analysis.
        //TODO(anatoly): Implement data transfer.

        var firstCommit: RevCommit

        // Get commits loading observable and wait for subscribers.
        val observableRevCommits = getObservableRevCommits().publish()

        // Main data flow. Read commits from repo and send them to server.
        observableRevCommits.doOnNext {
                    Logger.info("Commit: ${it.id.name} ${it.shortMessage}")
                }
                .map { c -> Commit(c) }
                .subscribe(
                        {
                            Logger.debug("onNext")
                            SourcererApi.postCommitAsync(it, {}, {})
                        },
                        { e ->
                            Logger.error("Error while hashing: ${e.message}")
                        },
                        {
                            Logger.debug("onComplete")
                        }
                )

        // Additional data flow. Read first commit.
        observableRevCommits.take(1).subscribe({ firstCommit = it }, {
                    // OnError processed on main data flow. Need to be defined.
                })

        // Start emitting commits.
        observableRevCommits.connect()
    }

    fun getObservableRevCommits(): Observable<RevCommit> = Observable.create {
        subscriber ->

        val git = try {
            Git.open(File(repo.path))
        } catch (e: IOException) {
            subscriber.onError(e)
            null
        }

        if (git != null) {
            val repository = git.repository
            try {
                val revWalk = RevWalk(repository)
                val commitId = repository.resolve("refs/heads/master")
                revWalk.markStart(revWalk.parseCommit(commitId))
                // TODO(anatoly): Hash only commits of specific user.
                for (commit in revWalk) {
                    subscriber.onNext(commit)
                }
            } catch (e: Exception) {
                subscriber.onError(e)
            }

            git.close()
        }

        subscriber.onComplete()
    }
}
