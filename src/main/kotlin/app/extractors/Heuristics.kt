// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

val ActionScriptRegex = Regex(
    "^\\s*(package\\s+[a-z0-9_\\.]+|import\\s+[a-zA-Z0-9_\\.]+;|class\\s+[A-Za-z0-9_]+\\s+extends\\s+[A-Za-z0-9_]+)"
)
val CSharpRegex = Regex("^\\s*namespace\\s*[\\w\\.]+\\s*\\{")
var DRegex = Regex(
    "^module\\s+[\\w.]*\\s*;|import\\s+[\\w\\s,.:]*;|\\w+\\s+\\w+\\s*\\(.*\\)(?:\\(.*\\))?\\s*\\{[^}]*\\}|unittest\\s*(?:\\(.*\\))?\\s*\\{[^}]*\\}"
)
var DTraceRegex = Regex(
    "^(\\w+:\\w*:\\w*:\\w*|BEGIN|END|provider\\s+|(tick|profile)-\\w+\\s+\\{[^}]*\\}|#pragma\\s+D\\s+(option|attributes|depends_on)\\s|#pragma\\s+ident\\s)"
)
var FSharpRegex = Regex("^\\s*(#light|import|let|module|namespace|open|type)")
var ForthRegex = Regex(" /^: /")
var FortranRegex = Regex(
    "^([c*][^abd-z]|      (subroutine|program|end|data)\\s|\\s*!)", RegexOption.IGNORE_CASE
)
var GLSLRegex = Regex("^\\s*(#version|precision|uniform|varying|vec[234])")
var LispRegex = Regex("^\\s*\\((defun|in-package|defpackage) ", RegexOption.IGNORE_CASE)
var MakefileRegex = Regex(
    "([\\/\\\\].*:\\s+.*\\s\\\\$|: \\\\$|^ : |^[\\w\\s\\/\\\\.]+\\w+\\.\\w+\\s*:\\s+[\\w\\s\\/\\\\.]+\\w+\\.\\w+)"
)
var NewLispRegex = Regex("^\\s*\\(define ")
val ObjectiveCRegex = Regex(
    "^\\s*(@(interface|class|protocol|property|end|synchronised|selector|implementation)\\b|#import\\s+.+\\.h[\">])"
)
var Perl5Regex = Regex("\\buse\\s+(?:strict\\b|v?5\\.)")
var Perl6Regex = Regex("^\\s*(?:use\\s+v6\\b|\\bmodule\\b|\\b(?:my\\s+)?class\\b)")

var PLSQLRegexs = setOf(
    Regex("\\\$\\\$PLSQL_|XMLTYPE|sysdate|systimestamp|\\.nextval|connect by|AUTHID (DEFINER|CURRENT_USER)", RegexOption.IGNORE_CASE),
    Regex("constructor\\W+function", RegexOption.IGNORE_CASE)
)
var NotSQLRegex = Regex("begin|boolean|package|exception", RegexOption.IGNORE_CASE)

var PythonRegex = Regex("(^(import|from|class|def)\\s)", RegexOption.MULTILINE)
var RustRegex = Regex("^(use |fn |mod |pub |macro_rules|impl|#!?\\[)")
var RenderScriptRegex = Regex("#include|#pragma\\s+(rs|version)|__attribute__")
var ScalaRegex = Regex(
    "^\\s*import (scala|java)\\./.match(data) || /^\\s*val\\s+\\w+\\s*=/.match(data) || /^\\s*class\\b"
)
var XMLPropsRegex = Regex("^(\\s*)(<Project|<Import|<Property|<?xml|xmlns)", RegexOption.IGNORE_CASE)

/**
 * Returns portion of a file content not exceeding the limit.
 */
const val HEURISTICS_CONSIDER_BYTES = 50 * 1024
fun toBuf(lines: List<String>) : String {
    var buf = ""
    for (line in lines) {
        buf += "$line\n"
        if (buf.length > HEURISTICS_CONSIDER_BYTES) {
            break
        }
    }
    return buf
}

/**
 * Heuristics to detect a programming language by file extension and content.
 * Inspired by GitHub Liguist heuristics (https://github.com/github/linguist).
 */
val Heuristics = mapOf<String, (List<String>) -> ExtractorInterface?>(
    "4TH" to { _ ->
        CommonExtractor("forth")
    },
    "as" to { lines ->
        if (ActionScriptRegex.matches(toBuf(lines))) CommonExtractor("actionscript")
        else CommonExtractor("angelscript")
    },
    "asm" to { _ ->
        CommonExtractor("assembly")
    },
    "bas" to { _ ->
        CommonExtractor("visualbasic")
    },
    "bat" to { _ ->
        CommonExtractor("dosbatch")
    },
    "bdy" to { _ ->
        CommonExtractor("plsql")
    },
    "c" to { _ ->
        CExtractor()
    },
    "cake" to { _ ->
        CSharpExtractor()
    },
    "cbl" to { _ ->
        CommonExtractor("cobol")
    },
    "cc" to { _ ->
        CppExtractor()
    },
    "cshtml" to { _ ->
        CSharpExtractor()
    },
    "csx" to { _ ->
        CSharpExtractor()
    },
    "clj" to { _ ->
        CommonExtractor("clojure")
    },
    "cljc" to { _ ->
        CommonExtractor("clojure")
    },
    "cljs" to { _ ->
        CommonExtractor("clojure")
    },
    "cob" to { _ ->
        CommonExtractor("cobol")
    },
    "coffee" to { _ ->
        CommonExtractor("coffeescript")
    },
    "cp" to { _ ->
        CppExtractor()
    },
    "cpp" to { _ ->
        CppExtractor()
    },
    "cpy" to { _ ->
        CommonExtractor("cobol")
    },
    "cql" to { _ ->
        CommonExtractor("sql")
    },
    "cs" to { lines ->
        val buf = toBuf(lines)
        if (Regex("![\\w\\s]+methodsFor: ").matches(buf)) CommonExtractor("smalltalk")
        else if (CSharpRegex.matches(buf)) CSharpExtractor()
        else null
    },
    "css" to { _ ->
        CssExtractor()
    },
    "cu" to { _ ->
        CommonExtractor("cuda")
    },
    "cuh" to { _ ->
        CommonExtractor("cuda")
    },
    "cxx" to { _ ->
        CppExtractor()
    },
    "c++" to { _ ->
        CppExtractor()
    },
    "d" to { lines ->
        val buf = toBuf(lines)
        if (DRegex.matches(buf)) CommonExtractor("d")
        else if (DTraceRegex.matches(buf)) CommonExtractor("dtrace")
        else if (MakefileRegex.matches(buf)) CommonExtractor("makefile")
        else null
    },
    "db2" to { _ ->
        CommonExtractor("sqlpl")
    },
    "ddl" to { lines ->
        val buf = toBuf(lines)
        if (PLSQLRegexs.any { re -> re.containsMatchIn(buf)})
            CommonExtractor("plsql")  // Oracle
        else if (!NotSQLRegex.containsMatchIn(buf))
            CommonExtractor("sql")  // Generic SQL
        else null
    },
    "edn" to { _ ->
        CommonExtractor("clojure")
    },
    "el" to { _ ->
        CommonExtractor("emacslisp")
    },
    "elc" to { _ ->
        CommonExtractor("emacslisp")
    },
    "elm" to { _ ->
        CommonExtractor("elm")
    },
    "erl" to { _ ->
        CommonExtractor("erlang")
    },
    "ex" to { _ ->
        CommonExtractor("elixir")
    },
    "exs" to { _ ->
        CommonExtractor("elixir")
    },
    "f" to { lines ->
        val buf = toBuf(lines)
        if (ForthRegex.matches(buf)) CommonExtractor("forth")
        else if (buf.contains("flowop")) CommonExtractor("filebench_wml")
        else if (FortranRegex.matches(buf)) CommonExtractor("fortran")
        else null
    },
    "f03" to { _ ->
        CommonExtractor("fortran")
    },
    "f08" to { _ ->
        CommonExtractor("fortran")
    },
    "f15" to { _ ->
        CommonExtractor("fortran")
    },
    "f90" to { _ ->
        CommonExtractor("fortran")
    },
    "f95" to { _ ->
        CommonExtractor("fortran")
    },
    "factor" to { _ ->
        CommonExtractor("factor")
    },
    "fnc" to { _ ->
        CommonExtractor("plsql")
    },
    "for" to { lines ->
        val buf = toBuf(lines)
        if (ForthRegex.matches(buf)) CommonExtractor("forth")
        else if (FortranRegex.matches(buf)) CommonExtractor("fortran")
        else null
    },
    "forth" to { _ ->
        CommonExtractor("forth")
    },
    "fs" to { lines ->
        val buf = toBuf(lines)
        if (Regex("^(: |new-device)").matches(buf)) CommonExtractor("forth")
        else if (FSharpRegex.matches(buf)) FSharpExtractor()
        else if (GLSLRegex.matches(buf)) CommonExtractor("GLSL")
        else if (Regex("#include|#pragma\\s+(rs|version)|__attribute__").matches(buf))
            CommonExtractor("filterscript")
        else null
    },
    "fsx" to { _ ->
        FSharpExtractor()
    },
    "go" to { _ ->
        GoExtractor()
    },
    "gradle" to { _ ->
        CommonExtractor("gradle")
    },
    "groovy" to { _ ->
        CommonExtractor("groovy")
    },
    "h" to { lines ->
        val buf = toBuf(lines)
        if (ObjectiveCRegex.matches(buf)) ObjectiveCExtractor()
        else CppExtractor()
    },
    "h++" to { _ ->
        CppExtractor()
    },
    "hh" to { _ ->
        CppExtractor()
    },
    "hpp" to { _ ->
        CppExtractor()
    },
    "htm" to { _ ->
        CommonExtractor("html")
    },
    "html" to { _ ->
        CommonExtractor("html")
    },
    "hs" to { _ ->
        CommonExtractor("haskell")
    },
    "hrl" to { _ ->
        CommonExtractor("erlang")
    },
    "hx" to { _ ->
        CommonExtractor("haxe")
    },
    "hxx" to { _ ->
        CppExtractor()
    },
    "hy" to { _ ->
        CommonExtractor("hy")
    },
    "ijs" to { _ ->
        CommonExtractor("j")
    },
    "inc" to { lines ->
        val buf = toBuf(lines)
        if (Regex("^<\\?(?:php)?").matches(buf)) PhpExtractor()
        else if (Regex("^\\s*#(declare|local|macro|while)\\s").matches(buf)) CommonExtractor("pov-ray_sdl")
        else null
    },
    "inl" to { _ ->
        CppExtractor()
    },
    "ino" to { _ ->
        CommonExtractor("arduino")
    },
    "java" to { _ ->
        JavaExtractor()
    },
    "jl" to { _ ->
        CommonExtractor("julia")
    },
    "js" to { _ ->
        JavascriptExtractor()
    },
    "jsx" to { _ ->
        JavascriptExtractor()
    },
    "kt" to { _ ->
        KotlinExtractor()
    },
    "l" to { lines ->
        val buf = toBuf(lines)
        if (Regex("\\(def(un|macro)\\s").matches(buf)) CommonExtractor("lisp")
        else if (Regex("^(%[%{}]xs|<.*>)").matches(buf)) CommonExtractor("lex")
        else if (Regex("^\\.[a-z][a-z](\\s|$)", RegexOption.IGNORE_CASE).matches(buf))
            CommonExtractor("roff")
        else if (Regex("^\\((de|class|rel|code|data|must)\\s").matches(buf))
            CommonExtractor("picolisp")
        else null
    },
    "less" to { _ ->
        CssExtractor()
    },
    "lhs" to { _ ->
        CommonExtractor("haskell")
    },
    "lisp" to { lines ->
        val buf = toBuf(lines)
        if (LispRegex.matches(buf)) CommonExtractor("lisp")
        else if (NewLispRegex.matches(buf)) CommonExtractor("newlisp")
        else null
    },
    "litcoffee" to { _ ->
        CommonExtractor("coffeescript")
    },
    "lsp" to { lines ->
        val buf = toBuf(lines)
        if (LispRegex.matches(buf)) CommonExtractor("lisp")
        else if (NewLispRegex.matches(buf)) CommonExtractor("newlisp")
        else null
    },
    "lua" to { _ ->
        CommonExtractor("lua")
    },
    "m" to { lines ->
        val buf = toBuf(lines)
        if (ObjectiveCRegex.matches(buf)) ObjectiveCExtractor()
        else if (buf.contains(":- module")) CommonExtractor("mercury")
        else if (Regex("^: ").matches(buf)) CommonExtractor("muf")
        else if (Regex("^\\s*;").matches(buf)) CommonExtractor("m")
        else if (Regex("\\*\\)$").matches(buf)) CommonExtractor("mathematica")
        else if (Regex("^\\s*%").matches(buf)) CommonExtractor("matlab")
        else if (Regex("^\\w+\\s*:\\s*module\\s*\\{").matches(buf)) CommonExtractor("limbo")
        else CommonExtractor("wolframlanguage")
    },
    "makefile" to { _ ->
        CommonExtractor("makefile")
    },
    "ml" to { lines ->
        val buf = toBuf(lines)
        if (Regex("(^\\s*module)|let rec |match\\s+(\\S+\\s)+with").matches(buf))
            CommonExtractor("ocaml")
        else if (Regex("=> |case\\s+(\\S+\\s)+of").matches(buf))
            CommonExtractor("standard_ml")
        else null
    },
    "mli" to { _ ->
        CommonExtractor("ocaml")
    },
    "mlx" to { _ ->
        CommonExtractor("matlab")
    },
    "mm" to { _ ->
        ObjectiveCExtractor()
    },
    "mysql" to { _ ->
        CommonExtractor("sql")
    },
    "nb" to { _ ->
        CommonExtractor("wolframlanguage")
    },
    "oxygene" to { _ ->
        CommonExtractor("oxygene")
    },
    "P" to { _ ->
        CommonExtractor("prolog")
    },
    "PL" to { _ ->
        CommonExtractor("perl")
    },
    "pas" to { _ ->
        CommonExtractor("pascal")
    },
    "pck" to { _ ->
        CommonExtractor("plsql")
    },
    "pde" to { _ ->
        CommonExtractor("processing")
    },
    "php" to { lines ->
        if (toBuf(lines).contains("<?hh")) CommonExtractor("hack")
        else PhpExtractor()
    },
    "phtml" to { _ ->
        PhpExtractor()
    },
    "php3" to { _ ->
        PhpExtractor()
    },
    "php4" to { _ ->
        PhpExtractor()
    },
    "php5" to { _ ->
        PhpExtractor()
    },
    "phps" to { _ ->
        PhpExtractor()
    },
    "pkb" to { _ ->
        CommonExtractor("plsql")
    },
    "pks" to { _ ->
        CommonExtractor("plsql")
    },
    "pl" to { lines ->
        val buf = toBuf(lines)
        if (Regex("^[^#]*:-").matches(buf)) CommonExtractor("prolog")
        else if (Perl5Regex.matches(buf)) CommonExtractor("perl")
        else if (Perl6Regex.matches(buf)) CommonExtractor("perl6")
        else null
    },
    "plb" to { _ ->
        CommonExtractor("plsql")
    },
    "pls" to { _ ->
        CommonExtractor("plsql")
    },
    "plsql" to { _ ->
        CommonExtractor("plsql")
    },
    "pm" to { lines ->
        val buf = toBuf(lines)
        if (Perl5Regex.matches(buf)) CommonExtractor("perl")
        else if (Perl6Regex.matches(buf)) CommonExtractor("perl6")
        else if (Regex("^\\s*\\/\\* XPM \\*\\/").matches(buf)) CommonExtractor("xpm")
        else null
    },
    "pom" to { _ ->
        CommonExtractor("maven")
    },
    "pp" to { _ ->
        CommonExtractor("puppet")
    },
    "prc" to { _ ->
        CommonExtractor("plsql")
    },
    "pro" to { lines ->
        val buf = toBuf(lines)
        if (Regex("^[^\\[#]+:-").matches(buf)) CommonExtractor("prolog")
        else if (buf.contains("last_client=")) CommonExtractor("ini")
        else if (buf.contains("HEADERS") || buf.contains("SOURCES")) CommonExtractor("qmake")
        else if (Regex("^\\s*function[ \\w,]+$").matches(buf)) CommonExtractor("idl")
        else null
    },
    "props" to { lines ->
        val buf = toBuf(lines)
        if (XMLPropsRegex.matches(buf)) CommonExtractor("xml")
        else if (Regex("\\w+\\s*=\\s*", RegexOption.IGNORE_CASE).matches(buf)) CommonExtractor("ini")
        else null
    },
    "ps1" to { _ ->
        CommonExtractor("powershell")
    },
    "psd1" to { _ ->
        CommonExtractor("powershell")
    },
    "psm1" to { _ ->
        CommonExtractor("powershell")
    },
    "py" to { _ ->
        PythonExtractor()
    },
    "py3" to { _ ->
        PythonExtractor()
    },
    "qml" to { _ ->
        CommonExtractor("qml")
    },
    "R" to { _ ->
        CommonExtractor("r")
    },
    "r" to { lines ->
        val buf = toBuf(lines)
        if (Regex("\\bRebol\\b").matches(buf)) CommonExtractor("eebol")
        else if (Regex("<-|^\\s*#").matches(buf)) CommonExtractor("r")
        else null
    },
    "rb" to { _ ->
        RubyExtractor()
    },
    "rbw" to { _ ->
        RubyExtractor()
    },
    "rpy" to { lines ->
        if (PythonRegex.matches(toBuf(lines))) CommonExtractor("python")
        else CommonExtractor("Ren'Py")
    },
    "rs" to { lines ->
        val buf = toBuf(lines)
        if (RustRegex.matches(buf)) CommonExtractor("rust")
        else if (RenderScriptRegex.matches(buf)) CommonExtractor("renderscript")
        else null
    },
    "S" to { _ ->
        CommonExtractor("assembly")
    },
    "s" to { _ ->
        CommonExtractor("assembly")
    },
    "sas" to { _ ->
        CommonExtractor("sas")
    },
    "sass" to { _ ->
        CssExtractor()
    },
    "sc" to { lines ->
        val buf = toBuf(lines)
        if (Regex("\\^(this|super)\\.").matches(buf) ||
            Regex("^\\s*(\\+|\\*)\\s*\\w+\\s*\\{").matches(buf) ||
            Regex("^\\s*~\\w+\\s*=\\.").matches(buf)) {
            CommonExtractor("supercollider")
        }
        else if (ScalaRegex.matches(buf)) CommonExtractor("scala")
        else null
    },
    "scala" to { _ ->
        CommonExtractor("scala")
    },
    "scm" to { _ ->
        CommonExtractor("scheme")
    },
    "scss" to { _ ->
        CssExtractor()
    },
    "sh" to { _ ->
        CommonExtractor("shell")
    },
    "spc" to { _ ->
        CommonExtractor("plsql")
    },
    "sql" to { lines ->
        val buf = toBuf(lines)
        if (Regex("^\\\\i\\b|AS \\$\\$|LANGUAGE '?plpgsql'?", RegexOption.IGNORE_CASE).containsMatchIn(buf) ||
            Regex("SECURITY (DEFINER|INVOKER)", RegexOption.IGNORE_CASE).containsMatchIn(buf) ||
            Regex("BEGIN( WORK| TRANSACTION)?;", RegexOption.IGNORE_CASE).containsMatchIn(buf))
            CommonExtractor("plpgsql")  // Postgres
        else if (Regex("(alter module)|(language sql)|(begin( NOT)+ atomic)", RegexOption.IGNORE_CASE).containsMatchIn(buf) ||
                 Regex("signal SQLSTATE '[0-9]+'", RegexOption.IGNORE_CASE).containsMatchIn(buf))
            CommonExtractor("sqlpl")  // IBM db2
        else if (PLSQLRegexs.any { re -> re.containsMatchIn(buf)})
            CommonExtractor("plsql")  // Oracle
        else CommonExtractor("sql")  // Generic SQL
    },
    "ss" to { _ ->
        CommonExtractor("scheme")
    },
    "st" to { _ ->
        CommonExtractor("smalltalk")
    },
    "swift" to { _ ->
        SwiftExtractor()
    },
    "tab" to { _ ->
        CommonExtractor("sql")
    },
    "tcl" to { _ ->
        CommonExtractor("tcl")
    },
    "tex" to { _ ->
        CommonExtractor("tex")
    },
    "tpb" to { _ ->
        CommonExtractor("plsql")
    },
    "tps" to { _ ->
        CommonExtractor("plsql")
    },
    "trg" to { _ ->
        CommonExtractor("plsql")
    },
    "ts" to { lines ->
        if (Regex("<TS\\b").matches(toBuf(lines))) CommonExtractor("xml")
        else CommonExtractor("typescript")
    },
    "tsx" to { lines ->
        val buf = toBuf(lines)
        if (Regex("^\\s*(import.+(from\\s+|require\\()['\"]react|\\/\\/\\/\\s*<reference\\s)").matches(buf))
            CommonExtractor("typescript")
        else if (Regex("^\\s*<\\?xml\\s+version", RegexOption.IGNORE_CASE).matches(buf))
            CommonExtractor("xml")
        else null
    },
    "udf" to { _ ->
        CommonExtractor("sql")
    },
    "v" to { _ ->
        CommonExtractor("verilog")
    },
    "vba" to { _ ->
        CommonExtractor("visualbasicforapps")
    },
    "vhdl" to { _ ->
        CommonExtractor("vhdl")
    },
    "vim" to { _ ->
        CommonExtractor("viml")
    },
    "viw" to { _ ->
        CommonExtractor("sql")
    },
    "vue" to { _ ->
        CommonExtractor("vue")
    },
    "vw" to { _ ->
        CommonExtractor("plsql")
    },
    "xtend" to { _ ->
        CommonExtractor("xtend")
    }
)
