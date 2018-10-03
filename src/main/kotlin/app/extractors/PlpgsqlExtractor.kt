// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

object PlpgsqlExtractor : ExtractorBase(
    language = Lang.PLPGSQL,
    importRegex = Regex(""".+CREATE (?:EXTENSION|LANGUAGE) ([a-zA-Z_][a-zA-Z0-9_]*)"""),
    commentRegex = Regex("""(--.*$)|(/[*].*?[*]/)"""))
