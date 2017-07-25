// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.CommitProtos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * Repository.
 */
class Repo() : ProtoWrapper<Repo, CommitProtos.Repo> {
    var path: String = ""
    var id: String = ""
    var lastCommitId: String = ""

    constructor(path: String) : this() {
        this.path = path
    }

    override fun getProto(): CommitProtos.Repo {
        return CommitProtos.Repo.newBuilder()
                .setId(id)
                .setLastCommitId(lastCommitId)
                .build()
    }

    @Throws(InvalidParameterException::class)
    override fun parseFrom(proto: CommitProtos.Repo): Repo {
        path = ""
        id = proto.id
        lastCommitId = proto.lastCommitId
        return this
    }

    @Throws(InvalidProtocolBufferException::class)
    override fun parseFrom(bytes: ByteArray): Repo {
        return parseFrom(CommitProtos.Repo.parseFrom(bytes))
    }

    override fun toString(): String {
        return path
    }
}
