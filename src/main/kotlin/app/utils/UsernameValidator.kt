// Copyright 2017 Sourcerer Inc. All Rights Reserved.

package app.utils

import com.beust.jcommander.IParameterValidator
import com.beust.jcommander.ParameterException

object UsernameValidator : IParameterValidator {
    @Throws(ParameterException::class)
    override fun validate(name: String, value: String) {
        if (!isValidUsername(value)) {
            throw ParameterException(
                    "Parameter $name should be correct username (found $value)")
        }
    }

    fun isValidUsername(username: String): Boolean {
        return Regex("^[a-zA-Z0-9_.+-]$").containsMatchIn(username)
    }
}
