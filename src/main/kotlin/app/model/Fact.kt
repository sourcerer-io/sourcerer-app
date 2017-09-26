package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * Key-value statistics for fun facts.
 */
data class Fact(
    var repo: Repo = Repo(),
    var code: Int = 0,
    var key: Int = 0,
    var value: Double = 0.0,
    var author: Author = Author()
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.Fact) : this() {
        repo = Repo(rehash = proto.repoRehash)
        author = Author("", proto.email)
        code = proto.code
        key = proto.key
        value = proto.value1.toDoubleOrNull() ?: 0.0
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.Fact.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.Fact {
        return Protos.Fact.newBuilder()
            .setRepoRehash(repo.rehash)
            .setEmail(author.email)
            .setCode(code)
            .setKey(key)
            .setValue1(value.toString())
            .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
