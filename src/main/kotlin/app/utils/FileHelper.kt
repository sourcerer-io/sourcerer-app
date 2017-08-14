// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

import java.nio.file.Path

object FileHelper {
    fun getFileExtension(path: Path): String {
        val fileName = path.fileName.toString()
        return fileName.substringAfterLast(
                delimiter = '.', missingDelimiterValue = "")
    }
}
