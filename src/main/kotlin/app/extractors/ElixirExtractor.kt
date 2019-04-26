// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

import app.RegexMeasured

object ElixirExtractor : ExtractorBase(
    language = Lang.ELIXIR,
    importRegex = RegexMeasured(
        CLASS_TAG + "importRegex",
        """^\s+(?:use|import|require) ([a-zA-Z_][a-zA-Z0-9_]*)"""
    ),
    commentRegex = RegexMeasured(
        CLASS_TAG + "commentRegex",
        """#.*$"""
    )
)
