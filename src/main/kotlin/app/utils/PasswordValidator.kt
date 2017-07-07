// Copyright 2017 Sourcerer Inc. All Rights Reserved.

package app.utils

import com.beust.jcommander.IParameterValidator
import com.beust.jcommander.ParameterException

object PasswordValidator : IParameterValidator {
    @Throws(ParameterException::class)
    override fun validate(name: String, value: String) {
        if (!isValidPassword(value)) {
            throw ParameterException(
                    "Parameter $name should be password of correct format")
        }
    }

    fun isValidPassword(password: String): Boolean {
        return Regex("^[a-zA-Z0-9_.+-]$").containsMatchIn(password)
    }
}
