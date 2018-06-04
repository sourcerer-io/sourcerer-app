// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package test.tests.extractors

// Special cases, when language code name is not a dir name in lower case.
val dirToLangMap = mapOf(
    "DOS Batch" to "dosbatch",
    "C#" to "csharp",
    "C++" to "cpp",
    "Common Lisp" to "lisp",
    "F#" to "fsharp",
    "Filebench WML" to "filebench_wml",
    "Objective-C" to "objectivec",
    "Perl 6" to "perl6",
    "POV-Ray SDL" to "pov-ray_sdl",
    "Ren'Py" to "renpy",
    "Visual Basic" to "visualbasic",
    "Wolfram Language" to "wolframlanguage"
)
