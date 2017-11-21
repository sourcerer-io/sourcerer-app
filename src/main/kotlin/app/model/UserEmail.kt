// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

import app.Protos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

/**
 * User information.
 */
class UserEmail(
    var email: String = "",
    var primary: Boolean = false,
    var verified: Boolean = false
) {
    @Throws(InvalidParameterException::class)
    constructor(proto: Protos.UserEmail) : this() {
        email = proto.email
        primary = proto.primary
        verified = proto.verified
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(Protos.UserEmail.parseFrom(bytes))

    constructor(serialized: String) : this(serialized.toByteArray())

    fun getProto(): Protos.UserEmail {
        return Protos.UserEmail.newBuilder()
            .setEmail(email)
            .setPrimary(primary)
            .setVerified(verified)
            .build()
    }

    fun serialize(): ByteArray {
        return getProto().toByteArray()
    }

    override fun toString(): String {
        val primary = if (this.primary) " (Primary)" else ""
        val verified = if (this.verified) "Confirmed" else "Not confirmed"
        return "${this.email}$primary — $verified"
    }

    override fun equals(other: Any?): Boolean {
        if (other is UserEmail) {
            return email == other.email
        }
        return false
    }

    override fun hashCode(): Int {
        return email.hashCode()
    }
}
