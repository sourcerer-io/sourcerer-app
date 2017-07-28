// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

import com.github.kittinunf.fuel.core.FuelError

class RequestException(val exception: Exception)
        : Exception(exception.message) {
    var httpStatusCode: Int = 0
    var httpResponseMessage: String = ""

    constructor(fuelError: FuelError) : this(fuelError as Exception) {
        httpStatusCode = fuelError.response.httpStatusCode
        httpResponseMessage = fuelError.response.httpResponseMessage
    }

    fun isAuthError(): Boolean {
        return httpStatusCode == 403
    }
}
