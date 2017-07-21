// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app

import app.utils.RepoHelper

/**
 * RepoExplorer hashes repository and uploads stats to server.
 */
class RepoExplorer(val repoPath: String) {
    fun explore() {
        println(RepoHelper.isValidRepo(repoPath))

        //TODO(anatoly): Implement repository analysis.
        //TODO(anatoly): Implement data transfer.
    }
}
