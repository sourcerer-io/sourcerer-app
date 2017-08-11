// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * Tech stats on a commit.
 */
data class Commits(
        var commits: List<Commit> = listOf()
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.Commits) : this() {
        commits = proto.commitsList.map { it -> Commit(it) }
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.Commits.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.Commits {
        return Protos.Commits.newBuilder()
                .addAllCommits(commits.map { it -> it.getProto() })
                .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
