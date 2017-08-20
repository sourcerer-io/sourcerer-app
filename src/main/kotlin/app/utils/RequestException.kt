// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

import com.github.kittinunf.fuel.core.FuelError
import com.google.protobuf.InvalidProtocolBufferException
import java.nio.charset.Charset
import java.security.InvalidParameterException

class RequestException(val exception: Exception)
        : Exception(exception.message) {
    private val AUTH_ERROR_CODES = listOf(401, 403)

    var httpStatusCode: Int = 0
    var httpResponseMessage: String = ""
    var httpBodyMessage: String = ""

    var isAuthError: Boolean = false
    get() = AUTH_ERROR_CODES.contains(httpStatusCode)

    var isParseError = false

    constructor(fuelError: FuelError) : this(fuelError as Exception) {
        httpStatusCode = fuelError.response.httpStatusCode
        httpResponseMessage = fuelError.response.httpResponseMessage
        httpBodyMessage = fuelError.response.data
            .toString(Charset.defaultCharset())
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
