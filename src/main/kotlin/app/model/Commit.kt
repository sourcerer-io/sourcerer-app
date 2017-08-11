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
data class Commit(
        var rehash: String = "",
        var repo: Repo = Repo(),
        // Tree rehash used for adjustments of stats due to rebase and fraud.
        var treeRehash: String = "",
        var author: Author = Author(),
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
        treeRehash = DigestUtils.sha256Hex(revCommit.tree.name)
        // TODO(anatoly): add Stats, isQommit, numLines.
    }

    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.Commit) : this() {
        rehash = proto.rehash
        repo = Repo(rehash = proto.repoRehash)
        treeRehash = proto.treeRehash
        author = Author(proto.authorName, proto.authorEmail)
        dateTimestamp = proto.date
        isQommit = proto.isQommit
        numLinesAdded = proto.numLinesAdded
        numLinesDeleted = proto.numLinesDeleted
        // TODO(anatoly): add Stats.
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.Commit.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.Commit {
        return Protos.Commit.newBuilder()
                .setRehash(rehash)
                .setRepoRehash(repo.rehash)
                .setTreeRehash(treeRehash)
                .setAuthorName(author.name)
                .setAuthorEmail(author.email)
                .setDate(dateTimestamp)
                .setIsQommit(isQommit)
                .setNumLinesAdded(numLinesAdded)
                .setNumLinesDeleted(numLinesDeleted)
                .build()
        // TODO(anatoly): add Stats.
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other?.javaClass != javaClass) return false
        return rehash == (other as Commit).rehash
    }

    override fun hashCode(): Int {
        return rehash.hashCode()
    }
}
