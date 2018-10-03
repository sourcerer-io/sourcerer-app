// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

object SwiftExtractor : ExtractorBase(
    language = Lang.SWIFT,
    importRegex = Regex("""import\s+(\w+)"""),
    commentRegex = Regex("""^([^\n]*//)[^\n]*"""))
