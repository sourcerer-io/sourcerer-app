// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app

/**
 * Repository data class.
 */
data class Repo(val path: String) {
    override fun toString(): String {
        return path
    }
}
