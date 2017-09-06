// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

import java.nio.file.Paths

object FileHelper {
    fun getFileExtension(path: String): String {
        val fileName = Paths.get(path).fileName.toString()
        return fileName.substringAfterLast(
                delimiter = '.', missingDelimiterValue = "")
    }
}
