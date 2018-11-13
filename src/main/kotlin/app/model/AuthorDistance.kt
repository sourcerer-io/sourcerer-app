// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

data class AuthorDistance(
        var repo: Repo = Repo(),
        var email: String = "",
        var score: Double = 0.0
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.AuthorDistance) : this() {
        repo = Repo(rehash = proto.repoRehash)
        email = proto.email
        score = proto.score
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.AuthorDistance.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.AuthorDistance {
        return Protos.AuthorDistance.newBuilder()
                .setRepoRehash(repo.rehash)
                .setEmail(email)
                .setScore(score)
                .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
