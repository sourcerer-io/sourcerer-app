// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * Tech stats on a commit.
 */
data class CommitStats(
        var numLinesAdded: Int = 0,
        var numLinesDeleted: Int = 0,
        var type: Int = 0,
        var tech: String = ""
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.CommitStats) : this() {
        numLinesAdded = proto.numLinesAdded
        numLinesDeleted = proto.numLinesDeleted
        type = proto.type
        tech = proto.tech
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.CommitStats.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.CommitStats {
        return Protos.CommitStats.newBuilder()
            .setNumLinesAdded(numLinesAdded)
            .setNumLinesDeleted(numLinesDeleted)
            .setType(type)
            .setTech(tech)
            .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
