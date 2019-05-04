// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

class PerlExtractor(private val language: String) : ExtractorBase(
    language,
    importRegex = Regex("""^use (.+);"""),
    commentRegex = Regex("""([^\n]*#.*$)"""),
    importStartsWith = true) {

    override fun mapImportToIndex(import: String, lang: String,
                                  startsWith: Boolean): String? {
        // Perl and Perl6 share libraries
        return super.mapImportToIndex(import, Lang.PERL, startsWith)
    }
}