package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * Used to describe processing of a single repo.
 */
data class ProcessEntry(
    var id: Int = 0,
    var status: Int = 0,
    var errorCode: Int = 0
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.ProcessEntry) : this() {
        id = proto.id
        status = proto.status
        errorCode = proto.errorCode
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.ProcessEntry.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.ProcessEntry {
        return Protos.ProcessEntry.newBuilder()
            .setId(id)
            .setStatus(status)
            .setErrorCode(errorCode)
            .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
