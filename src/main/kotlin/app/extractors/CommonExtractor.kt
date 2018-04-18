// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class CommonExtractor : ExtractorInterface {
    companion object {
        val FILE_EXTS_MAP = lazy {
            val reversedMap = mutableMapOf<String, List<String>>()
            reversedMap["actionscript"] = listOf("as")
            reversedMap["arduino"] = listOf("ino")
            reversedMap["assembly"] = listOf("asm", "s", "S")
            reversedMap["clojure"] = listOf("clj", "cljs", "cljc", "edn")
            reversedMap["cobol"] = listOf("cbl", "cob", "cpy")
            reversedMap["coffeescript"] = listOf("coffee", "litcoffee")
            reversedMap["cuda"] = listOf("cu", "cuh")
            reversedMap["d"] = listOf("d")
            reversedMap["dosbatch"] = listOf("bat")
            reversedMap["emacslisp"] = listOf("el", "elc")
            reversedMap["erlang"] = listOf("erl", "hrl")
            reversedMap["elixir"] = listOf("ex", "exs")
            reversedMap["elm"] = listOf("elm")
            reversedMap["factor"] = listOf("factor")
            reversedMap["forth"] = listOf("forth", "4TH")
            reversedMap["fortran"] = listOf("f", "for", "f90", "f95", "f03",
                    "f08", "f15")
            reversedMap["gradle"] = listOf("gradle")
            reversedMap["groovy"] = listOf("groovy")
            reversedMap["haskell"] = listOf("hs", "lhs")
            reversedMap["haxe"] = listOf("hx")
            reversedMap["html"] = listOf("html", "htm")
            reversedMap["hy"] = listOf("hy")
            reversedMap["j"] = listOf("ijs")
            reversedMap["julia"] = listOf("jl")
            reversedMap["lisp"] = listOf("lisp", "lsp", "l")
            reversedMap["lua"] = listOf("lua")
            reversedMap["makefile"] = listOf("makefile")
            reversedMap["matlab"] = listOf("m", "mlx")
            reversedMap["maven"] = listOf("pom")
            reversedMap["ocaml"] = listOf("ml", "mli")
            reversedMap["oxygene"] = listOf("oxygene")
            reversedMap["pascal"] = listOf("pas")
            reversedMap["perl"] = listOf("pl", "PL")
            reversedMap["powershell"] = listOf("ps1", "psm1", "psd1")
            reversedMap["processing"] = listOf("pde")
            reversedMap["prolog"] = listOf("P")
            reversedMap["puppet"] = listOf("pp")
            reversedMap["qml"] = listOf("qml")
            reversedMap["r"] = listOf("r", "R")
            reversedMap["rust"] = listOf("rs")
            reversedMap["sas"] = listOf("sas")
            reversedMap["scala"] = listOf("scala", "sc")
            reversedMap["scheme"] = listOf("scm", "ss")
            reversedMap["shell"] = listOf("sh")
            reversedMap["smalltalk"] = listOf("st")
            reversedMap["sql"] = listOf("sql")
            reversedMap["tcl"] = listOf("tcl")
            reversedMap["tex"] = listOf("tex")
            reversedMap["typescript"] = listOf("ts", "tsx")
            reversedMap["verilog"] = listOf("v")
            reversedMap["vhdl"] = listOf("vhdl")
            reversedMap["viml"] = listOf("vim")
            reversedMap["visualbasic"] = listOf("bas")
            reversedMap["visualbasicforapps"] = listOf("vba")
            reversedMap["vue"] = listOf("vue")
            reversedMap["wolframlanguage"] = listOf("nb","m")
            reversedMap["xtend"] = listOf("xtend")

            val map = hashMapOf<String, String>()
            reversedMap.forEach({ lang, exts ->
                exts.forEach { ext -> map.put(ext, lang)}
            })
            map
        }
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        files.mapNotNull { file ->
            val lang = FILE_EXTS_MAP.value[file.extension]
            if (lang != null) {
                file.language = lang
                file
            } else null
        }

        return super.extract(files)
    }
}
