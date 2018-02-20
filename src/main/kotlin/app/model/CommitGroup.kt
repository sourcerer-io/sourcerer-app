// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * Tech stats on a commit.
 */
data class CommitGroup(
        var commits: List<Commit> = listOf()
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.CommitGroup) : this() {
        commits = proto.commitsList.map { it -> Commit(it) }
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.CommitGroup.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.CommitGroup {
        return Protos.CommitGroup.newBuilder()
            .addAllCommits(commits.map { it -> it.getProto() })
            .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
