package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * Key-value statistics for fun facts.
 */
data class Fact(
    var repo: Repo = Repo(),
    var key: String = "",
    var value: Double = 0.0,
    var author: Author = Author()
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.Fact) : this() {
        repo = Repo(rehash = proto.repoRehash)
        author = Author("", proto.email)
        key = proto.key
        value = proto.value
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.Fact.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.Fact {
        return Protos.Fact.newBuilder()
            .setRepoRehash(repo.rehash)
            .setEmail(author.email)
            .setKey(key)
            .setValue(value)
            .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
