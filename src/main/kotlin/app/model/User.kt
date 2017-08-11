// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * User information.
 */
data class User (
        var repos: MutableList<Repo> = mutableListOf()
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.User) : this() {
        repos = proto.reposList.map { repo -> Repo(repo) }
                .toMutableList()
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.User.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.User {
        return Protos.User.newBuilder()
                .addAllRepos(repos.map { repo -> repo.getProto() })
                .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }
}
