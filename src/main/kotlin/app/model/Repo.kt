// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * Repository.
 */
class Repo(
        // Basic info.
        var path: String = "",
        var rehash: String = "",
        var initialCommit: Commit = Commit(),

        // Authors' email filter for hashed commits. If empty list then hash
        // only commits that created by current user.
        var emails: List<String> = listOf(),

        // Raw commits server history. Used to find overlap of commits.
        var commits: List<Commit> = listOf()
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.Repo) : this() {
        rehash = proto.rehash
        initialCommit = Commit(rehash = proto.initialCommitRehash)
        emails = proto.emailsList
        commits = proto.commitsList.map { it -> Commit(it) }
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.Repo.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.Repo {
        return Protos.Repo.newBuilder()
                .setRehash(rehash)
                .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }

    override fun toString(): String {
        return path
    }
}
