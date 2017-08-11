// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

import com.github.kittinunf.fuel.core.FuelError
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

class RequestException(val exception: Exception)
        : Exception(exception.message) {
    var httpStatusCode: Int = 0
    var httpResponseMessage: String = ""

    var isAuthError: Boolean = false
    get() = httpStatusCode == 403

    var isParseError = false

    constructor(fuelError: FuelError) : this(fuelError as Exception) {
        httpStatusCode = fuelError.response.httpStatusCode
        httpResponseMessage = fuelError.response.httpResponseMessage
    }

    constructor(parseException: InvalidProtocolBufferException) :
            this(parseException as Exception) {
        isParseError = true
    }

    constructor(parseException: InvalidParameterException) :
            this(parseException as Exception) {
        isParseError = true
    }
}
