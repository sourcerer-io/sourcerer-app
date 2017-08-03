// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * Repository.
 */
class Repo() : ProtoWrapper<Repo, Protos.Repo> {
    var path: String = ""
    var rehash: String = ""

    constructor(path: String) : this() {
        this.path = path
    }

    override fun getProto(): Protos.Repo {
        return Protos.Repo.newBuilder()
                .setRehash(rehash)
                .build()
    }

    @Throws(InvalidParameterException::class)
    override fun parseFrom(proto: Protos.Repo): Repo {
        path = ""
        rehash = proto.rehash
        return this
    }

    @Throws(InvalidProtocolBufferException::class)
    override fun parseFrom(bytes: ByteArray): Repo {
        return parseFrom(Protos.Repo.parseFrom(bytes))
    }

    override fun toString(): String {
        return path
    }
}
