// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class CommonExtractor : ExtractorInterface {
    companion object {
        val FILE_EXTS_MAP = lazy {
            val reversedMap = mutableMapOf<String, List<String>>()
            reversedMap.put("actionscript", listOf("as"))
            reversedMap.put("arduino", listOf("ino"))
            reversedMap.put("assembly", listOf("asm", "s", "S"))
            reversedMap.put("clojure", listOf("clj", "cljs", "cljc", "edn"))
            reversedMap.put("cobol", listOf("cbl", "cob", "cpy"))
            reversedMap.put("coffeescript", listOf("coffee", "litcoffee"))
            reversedMap.put("cuda", listOf("cu", "cuh"))
            reversedMap.put("d", listOf("d"))
            reversedMap.put("emacslisp", listOf("el", "elc"))
            reversedMap.put("erlang", listOf("erl", "hrl"))
            reversedMap.put("forth", listOf("forth", "4TH"))
            reversedMap.put("fortran", listOf("f", "for", "f90", "f95", "f03",
                "f08", "f15"))
            reversedMap.put("gradle", listOf("gradle"))
            reversedMap.put("groovy", listOf("groovy"))
            reversedMap.put("haskell", listOf("hs", "lhs"))
            reversedMap.put("html", listOf("html", "htm"))
            reversedMap.put("j", listOf("ijs"))
            reversedMap.put("julia", listOf("jl"))
            reversedMap.put("lisp", listOf("lisp", "lsp", "l"))
            reversedMap.put("lua", listOf("lua"))
            reversedMap.put("makefile", listOf("makefile"))
            reversedMap.put("matlab", listOf("m", "mlx"))
            reversedMap.put("maven", listOf("pom"))
            reversedMap.put("ocaml", listOf("ml", "mli"))
            reversedMap.put("pascal", listOf("pas"))
            reversedMap.put("perl", listOf("pl", "PL"))
            reversedMap.put("powershell", listOf("ps1", "psm1", "psd1"))
            reversedMap.put("processing", listOf("pde"))
            reversedMap.put("prolog", listOf("pl", "P"))
            reversedMap.put("puppet", listOf("pp"))
            reversedMap.put("r", listOf("r", "R"))
            reversedMap.put("rust", listOf("rs"))
            reversedMap.put("sas", listOf("sas"))
            reversedMap.put("scala", listOf("scala", "sc"))
            reversedMap.put("scheme", listOf("scm", "ss"))
            reversedMap.put("shell", listOf("sh"))
            reversedMap.put("sql", listOf("sql"))
            reversedMap.put("tcl", listOf("tcl"))
            reversedMap.put("tex", listOf("tex"))
            reversedMap.put("typescript", listOf("ts", "tsx"))
            reversedMap.put("verilog", listOf("v"))
            reversedMap.put("vhdl", listOf("vhdl"))
            reversedMap.put("viml", listOf("vim"))
            reversedMap.put("visualbasic", listOf("bas"))
            reversedMap.put("vue", listOf("vue"))

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
