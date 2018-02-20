package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * Group of commit authors.
 */
data class AuthorGroup(
        var authors: List<Author> = listOf()
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.AuthorGroup) : this() {
        authors = proto.authorsList.map { it -> Author(it) }
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.AuthorGroup.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.AuthorGroup {
        return Protos.AuthorGroup.newBuilder()
            .addAllAuthors(authors.map { it -> it.getProto() })
            .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
