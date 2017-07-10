// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

import com.beust.jcommander.IParameterValidator
import com.beust.jcommander.ParameterException
import java.io.File

class PathValidator : IParameterValidator {
    @Throws(ParameterException::class)
    override fun validate(name: String, value: String) {
        if (!isValidPath(value)) {
            throw ParameterException(
                    "Parameter $name should be correct path (found $value)")
        }
    }

    fun isValidPath(path: String): Boolean {
        var isValidPath = false

        try {
            val f = File(path)
            isValidPath = f.isDirectory
        } catch (e: SecurityException) {
        }

        return isValidPath
    }
}
