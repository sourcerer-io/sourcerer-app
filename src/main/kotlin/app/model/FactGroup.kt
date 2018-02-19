// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * Group of key-value facts.
 */
data class FactGroup(
        var stats: List<Fact> = listOf()
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.FactGroup) : this() {
        stats = proto.factsList.map { it -> Fact(it) }
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.FactGroup.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.FactGroup {
        return Protos.FactGroup.newBuilder()
            .addAllFacts(stats.map { it -> it.getProto() })
            .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
