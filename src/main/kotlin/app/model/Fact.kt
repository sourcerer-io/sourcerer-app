// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

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
    var value: String = "",
    var author: Author = Author(),
    var value2: String = "",
    var value3: String = ""
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.Fact) : this() {
        repo = Repo(rehash = proto.repoRehash)
        author = Author("", proto.email)
        code = proto.code
        key = proto.key
        value = ""
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
            .setValue1(value)
            .setValue2(value2)
            .setValue3(value3)
            .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
