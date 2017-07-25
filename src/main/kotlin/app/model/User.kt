// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.CommitProtos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * User information.
 */
class User : ProtoWrapper<User, CommitProtos.User> {
    var profileUrl: String = ""
    var repos: MutableList<Repo> = mutableListOf()

    override fun getProto(): CommitProtos.User {
        return CommitProtos.User.newBuilder()
                .setUrl(profileUrl)
                .addAllRepos(repos.map { repo -> repo.getProto() })
                .build()
    }

    @Throws(InvalidParameterException::class)
    override fun parseFrom(proto: CommitProtos.User): User {
        profileUrl = proto.url
        repos = proto.reposList.map { repo -> Repo("").parseFrom(repo) }
                .toMutableList()
        return this
    }

    @Throws(InvalidParameterException::class,
            InvalidProtocolBufferException::class)
    override fun parseFrom(bytes: ByteArray): User {
        return parseFrom(CommitProtos.User.parseFrom(bytes))
    }
}
