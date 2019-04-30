// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

class PerlExtractor(private val language: String) : ExtractorBase(
    language,
    importRegex = Regex("""^use (.+);"""),
    commentRegex = Regex("""([^\n]*#.*$)"""))
