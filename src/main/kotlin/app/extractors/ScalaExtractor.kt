// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

object ScalaExtractor : ExtractorBase(
    language = Lang.SCALA,
    importRegex = Regex("""^import (?:_root_\.)?((?:\.?[a-z]+)+\.)"""),
    commentRegex = Regex("(//.+$)|(/[*].*?[*]/)"),
    importStartsWith = true)
