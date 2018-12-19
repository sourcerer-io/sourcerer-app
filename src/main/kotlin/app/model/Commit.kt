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
        var coauthors: List<Author> = mutableListOf(),
        var dateTimestamp: Long = 0,
        var dateTimeZoneOffset: Int = 0,
        var isQommit: Boolean = false,
        var numLinesAdded: Int = 0,
        var numLinesDeleted: Int = 0,
        var stats: List<CommitStats> = mutableListOf()
) {
    // Wrapping JGit's RevCommit.
    var raw: RevCommit? = null  // Not sent to sever.
    var diffs: List<DiffFile> = listOf()

    constructor(revCommit: RevCommit, coauthorsList: List<Author>? = null) :
            this() {
        raw = revCommit

        rehash = DigestUtils.sha256Hex(revCommit.id.name)
        author = Author(revCommit.authorIdent.name,
                        revCommit.authorIdent.emailAddress.toLowerCase())
        dateTimestamp = revCommit.authorIdent.getWhen().time / 1000
        dateTimeZoneOffset = revCommit.authorIdent.timeZoneOffset
        treeRehash = DigestUtils.sha256Hex(revCommit.tree.name)
        if (coauthorsList != null) {
            coauthors = coauthorsList
        }
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
        stats = proto.statsList.map { CommitStats(it) }
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
            .addAllStats(stats.map { it.getProto() })
            .build()
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

    fun getAllAdded(): List<String> {
        return diffs.map { it.getAllAdded() }.flatten()
    }

    fun getAllDeleted(): List<String> {
        return diffs.map { it.getAllDeleted() }.flatten()
    }
}
