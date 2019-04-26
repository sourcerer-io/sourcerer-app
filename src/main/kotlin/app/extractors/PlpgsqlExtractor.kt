// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

import app.RegexMeasured

object PlpgsqlExtractor : ExtractorBase(
    language = Lang.PLPGSQL,
    importRegex = RegexMeasured(
        "PlpgsqlExtractor-commentRegex",
        """.+CREATE (?:EXTENSION|LANGUAGE) ([a-zA-Z_][a-zA-Z0-9_]*)"""
    ),
    commentRegex = RegexMeasured(
        "PlpgsqlExtractor-commentRegex",
        """(--.*$)|(/[*].*?[*]/)"""
    )
)
