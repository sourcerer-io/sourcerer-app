// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.api

import app.Logger
import app.model.Error
import app.model.Errors
import com.github.kittinunf.fuel.core.FuelError
import com.google.protobuf.InvalidProtocolBufferException
import java.nio.charset.Charset
import java.security.InvalidParameterException

class ApiError(exception: Exception) : Exception(exception.message) {
    companion object {
        private val AUTH_ERROR_CODES = listOf(401, 403)
    }

    // Response content.
    var httpStatusCode: Int = 0
    var httpResponseMessage: String = ""
    var httpBodyMessage: String = ""

    // Server errors from response.
    var serverErrors = listOf<Error>()

    // Type of errors.
    var isParseError = false
    var isAuthError: Boolean = false
    get() = AUTH_ERROR_CODES.contains(httpStatusCode)

    constructor(fuelError: FuelError) : this(fuelError as Exception) {
        httpStatusCode = fuelError.response.statusCode
        httpResponseMessage = fuelError.response.responseMessage
        if (fuelError.response.headers["Content-Type"]
            ?.contains("application/octet-stream") == true) {
            try {
                serverErrors = Errors(fuelError.response.data).errors
            } catch (e: Exception) {
                Logger.error(e, "Error while parsing errors from server")
            }
        } else {
            httpBodyMessage = fuelError.response.data
                .toString(Charset.defaultCharset())
        }
    }

    constructor(parseException: InvalidProtocolBufferException) :
            this(parseException as Exception) {
        isParseError = true
    }

    constructor(parseException: InvalidParameterException) :
            this(parseException as Exception) {
        isParseError = true
    }

    fun isWithServerCode(serverErrorCode: Int): Boolean {
        return serverErrors.find { error ->
            error.code == serverErrorCode } != null
    }
}

fun ApiError?.ifNotNullThrow() {
    if (this != null) {
        throw this
    }
}

fun ApiError?.isWithServerCode(serverErrorCode: Int): Boolean {
    if (this != null) {
        return this.isWithServerCode(serverErrorCode)
    }
    return false
}
