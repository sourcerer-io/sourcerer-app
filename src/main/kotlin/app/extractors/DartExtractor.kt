// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

object DartExtractor : ExtractorBase(
    language = Lang.DART,
    importRegex = Regex("""^import ['"](.+)['"];$"""),
    commentRegex = Regex("(//.+$)|(/[*].*?[*]/)"))
