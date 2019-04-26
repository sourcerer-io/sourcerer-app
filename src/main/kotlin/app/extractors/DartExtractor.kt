// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

import app.RegexMeasured

object DartExtractor : ExtractorBase(
    language = Lang.DART,
    importRegex = RegexMeasured(
        "DartExtractor-importRegex",
        """^import ['"](.+)['"];$"""
    ),
    commentRegex = RegexMeasured(
        "DartExtractor-commentRegex",
        "(//.+$)|(/[*].*?[*]/)"
    )
)
