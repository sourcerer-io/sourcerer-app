// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app

import app.CommitProtos.Commit

/**
 * Sourcerer API.
 */
object SourcererApi {
    fun getUserInfoBlocking(): String {
        // TODO(anatoly): Implement.
        return readLine() ?: ""  // Mock.
    }

    fun postCommitBlocking(commit: Commit) {
        // TODO(anatoly): Implement.
    }

    fun getUserInfoAsync(success: (String) -> Unit, failure: (String) -> Unit) {
        // TODO(anatoly): Implement.
    }

    fun postCommitAsync(success: (String) -> Unit, failure: (String) -> Unit) {
        // TODO(anatoly): Implement.
    }
}
