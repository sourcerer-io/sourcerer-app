// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

val ActionScriptRegex = Regex(
    "^\\s*(package\\s+[a-z0-9_\\.]+|import\\s+[a-zA-Z0-9_\\.]+;|class\\s+[A-Za-z0-9_]+\\s+extends\\s+[A-Za-z0-9_]+)",
    RegexOption.MULTILINE
)
val CommonLispRegex = Regex(
    "^\\s*\\((defun|in-package|defpackage) ",
    setOf(RegexOption.MULTILINE, RegexOption.IGNORE_CASE)
)
val CPlusPlusRegex = Regex(
    "(template |class |namespace |#include <c?std[^.]+>)",
    RegexOption.MULTILINE
)
val DRegex = Regex(
    "^module\\s+[\\w.]*\\s*;|import\\s+[\\w\\s,.:]*;|\\w+\\s+\\w+\\s*\\(.*\\)(?:\\(.*\\))?\\s*\\{[^}]*\\}|unittest\\s*(?:\\(.*\\))?\\s*\\{[^}]*\\}",
    RegexOption.MULTILINE
)
val DTraceRegex = Regex(
    "^(\\w+:\\w*:\\w*:\\w*|BEGIN|END|provider\\s+|(tick|profile)-\\w+\\s+\\{[^}]*\\}|#pragma\\s+D\\s+(option|attributes|depends_on)\\s|#pragma\\s+ident\\s)",
    RegexOption.MULTILINE
)
val FilterscriptRegex = Regex(
    "#include|#pragma\\s+(rs|version)|__attribute__"
)
val FSharpRegex = Regex(
    "^\\s*(#light|import|let|module|namespace|open|type)",
    RegexOption.MULTILINE
)
val ForthRegex = Regex(
    "^: "
)
val ForthFsRegex = Regex(
    "^(: |new-device)"
)
val FortranRegex = Regex(
    "^([c*][^abd-z]|      (subroutine|program|end|data)\\s|\\s*!)",
    RegexOption.IGNORE_CASE
)
val GLSLRegex = Regex(
    "^\\s*(#version|precision|uniform|varying|vec[234])",
    RegexOption.IGNORE_CASE
)
val IDLRegex = Regex(
    "^\\s*function[ \\w,]+$",
    RegexOption.MULTILINE
)
val INIPropsRegex = Regex(
    "\\w+\\s*=\\s*",
    RegexOption.IGNORE_CASE
)
val LexRegex = Regex(
    "^(%[%{}]xs|<.*>)",
    RegexOption.MULTILINE
)
val LimboRegex = Regex(
    "^\\w+\\s*:\\s*module\\s*\\{",
    RegexOption.MULTILINE
)
val MathematicaRegex = Regex(
    "\\*\\)$",
    RegexOption.MULTILINE
)
val MatlabRegex = Regex(
    "^\\s*%",
    RegexOption.MULTILINE
)
val MRegexs = setOf(
    Regex(
        "^\\s*;",
        RegexOption.MULTILINE
    ),
    Regex(
        "^\\w+\\s;",
        RegexOption.MULTILINE
    )
)
val MakefileRegex = Regex(
    "([\\/\\\\].*:\\s+.*\\s\\\\$|: \\\\$|^ : |^[\\w\\s\\/\\\\.]+\\w+\\.\\w+\\s*:\\s+[\\w\\s\\/\\\\.]+\\w+\\.\\w+)"
)
val MUFRegex =Regex(
    "^: ",
    RegexOption.MULTILINE
)
val NewLispRegex = Regex(
    "^\\s*\\(define ",
    RegexOption.MULTILINE
)
val NotSQLRegex = Regex(
    "begin|boolean|package|exception",
    RegexOption.IGNORE_CASE
)
val ObjectiveCRegex = Regex(
    "^\\s*(@(interface|class|protocol|property|end|synchronised|selector|implementation)\\b|#import\\s+.+\\.h[\">])",
    RegexOption.MULTILINE
)
val OCamlRegex = Regex(
    "(^\\s*module)|let rec |match\\s+(\\S+\\s)+with",
    RegexOption.MULTILINE
)
val PascalRegex = Regex(
    "(^\\s*uses)|(function)|(program)",
    setOf(RegexOption.MULTILINE, RegexOption.IGNORE_CASE)
)
val Perl5Regex = Regex(
    "\\buse\\s+(?:strict\\b|v?5\\.)"
)
val Perl6Regex = Regex(
    "^\\s*(?:use\\s+v6\\b|\\bmodule\\b|\\b(?:my\\s+)?class\\b)",
    RegexOption.MULTILINE
)
val PHPRegex = Regex(
    "^<\\?(?:php)?"
)
val PicoLispRegex = Regex(
    "^\\((de|class|rel|code|data|must)\\s",
    RegexOption.MULTILINE
)
val PLpgSQLRegexs = setOf(
    Regex(
        "^\\\\i\\b|AS \\$\\$|LANGUAGE '?plpgsql'?",
        setOf(RegexOption.MULTILINE, RegexOption.IGNORE_CASE)
    ),
    Regex(
        "SECURITY (DEFINER|INVOKER)",
        RegexOption.IGNORE_CASE
    ),
    Regex(
        "BEGIN( WORK| TRANSACTION)?;",
        RegexOption.IGNORE_CASE
    )
)
val PLSQLRegexs = setOf(
    Regex(
        "\\\$\\\$PLSQL_|XMLTYPE|sysdate|systimestamp|\\.nextval|connect by|AUTHID (DEFINER|CURRENT_USER)",
        RegexOption.IGNORE_CASE
    ),
    Regex(
        "constructor\\W+function",
        RegexOption.IGNORE_CASE
    )
)
val POVRaySDLRegex = Regex(
    "^\\s*#(declare|local|macro|while)\\s", RegexOption.MULTILINE
)
val PrologRegex = Regex(
    "^[^#]*:-",
    RegexOption.MULTILINE
)
val PythonRegex = Regex(
    "(^(import|from|class|def)\\s)",
    RegexOption.MULTILINE
)
val RRegex = Regex(
    "<-|^\\s*#"
)
val RebolRegex = Regex(
    "\\bRebol\\b",
    RegexOption.IGNORE_CASE
)
val RoffRegex = Regex(
    "^\\.[a-z][a-z](\\s|$)",
    setOf(RegexOption.MULTILINE, RegexOption.IGNORE_CASE)
)
val RustRegex = Regex(
    "^(use |fn |mod |pub |macro_rules|impl|#!?\\[)",
    RegexOption.MULTILINE
)
val RenderScriptRegex = Regex(
    "#include|#pragma\\s+(rs|version)|__attribute__"
)
val ScalaRegex = Regex(
    "^\\s*import (scala|java)\\./.match(data) || /^\\s*val\\s+\\w+\\s*=/.match(data) || /^\\s*class\\b",
    RegexOption.MULTILINE
)
val SmalltalkRegex = Regex(
    "![\\w\\s]+methodsFor: "
)
val SQLPLRegexs = setOf(
    Regex(
        "(alter module)|(language sql)|(begin( NOT)+ atomic)",
        RegexOption.IGNORE_CASE
    ),
    Regex(
        "signal SQLSTATE '[0-9]+'",
        RegexOption.IGNORE_CASE
    )
)
val StandardMLRegex = Regex(
    "=> |case\\s+(\\S+\\s)+of"
)
val SuperColliderRegexs = setOf(
    Regex("\\^(this|super)\\."),
    Regex("^\\s*(\\+|\\*)\\s*\\w+\\s*\\{", RegexOption.MULTILINE),
    Regex("^\\s*~\\w+\\s*=\\.", RegexOption.MULTILINE)
)
val TeXRegex = Regex(
    "\\\\\\w+\\{"
)
val TypeScriptRegex = Regex(
    "^\\s*(import.+(from\\s+|require\\()['\"]react|\\/\\/\\/\\s*<reference\\s)",
    RegexOption.MULTILINE
)
val XMLPropsRegex = Regex(
    "^(\\s*)(<Project|<Import|<Property|<?xml|xmlns)",
    setOf(RegexOption.MULTILINE, RegexOption.IGNORE_CASE)
)
val XMLTsRegex = Regex(
    "<TS\\b"
)
val XMLTsxRegex = Regex(
    "^\\s*<\\?xml\\s+version",
    setOf(RegexOption.MULTILINE, RegexOption.IGNORE_CASE)
)
val XPMRegex = Regex(
    "^\\s*\\/\\* XPM \\*\\/",
    RegexOption.MULTILINE
)

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
    "4" to { _ ->
        CommonExtractor(Lang.Roff)
    },
    "4th" to { _ ->
        CommonExtractor(Lang.Forth)
    },
    "a51" to { _ ->
        CommonExtractor(Lang.Assembly)
    },
    "al" to { _ ->
        CommonExtractor(Lang.Perl)
    },
    "as" to { lines ->
        if (ActionScriptRegex.containsMatchIn(toBuf(lines))) CommonExtractor(Lang.ActionScript)
        else CommonExtractor(Lang.AngelScript)
    },
    "asm" to { _ ->
        CommonExtractor(Lang.Assembly)
    },
    "b" to { _ ->
        CommonExtractor(Lang.Limbo)
    },
    "bas" to { _ ->
        CommonExtractor(Lang.VisualBasic)
    },
    "bat" to { _ ->
        CommonExtractor(Lang.DOSBatch)
    },
    "bbx" to { _ ->
        CommonExtractor(Lang.TeX)
    },
    "bdy" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "boot" to { _ ->
        CommonExtractor(Lang.Clojure)
    },
    "c" to { _ ->
        CExtractor()
    },
    "cake" to { _ ->
        CSharpExtractor()
    },
    "cbl" to { _ ->
        CommonExtractor(Lang.COBOL)
    },
    "cbx" to { _ ->
        CommonExtractor(Lang.TeX)
    },
    "cc" to { _ ->
        CppExtractor()
    },
    "cgi" to { lines ->
        val buf = toBuf(lines)
        if (Perl5Regex.containsMatchIn(buf)) CommonExtractor(Lang.Perl)
        else null
    },
    "cl" to { _ ->
        CommonExtractor(Lang.CommonLisp)
    },
    "cl2" to { _ ->
        CommonExtractor(Lang.Clojure)
    },
    "clj" to { _ ->
        CommonExtractor(Lang.Clojure)
    },
    "cljc" to { _ ->
        CommonExtractor(Lang.Clojure)
    },
    "cljscm" to { _ ->
        CommonExtractor(Lang.Clojure)
    },
    "cljs" to { _ ->
        CommonExtractor(Lang.Clojure)
    },
    "cljx" to { _ ->
        CommonExtractor(Lang.Clojure)
    },
    "cls" to { lines ->
        val buf = toBuf(lines)
        if (TeXRegex.containsMatchIn(buf)) CommonExtractor(Lang.TeX)
        else CommonExtractor(Lang.VisualBasic)
    },
    "cob" to { _ ->
        CommonExtractor(Lang.COBOL)
    },
    "coffee" to { _ ->
        CommonExtractor(Lang.CoffeeScript)
    },
    "cp" to { _ ->
        CppExtractor()
    },
    "cpp" to { _ ->
        CppExtractor()
    },
    "cpy" to { _ ->
        CommonExtractor(Lang.COBOL)
    },
    "cql" to { _ ->
        CommonExtractor(Lang.SQL)
    },
    "cs" to { lines ->
        val buf = toBuf(lines)
        if (SmalltalkRegex.containsMatchIn(buf)) CommonExtractor(Lang.Smalltalk)
        else CSharpExtractor()
    },
    "cshtml" to { _ ->
        CSharpExtractor()
    },
    "css" to { _ ->
        CssExtractor()
    },
    "csx" to { _ ->
        CSharpExtractor()
    },
    "cu" to { _ ->
        CommonExtractor(Lang.Cuda)
    },
    "cuh" to { _ ->
        CommonExtractor(Lang.Cuda)
    },
    "cxx" to { _ ->
        CppExtractor()
    },
    "c++" to { _ ->
        CppExtractor()
    },
    "d" to { lines ->
        val buf = toBuf(lines)
        if (DRegex.containsMatchIn(buf)) CommonExtractor(Lang.D)
        else if (DTraceRegex.containsMatchIn(buf)) CommonExtractor(Lang.DTrace)
        else if (MakefileRegex.containsMatchIn(buf)) CommonExtractor(Lang.Makefile)
        else null
    },
    "db2" to { _ ->
        CommonExtractor(Lang.SQLPL)
    },
    "ddl" to { lines ->
        val buf = toBuf(lines)
        if (PLSQLRegexs.any { re -> re.containsMatchIn(buf)}) CommonExtractor(Lang.PLSQL)  // Oracle
        else if (!NotSQLRegex.containsMatchIn(buf)) CommonExtractor(Lang.SQL)  // Generic SQL
        else null
    },
    "dlm" to { _ ->
        CommonExtractor(Lang.IDL)
    },
    "dpr" to { _ ->
        CommonExtractor(Lang.Pascal)
    },
    "edn" to { _ ->
        CommonExtractor(Lang.Clojure)
    },
    "el" to { _ ->
        CommonExtractor(Lang.EmacsLisp)
    },
    "elc" to { _ ->
        CommonExtractor(Lang.EmacsLisp)
    },
    "eliom" to { _ ->
        CommonExtractor(Lang.OCaml)
    },
    "elm" to { _ ->
        CommonExtractor(Lang.Elm)
    },
    "erl" to { _ ->
        CommonExtractor(Lang.Erlang)
    },
    "ex" to { _ ->
        CommonExtractor(Lang.Elixir)
    },
    "exs" to { _ ->
        CommonExtractor(Lang.Elixir)
    },
    "f" to { lines ->
        val buf = toBuf(lines)
        if (ForthRegex.containsMatchIn(buf)) CommonExtractor(Lang.Forth)
        else if (buf.contains("flowop")) CommonExtractor(Lang.FilebenchWML)
        else if (FortranRegex.containsMatchIn(buf)) CommonExtractor(Lang.Fortran)
        else null
    },
    "f03" to { _ ->
        CommonExtractor(Lang.Fortran)
    },
    "f08" to { _ ->
        CommonExtractor(Lang.Fortran)
    },
    "f15" to { _ ->
        CommonExtractor(Lang.Fortran)
    },
    "f90" to { _ ->
        CommonExtractor(Lang.Fortran)
    },
    "f95" to { _ ->
        CommonExtractor(Lang.Fortran)
    },
    "factor" to { _ ->
        CommonExtractor(Lang.Factor)
    },
    "fcgi" to { lines ->
        val buf = toBuf(lines)
        if (Perl5Regex.containsMatchIn(buf)) CommonExtractor(Lang.Perl)
        else CommonExtractor(Lang.Lua)
    },
    "fnc" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "for" to { lines ->
        val buf = toBuf(lines)
        if (ForthRegex.containsMatchIn(buf)) CommonExtractor(Lang.Forth)
        else if (FortranRegex.containsMatchIn(buf)) CommonExtractor(Lang.Fortran)
        else null
    },
    "forth" to { _ ->
        CommonExtractor(Lang.Forth)
    },
    "fp" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "fr" to { _ ->
        CommonExtractor(Lang.Forth)
    },
    "frag" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "frg" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "frt" to { _ ->
        CommonExtractor(Lang.Forth)
    },
    "fs" to { lines ->
        val buf = toBuf(lines)
        if (ForthFsRegex.containsMatchIn(buf)) CommonExtractor(Lang.Forth)
        else if (FSharpRegex.containsMatchIn(buf)) FSharpExtractor()
        else if (GLSLRegex.containsMatchIn(buf)) CommonExtractor(Lang.GLSL)
        else if (FilterscriptRegex.containsMatchIn(buf)) CommonExtractor(Lang.Filterscript)
        else null
    },
    "fsh" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "fsx" to { _ ->
        FSharpExtractor()
    },
    "fth" to { _ ->
        CommonExtractor(Lang.Forth)
    },
    "fxml" to { _ ->
        CommonExtractor(Lang.XML)
    },
    "glsl" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "go" to { _ ->
        GoExtractor()
    },
    "gradle" to { _ ->
        CommonExtractor(Lang.Gradle)
    },
    "groovy" to { _ ->
        CommonExtractor(Lang.Groovy)
    },
    "h" to { lines ->
        val buf = toBuf(lines)
        if (ObjectiveCRegex.containsMatchIn(buf)) ObjectiveCExtractor()
        else if (CPlusPlusRegex.containsMatchIn(buf)) CppExtractor()
        else CExtractor()
    },
    "h++" to { _ ->
        CppExtractor()
    },
    "hh" to { _ ->
        CppExtractor()
    },
    "hic" to { _ ->
        CommonExtractor(Lang.Clojure)
    },
    "hl" to { _ ->
        CommonExtractor(Lang.Clojure)
    },
    "hpp" to { _ ->
        CppExtractor()
    },
    "htm" to { _ ->
        CommonExtractor(Lang.HTML)
    },
    "html" to { _ ->
        CommonExtractor(Lang.HTML)
    },
    "hs" to { _ ->
        CommonExtractor(Lang.Haskell)
    },
    "hrl" to { _ ->
        CommonExtractor(Lang.Erlang)
    },
    "hx" to { _ ->
        CommonExtractor(Lang.Haxe)
    },
    "hxx" to { _ ->
        CppExtractor()
    },
    "hy" to { _ ->
        CommonExtractor(Lang.Hy)
    },
    "ijs" to { _ ->
        CommonExtractor(Lang.J)
    },
    "inc" to { lines ->
        val buf = toBuf(lines)
        if (PHPRegex.containsMatchIn(buf)) PhpExtractor()
        else if (POVRaySDLRegex.containsMatchIn(buf)) CommonExtractor(Lang.POVRaySDL)
        else if (PascalRegex.containsMatchIn(buf)) CommonExtractor(Lang.Pascal)
        else CommonExtractor(Lang.Assembly)
    },
    "inl" to { _ ->
        CppExtractor()
    },
    "ino" to { _ ->
        CommonExtractor(Lang.Arduino)
    },
    "java" to { _ ->
        JavaExtractor()
    },
    "jl" to { _ ->
        CommonExtractor(Lang.Julia)
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
    "kojo" to { _ ->
        CommonExtractor(Lang.Scala)
    },
    "l" to { lines ->
        val buf = toBuf(lines)
        if (CommonLispRegex.containsMatchIn(buf)) CommonExtractor(Lang.CommonLisp)
        else if (LexRegex.containsMatchIn(buf)) CommonExtractor(Lang.Lex)
        else if (RoffRegex.containsMatchIn(buf)) CommonExtractor(Lang.Roff)
        else if (PicoLispRegex.containsMatchIn(buf)) CommonExtractor(Lang.PicoLisp)
        else null
    },
    "lbx" to { _ ->
        CommonExtractor(Lang.TeX)
    },
    "less" to { _ ->
        CssExtractor()
    },
    "lhs" to { _ ->
        CommonExtractor(Lang.Haskell)
    },
    "lisp" to { lines ->
        val buf = toBuf(lines)
        if (CommonLispRegex.containsMatchIn(buf)) CommonExtractor(Lang.CommonLisp)
        else if (NewLispRegex.containsMatchIn(buf)) CommonExtractor(Lang.NewLisp)
        else null
    },
    "litcoffee" to { _ ->
        CommonExtractor(Lang.CoffeeScript)
    },
    "lsp" to { lines ->
        val buf = toBuf(lines)
        if (CommonLispRegex.containsMatchIn(buf)) CommonExtractor(Lang.CommonLisp)
        else if (NewLispRegex.containsMatchIn(buf)) CommonExtractor(Lang.NewLisp)
        else null
    },
    "lua" to { _ ->
        CommonExtractor(Lang.Lua)
    },
    "m" to { lines ->
        val buf = toBuf(lines)
        if (ObjectiveCRegex.containsMatchIn(buf)) ObjectiveCExtractor()
        else if (buf.contains(":- module")) CommonExtractor(Lang.Mercury)
        else if (MUFRegex.containsMatchIn(buf)) CommonExtractor(Lang.MUF)
        else if (MRegexs.any { re -> re.containsMatchIn(buf)}) CommonExtractor(Lang.M)
        else if (MathematicaRegex.containsMatchIn(buf)) CommonExtractor(Lang.Mathematica)
        else if (MatlabRegex.containsMatchIn(buf)) CommonExtractor(Lang.Matlab)
        else if (LimboRegex.containsMatchIn(buf)) CommonExtractor(Lang.Limbo)
        else CommonExtractor(Lang.WolframLanguage)
    },
    "make" to { _ ->
        CommonExtractor(Lang.Makefile)
    },
    "makefile" to { _ ->
        CommonExtractor(Lang.Makefile)
    },
    "mjml" to { _ ->
        CommonExtractor(Lang.XML)
    },
    "ml" to { lines ->
        val buf = toBuf(lines)
        if (OCamlRegex.containsMatchIn(buf)) CommonExtractor(Lang.OCaml)
        else if (StandardMLRegex.containsMatchIn(buf)) CommonExtractor(Lang.StandardML)
        else null
    },
    "mli" to { _ ->
        CommonExtractor(Lang.OCaml)
    },
    "mlx" to { _ ->
        CommonExtractor(Lang.Matlab)
    },
    "mm" to { _ ->
        ObjectiveCExtractor()
    },
    "ms" to { _ ->
        CommonExtractor(Lang.Roff)
    },
    "mt" to { _ ->
        CommonExtractor(Lang.Mathematica)
    },
    "muf" to { _ ->
        CommonExtractor(Lang.MUF)
    },
    "mysql" to { _ ->
        CommonExtractor(Lang.SQL)
    },
    "n" to { _ ->
        CommonExtractor(Lang.Roff)
    },
    "nasm" to { _ ->
        CommonExtractor(Lang.Assembly)
    },
    "nb" to { lines ->
        val buf = toBuf(lines)
        if (MathematicaRegex.containsMatchIn(buf)) CommonExtractor(Lang.Mathematica)
        else CommonExtractor(Lang.WolframLanguage)
    },
    "nl" to { _ ->
        CommonExtractor(Lang.NewLisp)
    },
    "nr" to { _ ->
        CommonExtractor(Lang.Roff)
    },
    "oxygene" to { _ ->
        CommonExtractor(Lang.Oxygene)
    },
    "P" to { _ ->
        CommonExtractor(Lang.Prolog)
    },
    "p6" to { _ ->
        CommonExtractor(Lang.Perl6)
    },
    "p8" to { _ ->
        CommonExtractor(Lang.Lua)
    },
    "pas" to { _ ->
        CommonExtractor(Lang.Pascal)
    },
    "pascal" to { _ ->
        CommonExtractor(Lang.Pascal)
    },
    "pck" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "pd_lua" to { _ ->
        CommonExtractor(Lang.Lua)
    },
    "pde" to { _ ->
        CommonExtractor(Lang.Processing)
    },
    "php" to { lines ->
        if (toBuf(lines).contains("<?hh")) CommonExtractor(Lang.Hack)
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
        CommonExtractor(Lang.PLSQL)
    },
    "pks" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "pl" to { lines ->
        val buf = toBuf(lines)
        if (PrologRegex.containsMatchIn(buf)) CommonExtractor(Lang.Prolog)
        else if (Perl6Regex.containsMatchIn(buf)) CommonExtractor(Lang.Perl6)
        else CommonExtractor(Lang.Perl)
    },
    "plb" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "pls" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "plsql" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "pm" to { lines ->
        val buf = toBuf(lines)
        if (Perl5Regex.containsMatchIn(buf)) CommonExtractor(Lang.Perl)
        else if (Perl6Regex.containsMatchIn(buf)) CommonExtractor(Lang.Perl6)
        else if (XPMRegex.containsMatchIn(buf)) CommonExtractor(Lang.XPM)
        else null
    },
    "pm6" to { _ ->
        CommonExtractor(Lang.Perl6)
    },
    "pom" to { _ ->
        CommonExtractor(Lang.MavenPOM)
    },
    "pov" to { _ ->
        CommonExtractor(Lang.POVRaySDL)
    },
    "pp" to { lines ->
        val buf = toBuf(lines)
        if (PascalRegex.containsMatchIn(buf)) CommonExtractor(Lang.Pascal)
        else CommonExtractor(Lang.Puppet)
    },
    "prc" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "pro" to { lines ->
        val buf = toBuf(lines)
        if (PrologRegex.containsMatchIn(buf)) CommonExtractor(Lang.Prolog)
        else if (buf.contains("last_client=")) CommonExtractor(Lang.INI)
        else if (buf.contains("HEADERS") || buf.contains("SOURCES")) CommonExtractor(Lang.QMake)
        else if (IDLRegex.containsMatchIn(buf)) CommonExtractor(Lang.IDL)
        else null
    },
    "prolog" to { _ ->
        CommonExtractor(Lang.Prolog)
    },
    "props" to { lines ->
        val buf = toBuf(lines)
        if (XMLPropsRegex.containsMatchIn(buf)) CommonExtractor(Lang.XML)
        else if (INIPropsRegex.containsMatchIn(buf)) CommonExtractor(Lang.INI)
        else null
    },
    "ps1" to { _ ->
        CommonExtractor(Lang.PowerShell)
    },
    "psd1" to { _ ->
        CommonExtractor(Lang.PowerShell)
    },
    "psm1" to { _ ->
        CommonExtractor(Lang.PowerShell)
    },
    "py" to { _ ->
        PythonExtractor()
    },
    "py3" to { _ ->
        PythonExtractor()
    },
    "qml" to { _ ->
        CommonExtractor(Lang.QML)
    },
    "r" to { lines ->
        val buf = toBuf(lines)
        if (RebolRegex.containsMatchIn(buf)) CommonExtractor(Lang.Rebol)
        else if (RRegex.containsMatchIn(buf)) CommonExtractor(Lang.R)
        else null
    },
    "r2" to { _ ->
        CommonExtractor(Lang.Rebol)
    },
    "r3" to { _ ->
        CommonExtractor(Lang.Rebol)
    },
    "rb" to { _ ->
        RubyExtractor()
    },
    "rbw" to { _ ->
        RubyExtractor()
    },
    "rd" to { _ ->
        CommonExtractor(Lang.R)
    },
    "reb" to { _ ->
        CommonExtractor(Lang.Rebol)
    },
    "rebol" to { _ ->
        CommonExtractor(Lang.Rebol)
    },
    "rno" to { _ ->
        CommonExtractor(Lang.Roff)
    },
    "rpy" to { lines ->
        if (PythonRegex.containsMatchIn(toBuf(lines))) PythonExtractor()
        else CommonExtractor(Lang.RenPy)
    },
    "rs" to { lines ->
        val buf = toBuf(lines)
        if (RustRegex.containsMatchIn(buf)) CommonExtractor(Lang.Rust)
        else if (RenderScriptRegex.containsMatchIn(buf)) CommonExtractor(Lang.RenderScript)
        else null
    },
    "rsh" to { _ ->
        CommonExtractor(Lang.RenderScript)
    },
    "rsx" to { _ ->
        CommonExtractor(Lang.R)
    },
    "s" to { _ ->
        CommonExtractor(Lang.Assembly)
    },
    "sas" to { _ ->
        CommonExtractor(Lang.SAS)
    },
    "sass" to { _ ->
        CssExtractor()
    },
    "sbt" to { _ ->
        CommonExtractor(Lang.Scala)
    },
    "sc" to { lines ->
        val buf = toBuf(lines)
        if (SuperColliderRegexs.any { re -> re.containsMatchIn(buf) }) CommonExtractor(Lang.SuperCollider)
        else if (ScalaRegex.containsMatchIn(buf)) CommonExtractor(Lang.Scala)
        else null
    },
    "scala" to { _ ->
        CommonExtractor(Lang.Scala)
    },
    "scd" to { _ ->
        CommonExtractor(Lang.SuperCollider)
    },
    "sch" to { _ ->
        CommonExtractor(Lang.Scheme)
    },
    "scm" to { _ ->
        CommonExtractor(Lang.Scheme)
    },
    "scss" to { _ ->
        CssExtractor()
    },
    "sexp" to { _ ->
        CommonExtractor(Lang.CommonLisp)
    },
    "sh" to { _ ->
        CommonExtractor(Lang.Shell)
    },
    "shader" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "sld" to { _ ->
        CommonExtractor(Lang.Scheme)
    },
    "sls" to { _ ->
        CommonExtractor(Lang.Scheme)
    },
    "spc" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "sps" to { _ ->
        CommonExtractor(Lang.Scheme)
    },
    "sql" to { lines ->
        val buf = toBuf(lines)
        if (PLpgSQLRegexs.any { re -> re.containsMatchIn(buf)}) CommonExtractor(Lang.PLpgSQL)  // Postgress
        else if (SQLPLRegexs.any { re -> re.containsMatchIn(buf)}) CommonExtractor(Lang.SQLPL)  // IDB db2
        else if (PLSQLRegexs.any { re -> re.containsMatchIn(buf)}) CommonExtractor(Lang.PLSQL)  // Oracle
        else CommonExtractor(Lang.SQL)  // Generic SQL
    },
    "ss" to { _ ->
        CommonExtractor(Lang.Scheme)
    },
    "st" to { _ ->
        CommonExtractor(Lang.Smalltalk)
    },
    "swift" to { _ ->
        SwiftExtractor()
    },
    "t" to { lines ->
        val buf = toBuf(lines)
        if (Perl6Regex.containsMatchIn(buf)) CommonExtractor(Lang.Perl6)
        else CommonExtractor(Lang.Perl)
    },
    "tab" to { _ ->
        CommonExtractor(Lang.SQL)
    },
    "tcl" to { _ ->
        CommonExtractor(Lang.Tcl)
    },
    "tesc" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "tese" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "tex" to { _ ->
        CommonExtractor(Lang.TeX)
    },
    "tmac" to { _ ->
        CommonExtractor(Lang.Roff)
    },
    "toc" to { _ ->
        CommonExtractor(Lang.TeX)
    },
    "tpb" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "tps" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "trg" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "ts" to { lines ->
        if (XMLTsRegex.containsMatchIn(toBuf(lines))) CommonExtractor(Lang.XML)
        else CommonExtractor(Lang.TypeScript)
    },
    "tsx" to { lines ->
        val buf = toBuf(lines)
        if (TypeScriptRegex.containsMatchIn(buf)) CommonExtractor(Lang.TypeScript)
        else if (XMLTsxRegex.containsMatchIn(buf)) CommonExtractor(Lang.XML)
        else null
    },
    "udf" to { _ ->
        CommonExtractor(Lang.SQL)
    },
    "ux" to { _ ->
        CommonExtractor(Lang.XML)
    },
    "v" to { _ ->
        CommonExtractor(Lang.Verilog)
    },
    "vb" to { _ ->
        CommonExtractor(Lang.VisualBasic)
    },
    "vba" to { _ ->
        CommonExtractor(Lang.VisualBasicForApps)
    },
    "vhdl" to { _ ->
        CommonExtractor(Lang.VHDL)
    },
    "vbhtml" to { _ ->
        CommonExtractor(Lang.VisualBasic)
    },
    "vim" to { _ ->
        CommonExtractor(Lang.VimL)
    },
    "viw" to { _ ->
        CommonExtractor(Lang.SQL)
    },
    "vrx" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "vsh" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "vue" to { _ ->
        CommonExtractor(Lang.Vue)
    },
    "vw" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "wl" to { _ ->
        CommonExtractor(Lang.Mathematica)
    },
    "wlt" to { _ ->
        CommonExtractor(Lang.Mathematica)
    },
    "xml" to { _ ->
        CommonExtractor(Lang.XML)
    },
    "xpm" to { _ ->
        CommonExtractor(Lang.XPM)
    },
    "xtend" to { _ ->
        CommonExtractor(Lang.Xtend)
    },
    "yap" to { _ ->
        CommonExtractor(Lang.Prolog)
    }
)
