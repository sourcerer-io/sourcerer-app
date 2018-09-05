// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

object ElixirExtractor : ExtractorBase(
    language = Lang.ELIXIR,
    importRegex = Regex("""^\s+(?:use|import|require) ([a-zA-Z_][a-zA-Z0-9_]*)"""),
    commentRegex = Regex("""#.*$"""))
