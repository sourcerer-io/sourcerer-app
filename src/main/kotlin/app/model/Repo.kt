// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * Repository.
 */
data class Repo(
    // Basic info.
    var rehash: String = "",
    var initialCommitRehash: String = "",

    // Authors' email filter for hashed commits. If empty list then hash
    // only commits that created by current user.
    var emails: List<String> = listOf(),

    // Raw commits server history. Used to find overlap of commits.
    var commits: List<Commit> = listOf(),

    // Meta info about repo. Is not used for a locally run app.
    var meta: RepoMeta = RepoMeta(),

    // Processing session id, used to check the processing status.
    var processEntryId: Int = 0
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.Repo) : this() {
        rehash = proto.rehash
        initialCommitRehash = proto.initialCommitRehash
        emails = proto.emailsList
        commits = proto.commitsList.map { Commit(it) }
        processEntryId = proto.processEntryId
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.Repo.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.Repo {
        return Protos.Repo.newBuilder()
            .setRehash(rehash)
            .setInitialCommitRehash(rehash)
            .addAllEmails(emails)
            .addAllCommits(commits.map { it.getProto() })
            .setMeta(meta.getProto())
            .setProcessEntryId(processEntryId)
            .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other?.javaClass != javaClass) return false
        return rehash == (other as Repo).rehash
    }

    override fun hashCode(): Int {
        return rehash.hashCode()
    }
}
