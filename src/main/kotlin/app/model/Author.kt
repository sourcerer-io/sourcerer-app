// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

/**
 * Commit author.
 */
data class Author(var name: String = "", var email: String = "") {
    // Email defines user identity.
    override fun equals(other: Any?): Boolean {
        if (other is Author) {
            return email == other.email
        }
        return false
    }

    override fun hashCode(): Int {
        return email.hashCode()
    }
}
