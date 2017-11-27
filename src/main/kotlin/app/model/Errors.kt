// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

data class Errors (
    var errors: List<Error> = listOf()
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.Errors) : this() {
        errors = proto.errorsList.map { error -> Error(error) }
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.Errors.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.Errors {
        return Protos.Errors.newBuilder()
            .addAllErrors(errors.map { error -> error.getProto() })
            .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
