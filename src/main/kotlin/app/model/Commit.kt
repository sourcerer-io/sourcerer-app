// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.CommitProtos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * Commit.
 */
class Commit : ProtoWrapper<Commit, CommitProtos.Commit> {
    var id: String = ""
    var repo: Repo = Repo("")
    var author: Author = Author("", "")
    var dateTimestamp: Int = 0
    var qommit: Boolean = false
    var numLinesAdd: Int = 0
    var numLinesDelete: Int = 0
    // TODO(anatoly): add Stats.

    override fun getProto(): CommitProtos.Commit {
        return CommitProtos.Commit.newBuilder()
                .setId(id)
                .setRepoId(repo.id)
                .setAuthorName(author.name)
                .setAuthorEmail(author.email)
                .setDate(dateTimestamp)
                .setQommit(qommit)
                .setNumLinesAdd(numLinesAdd)
                .setNumLinesDeleted(numLinesDelete)
                .build()
    }

    @Throws(InvalidParameterException::class)
    override fun parseFrom(proto: CommitProtos.Commit): Commit {
        id = proto.id
        repo = Repo() // TODO(anatoly): fill Repo.
        author = Author(proto.authorName, proto.authorEmail)
        dateTimestamp = proto.date
        qommit = proto.qommit
        numLinesAdd = proto.numLinesAdd
        numLinesDelete = proto.numLinesDeleted
        return this
    }

    @Throws(InvalidProtocolBufferException::class)
    override fun parseFrom(bytes: ByteArray): Commit {
        return parseFrom(CommitProtos.Commit.parseFrom(bytes))
    }
}
