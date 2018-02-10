package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * Used to describe processing of multiple repos.
 */
data class Process(
    var id: Int = 0,
    var requestNumEntries: Int = 0,
    var entries: List<ProcessEntry> = mutableListOf()
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.Process) : this() {
        id = proto.id
        requestNumEntries = proto.requestNumEntries
        entries = proto.entriesList.map { ProcessEntry(it) }
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.Process.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.Process {
        return Protos.Process.newBuilder()
                     .setId(id)
                     .setRequestNumEntries(requestNumEntries)
                     .addAllEntries(entries.map { it.getProto() })
                     .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
