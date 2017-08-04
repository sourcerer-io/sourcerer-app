// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import org.apache.commons.codec.digest.DigestUtils
import org.eclipse.jgit.revwalk.RevCommit
import java.security.InvalidParameterException

/**
 * Commit.
 */
class Commit(
        var rehash: String = "",
        var repo: Repo = Repo(""),
        var author: Author = Author("", ""),
        var dateTimestamp: Int = 0,
        var isQommit: Boolean = false,
        var numLinesAdded: Int = 0,
        var numLinesDeleted: Int = 0
        // TODO(anatoly): add Stats.
) {
    constructor(revCommit: RevCommit) : this() {
        rehash = DigestUtils.sha256Hex(revCommit.id.name)
        author = Author(revCommit.authorIdent.name,
                             revCommit.authorIdent.emailAddress)
        dateTimestamp = revCommit.commitTime
    }

    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.Commit) : this() {
        rehash = proto.rehash
        repo = Repo() // TODO(anatoly): fill Repo.
        author = Author(proto.authorName, proto.authorEmail)
        dateTimestamp = proto.date
        isQommit = proto.isQommit
        numLinesAdded = proto.numLinesAdded
        numLinesDeleted = proto.numLinesDeleted
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.Commit.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.Commit {
        return Protos.Commit.newBuilder()
                .setRehash(rehash)
                .setRepoRehash(repo.rehash)
                .setAuthorName(author.name)
                .setAuthorEmail(author.email)
                .setDate(dateTimestamp)
                .setIsQommit(isQommit)
                .setNumLinesAdded(numLinesAdded)
                .setNumLinesDeleted(numLinesDeleted)
                .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
