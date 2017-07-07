// Copyright 2017 Sourcerer Inc. All Rights Reserved.

package app.utils

import com.beust.jcommander.IParameterValidator
import com.beust.jcommander.ParameterException

object EmailValidator : IParameterValidator {
    @Throws(ParameterException::class)
    override fun validate(name: String, value: String) {
        if (!isValidEmail(value)) {
            throw ParameterException(
                    "Parameter $name should be correct email (found $value)")
        }
    }

    fun isValidEmail(email: String): Boolean {
        return Regex(
                "^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+\$")
                .containsMatchIn(email)
    }
}
