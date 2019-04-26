// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.RegexMeasured

object SwiftExtractor : ExtractorBase(
    language = Lang.SWIFT,
    importRegex = RegexMeasured(
        "SwiftExtractor-importRegex",
        """import\s+(\w+)"""
    ),
    commentRegex = RegexMeasured(
        "SwiftExtractor-commentRegex",
        """^([^\n]*//)[^\n]*"""
    )
)
