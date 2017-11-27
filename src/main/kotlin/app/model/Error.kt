// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

data class Error(
    var code: Int = 0,
    var message: String = ""
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.Error) : this() {
        code = proto.code
        message = proto.message
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.Error.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.Error {
        return Protos.Error.newBuilder()
            .setCode(code)
            .setMessage(message)
            .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
