// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app

import app.utils.CommandExplore
import java.io.File

/**
 * RepoExplorer analyzes repositories and uploads stats to server.
 */
class RepoExplorer(options: CommandExplore) {
    val path = options.path

    fun explore() {
        var isValidPath = false

        try {
            val f = File(path)
            isValidPath = f.isDirectory
        } catch (e: SecurityException) {
        }

        println(isValidPath)

        //TODO(anatoly): Implement repository analysis.
        //TODO(anatoly): Implement data transfer.
    }
}
