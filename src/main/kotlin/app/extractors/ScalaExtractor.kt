// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

import app.RegexMeasured

object ScalaExtractor : ExtractorBase(
    language = Lang.SCALA,
    importRegex = RegexMeasured(
        "ScalaExtractor-importRegex",
        """^import (?:_root_\.)?((?:\.?[a-z]+)+\.)"""
    ),
    commentRegex = RegexMeasured(
        "ScalaExtractor-commentRegex",
        "(//.+$)|(/[*].*?[*]/)"
    ),
    importStartsWith = true)
