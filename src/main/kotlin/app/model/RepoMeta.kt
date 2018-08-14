package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * Meta info about repo. Is not used for a locally run app.
 */
data class RepoMeta(
    var hosterId: String = "",
    var name: String = "",
    var ownerName: String = "",
    var htmlUrl: String = "",
    var cloneUrl: String = ""
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.RepoMeta) : this() {
        hosterId = proto.hosterId
        name = proto.name
        ownerName = proto.ownerName
        htmlUrl = proto.htmlUrl
        cloneUrl = proto.cloneUrl
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.RepoMeta.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.RepoMeta {
        return Protos.RepoMeta.newBuilder()
            .setHosterId(hosterId)
            .setName(name)
            .setOwnerName(ownerName)
            .setHtmlUrl(htmlUrl)
            .setCloneUrl(cloneUrl)
            .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
