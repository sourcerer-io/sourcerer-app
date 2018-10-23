// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

data class AuthorDistanceGroup(
        var stats: List<AuthorDistance> = listOf()
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.AuthorDistanceGroup) : this() {
        stats = proto.authorDistancesList.map { AuthorDistance(it) }
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.AuthorDistanceGroup.parseFrom
    (bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.AuthorDistanceGroup {
        return Protos.AuthorDistanceGroup.newBuilder()
                .addAllAuthorDistances(stats.map { it.getProto() })
                .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
