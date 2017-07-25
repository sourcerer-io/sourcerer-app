// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import com.google.protobuf.GeneratedMessageV3

/**
 * Protobuf class wrapper interface.
 */
interface ProtoWrapper<out T, P : GeneratedMessageV3> {
    fun getProto(): P

    fun serialize(): String {
        return this.getProto().toByteArray().toString(Charsets.UTF_8)
    }

    fun parseFrom(proto: P): T

    fun parseFrom(bytes: ByteArray): T

    fun parseFrom(serialized: String): T {
        return this.parseFrom(serialized.toByteArray(Charsets.UTF_8))
    }
}
