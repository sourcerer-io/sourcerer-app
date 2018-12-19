// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.extractors

import app.model.DiffFile
import app.model.CommitStats

val ActionscriptRegex = Regex(
    "^\\s*(package\\s+[a-z0-9_\\.]+|import\\s+[a-zA-Z0-9_\\.]+;|class\\s+[A-Za-z0-9_]+\\s+extends\\s+[A-Za-z0-9_]+)",
    RegexOption.MULTILINE
)
val CoqRegex = Regex(
    """^Require\s""",
    RegexOption.MULTILINE
)
val CommonLispRegex = Regex(
    "^\\s*\\((defun|in-package|defpackage) ",
    setOf(RegexOption.MULTILINE, RegexOption.IGNORE_CASE)
)
val CppRegex = Regex(
    "(template |class |namespace |#include <c?std[^.]+>)",
    RegexOption.MULTILINE
)
val DRegex = Regex(
    "^module\\s+[\\w.]*\\s*;|import\\s+[\\w\\s,.:]*;|\\w+\\s+\\w+\\s*\\(.*\\)(?:\\(.*\\))?\\s*\\{[^}]*\\}|unittest\\s*(?:\\(.*\\))?\\s*\\{[^}]*\\}",
    RegexOption.MULTILINE
)
val DtraceRegex = Regex(
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
val GlslRegex = Regex(
    "^\\s*(#version|precision|uniform|varying|vec[234])",
    RegexOption.IGNORE_CASE
)
val IdlRegex = Regex(
    "^\\s*function[ \\w,]+$",
    RegexOption.MULTILINE
)
val IniPropsRegex = Regex(
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
    """(^\s*%)|(^end$)""",
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
val MufRegex =Regex(
    "^: ",
    RegexOption.MULTILINE
)
val NewLispRegex = Regex(
    "^\\s*\\(define ",
    RegexOption.MULTILINE
)
val NotSqlRegex = Regex(
    "begin|boolean|package|exception",
    RegexOption.IGNORE_CASE
)
val ObjectiveCRegex = Regex(
    "^\\s*(@(interface|class|protocol|property|end|synchronised|selector|implementation)\\b|#import\\s+.+\\.h[\">])",
    RegexOption.MULTILINE
)
val OcamlRegex = Regex(
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
val PhpRegex = Regex(
    "^<\\?(?:php)?"
)
val PicoLispRegex = Regex(
    "^\\((de|class|rel|code|data|must)\\s",
    RegexOption.MULTILINE
)
val PlpgsqlRegexs = setOf(
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
val PlsqlRegexs = setOf(
    Regex(
        "\\\$\\\$PLSQL_|XMLTYPE|sysdate|systimestamp|\\.nextval|connect by|AUTHID (DEFINER|CURRENT_USER)",
        RegexOption.IGNORE_CASE
    ),
    Regex(
        "constructor\\W+function",
        RegexOption.IGNORE_CASE
    )
)
val PovRaySdlRegex = Regex(
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
val RenderscriptRegex = Regex(
    "#include|#pragma\\s+(rs|version)|__attribute__"
)
val ScalaRegex = Regex(
    "^\\s*import (scala|java)\\./.match(data) || /^\\s*val\\s+\\w+\\s*=/.match(data) || /^\\s*class\\b",
    RegexOption.MULTILINE
)
val SmalltalkRegex = Regex(
    "![\\w\\s]+methodsFor: "
)
val SqlplRegexs = setOf(
    Regex(
        "(alter module)|(language sql)|(begin( NOT)+ atomic)",
        RegexOption.IGNORE_CASE
    ),
    Regex(
        "signal SQLSTATE '[0-9]+'",
        RegexOption.IGNORE_CASE
    )
)
val StandardMlRegex = Regex(
    "=> |case\\s+(\\S+\\s)+of"
)
val SupercolliderRegexs = setOf(
    Regex("\\^(this|super)\\."),
    Regex("^\\s*(\\+|\\*)\\s*\\w+\\s*\\{", RegexOption.MULTILINE),
    Regex("^\\s*~\\w+\\s*=\\.", RegexOption.MULTILINE)
)
val TexRegex = Regex(
    "\\\\\\w+\\{"
)
val TypescriptRegex = Regex(
    "^\\s*(import.+(from\\s+|require\\()['\"]react|\\/\\/\\/\\s*<reference\\s)",
    RegexOption.MULTILINE
)
val XmlPropsRegex = Regex(
    "^(\\s*)(<Project|<Import|<Property|<?xml|xmlns)",
    setOf(RegexOption.MULTILINE, RegexOption.IGNORE_CASE)
)
val XmltsRegex = Regex(
    "<TS\\b"
)
// Mystical \uFEFF 'ZERO WIDTH NO-BREAK SPACE' unicode character may appear
// in beginning of files.
val XmlRegex = Regex(
    "^\\uFEFF?\\s*<\\?xml\\s+version",
    setOf(RegexOption.MULTILINE, RegexOption.IGNORE_CASE)
)
val XpmRegex = Regex(
    "^\\s*\\/\\* XPM \\*\\/",
    RegexOption.MULTILINE
)

/**
 * Heuristics to detect a programming language by file extension and content.
 * Inspired by GitHub Liguist heuristics (https://github.com/github/linguist).
 */
object Heuristics
{
    /**
     * Returns a list of language commit stats extracted from the given file.
     */
    fun analyze(file: DiffFile) : List<CommitStats>? {
        val buf = toBuf(file.new.content)
        var extractor: ExtractorInterface? = null

        // Look for an extractor by a file extension. If failed, then fallback
        // to generic content analysis.
        val extractorFactory = HeuristicsMap[file.extension]
        if (extractorFactory != null) {
            extractor = extractorFactory(buf)
        } else {
            if (XmlRegex.containsMatchIn(buf)) {
                extractor = CommonExtractor(Lang.XML)
            }
        }

        return extractor?.extract(listOf(file))
    }

    /**
     * Returns a portion of the file content not exceeding the limit.
     */
    private const val HEURISTICS_CONSIDER_BYTES = 50 * 1024
    private fun toBuf(lines: List<String>) : String {
        var buf = ""
        for (line in lines) {
            buf += "$line\n"
            if (buf.length > HEURISTICS_CONSIDER_BYTES) {
                break
            }
        }
        return buf
    }
}

/**
 * A map of file extensions to language extracters.
 */
val HeuristicsMap = mapOf<String, (String) -> ExtractorInterface?>(
    "4" to { _ ->
        CommonExtractor(Lang.ROFF)
    },
    "4th" to { _ ->
        CommonExtractor(Lang.FORTH)
    },
    "a51" to { _ ->
        CommonExtractor(Lang.ASSEMBLY)
    },
    "al" to { _ ->
        CommonExtractor(Lang.PERL)
    },
    "as" to { buf ->
        if (ActionscriptRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.ACTIONSCRIPT)
        } else CommonExtractor(Lang.ANGELSCRIPT)
    },
    "asm" to { _ ->
        CommonExtractor(Lang.ASSEMBLY)
    },
    "b" to { _ ->
        CommonExtractor(Lang.LIMBO)
    },
    "bas" to { _ ->
        CommonExtractor(Lang.VISUALBASIC)
    },
    "bat" to { _ ->
        CommonExtractor(Lang.DOSBATCH)
    },
    "bbx" to { _ ->
        CommonExtractor(Lang.TEX)
    },
    "bdy" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "boot" to { _ ->
        CommonExtractor(Lang.CLOJURE)
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
        CommonExtractor(Lang.TEX)
    },
    "cc" to { _ ->
        CppExtractor()
    },
    "cgi" to { buf ->
        if (Perl5Regex.containsMatchIn(buf)) {
            CommonExtractor(Lang.PERL)
        } else null
    },
    "cl" to { _ ->
        CommonExtractor(Lang.COMMONLISP)
    },
    "cl2" to { _ ->
        CommonExtractor(Lang.CLOJURE)
    },
    "clj" to { _ ->
        CommonExtractor(Lang.CLOJURE)
    },
    "cljc" to { _ ->
        CommonExtractor(Lang.CLOJURE)
    },
    "cljscm" to { _ ->
        CommonExtractor(Lang.CLOJURE)
    },
    "cljs" to { _ ->
        CommonExtractor(Lang.CLOJURE)
    },
    "cljx" to { _ ->
        CommonExtractor(Lang.CLOJURE)
    },
    "cls" to { buf ->
        if (TexRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.TEX)
        } else {
            CommonExtractor(Lang.VISUALBASIC)
        }
    },
    "cob" to { _ ->
        CommonExtractor(Lang.COBOL)
    },
    "coffee" to { _ ->
        CommonExtractor(Lang.COFFEESCRIPT)
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
    "cs" to { buf ->
        if (SmalltalkRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.SMALLTALK)
        } else {
            CSharpExtractor()
        }
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
        CommonExtractor(Lang.CUDA)
    },
    "cuh" to { _ ->
        CommonExtractor(Lang.CUDA)
    },
    "cxx" to { _ ->
        CppExtractor()
    },
    "c++" to { _ ->
        CppExtractor()
    },
    "d" to { buf ->
        if (DRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.D)
        } else if (DtraceRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.DTRACE)
        } else if (MakefileRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.MAKEFILE)
        } else null
    },
    "dart" to { _ ->
        DartExtractor
    },
    "db2" to { _ ->
        CommonExtractor(Lang.SQLPL)
    },
    "ddl" to { buf ->
        if (PlsqlRegexs.any { re -> re.containsMatchIn(buf)}) {
            CommonExtractor(Lang.PLSQL)  // Oracle
        } else if (!NotSqlRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.SQL)  // Generic SQL
        } else null
    },
    "dlm" to { _ ->
        CommonExtractor(Lang.IDL)
    },
    "dpr" to { _ ->
        CommonExtractor(Lang.PASCAL)
    },
    "edn" to { _ ->
        CommonExtractor(Lang.CLOJURE)
    },
    "el" to { _ ->
        CommonExtractor(Lang.EMACSLISP)
    },
    "elc" to { _ ->
        CommonExtractor(Lang.EMACSLISP)
    },
    "eliom" to { _ ->
        CommonExtractor(Lang.OCAML)
    },
    "elm" to { _ ->
        CommonExtractor(Lang.ELM)
    },
    "erl" to { _ ->
        CommonExtractor(Lang.ERLANG)
    },
    "ex" to { _ ->
        ElixirExtractor
    },
    "exs" to { _ ->
        ElixirExtractor
    },
    "f" to { buf ->
        if (ForthRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.FORTH)
        } else if (buf.contains("flowop")) {
            CommonExtractor(Lang.FILEBENCHWML)
        } else if (FortranRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.FORTRAN)
        } else null
    },
    "f03" to { _ ->
        CommonExtractor(Lang.FORTRAN)
    },
    "f08" to { _ ->
        CommonExtractor(Lang.FORTRAN)
    },
    "f15" to { _ ->
        CommonExtractor(Lang.FORTRAN)
    },
    "f90" to { _ ->
        CommonExtractor(Lang.FORTRAN)
    },
    "f95" to { _ ->
        CommonExtractor(Lang.FORTRAN)
    },
    "factor" to { _ ->
        CommonExtractor(Lang.FACTOR)
    },
    "fcgi" to { buf ->
        if (Perl5Regex.containsMatchIn(buf)) {
            CommonExtractor(Lang.PERL)
        } else {
            CommonExtractor(Lang.LUA)
        }
    },
    "fnc" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "for" to { buf ->
        if (ForthRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.FORTH)
        } else if (FortranRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.FORTRAN)
        } else null
    },
    "forth" to { _ ->
        CommonExtractor(Lang.FORTH)
    },
    "fp" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "fr" to { _ ->
        CommonExtractor(Lang.FORTH)
    },
    "frag" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "frg" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "frt" to { _ ->
        CommonExtractor(Lang.FORTH)
    },
    "fs" to { buf ->
        if (ForthFsRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.FORTH)
        } else if (FSharpRegex.containsMatchIn(buf)) {
            FSharpExtractor()
        } else if (GlslRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.GLSL)
        } else if (FilterscriptRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.FILTERSCRIPT)
        } else null
    },
    "fsh" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "fsx" to { _ ->
        FSharpExtractor()
    },
    "fth" to { _ ->
        CommonExtractor(Lang.FORTH)
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
        CommonExtractor(Lang.GRADLE)
    },
    "groovy" to { _ ->
        CommonExtractor(Lang.GROOVY)
    },
    "h" to { buf ->
        if (ObjectiveCRegex.containsMatchIn(buf)) {
            ObjectiveCExtractor()
        } else if (CppRegex.containsMatchIn(buf)) {
            CppExtractor()
        } else CExtractor()
    },
    "h++" to { _ ->
        CppExtractor()
    },
    "hh" to { _ ->
        CppExtractor()
    },
    "hic" to { _ ->
        CommonExtractor(Lang.CLOJURE)
    },
    "hl" to { _ ->
        CommonExtractor(Lang.CLOJURE)
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
        CommonExtractor(Lang.HASKELL)
    },
    "hrl" to { _ ->
        CommonExtractor(Lang.ERLANG)
    },
    "hx" to { _ ->
        CommonExtractor(Lang.HAXE)
    },
    "hxx" to { _ ->
        CppExtractor()
    },
    "hy" to { _ ->
        CommonExtractor(Lang.HY)
    },
    "ijs" to { _ ->
        CommonExtractor(Lang.J)
    },
    "inc" to { buf ->
        if (PhpRegex.containsMatchIn(buf)) {
            PhpExtractor()
        } else if (PovRaySdlRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.POVRAYSDL)
        } else if (PascalRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.PASCAL)
        } else {
            CommonExtractor(Lang.ASSEMBLY)
        }
    },
    "inl" to { _ ->
        CppExtractor()
    },
    "ino" to { _ ->
        CommonExtractor(Lang.ARDUINO)
    },
    "java" to { _ ->
        JavaExtractor()
    },
    "jl" to { _ ->
        CommonExtractor(Lang.JULIA)
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
        ScalaExtractor
    },
    "l" to { buf ->
        if (CommonLispRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.COMMONLISP)
        } else if (LexRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.LEX)
        } else if (RoffRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.ROFF)
        } else if (PicoLispRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.PICOLISP)
        } else null
    },
    "lbx" to { _ ->
        CommonExtractor(Lang.TEX)
    },
    "less" to { _ ->
        CssExtractor()
    },
    "lhs" to { _ ->
        CommonExtractor(Lang.HASKELL)
    },
    "lisp" to { buf ->
        if (CommonLispRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.COMMONLISP)
        } else if (NewLispRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.NEWLISP)
        } else null
    },
    "litcoffee" to { _ ->
        CommonExtractor(Lang.COFFEESCRIPT)
    },
    "lsp" to { buf ->
        if (CommonLispRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.COMMONLISP)
        } else if (NewLispRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.NEWLISP)
        } else null
    },
    "lua" to { _ ->
        CommonExtractor(Lang.LUA)
    },
    "m" to { buf ->
        if (ObjectiveCRegex.containsMatchIn(buf)) {
            ObjectiveCExtractor()
        } else if (buf.contains(":- module")) {
            CommonExtractor(Lang.MERCURY)
        } else if (MufRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.MUF)
        } else if (MRegexs.any { re -> re.containsMatchIn(buf)}) {
            CommonExtractor(Lang.M)
        } else if (MathematicaRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.MATHEMATICA)
        } else if (MatlabRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.MATLAB)
        } else if (LimboRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.LIMBO)
        } else {
            CommonExtractor(Lang.WOLFRAM)
        }
    },
    "make" to { _ ->
        CommonExtractor(Lang.MAKEFILE)
    },
    "makefile" to { _ ->
        CommonExtractor(Lang.MAKEFILE)
    },
    "mat" to { _ ->
        CommonExtractor(Lang.MATLAB)
    },
    "mjml" to { _ ->
        CommonExtractor(Lang.XML)
    },
    "ml" to { buf ->
        if (OcamlRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.OCAML)
        } else if (StandardMlRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.STANDARDML)
        } else null
    },
    "mli" to { _ ->
        CommonExtractor(Lang.OCAML)
    },
    "mlx" to { _ ->
        CommonExtractor(Lang.MATLAB)
    },
    "mm" to { _ ->
        ObjectiveCExtractor()
    },
    "ms" to { _ ->
        CommonExtractor(Lang.ROFF)
    },
    "mt" to { _ ->
        CommonExtractor(Lang.MATHEMATICA)
    },
    "muf" to { _ ->
        CommonExtractor(Lang.MUF)
    },
    "mysql" to { _ ->
        CommonExtractor(Lang.SQL)
    },
    "n" to { _ ->
        CommonExtractor(Lang.ROFF)
    },
    "nasm" to { _ ->
        CommonExtractor(Lang.ASSEMBLY)
    },
    "nb" to { buf ->
        if (MathematicaRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.MATHEMATICA)
        } else CommonExtractor(Lang.WOLFRAM)
    },
    "nl" to { _ ->
        CommonExtractor(Lang.NEWLISP)
    },
    "nr" to { _ ->
        CommonExtractor(Lang.ROFF)
    },
    "oxygene" to { _ ->
        CommonExtractor(Lang.OXYGENE)
    },
    "P" to { _ ->
        CommonExtractor(Lang.PROLOG)
    },
    "p6" to { _ ->
        CommonExtractor(Lang.PERL6)
    },
    "p8" to { _ ->
        CommonExtractor(Lang.LUA)
    },
    "pas" to { _ ->
        CommonExtractor(Lang.PASCAL)
    },
    "pascal" to { _ ->
        CommonExtractor(Lang.PASCAL)
    },
    "pck" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "pd_lua" to { _ ->
        CommonExtractor(Lang.LUA)
    },
    "pde" to { _ ->
        CommonExtractor(Lang.PROCESSING)
    },
    "php" to { buf ->
        if (buf.contains("<?hh")) {
            CommonExtractor(Lang.HACK)
        } else {
            PhpExtractor()
        }
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
    "pl" to { buf ->
        if (PrologRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.PROLOG)
        } else if (Perl6Regex.containsMatchIn(buf)) {
            CommonExtractor(Lang.PERL6)
        } else {
            CommonExtractor(Lang.PERL)
        }
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
    "pm" to { buf ->
        if (Perl5Regex.containsMatchIn(buf)) {
            CommonExtractor(Lang.PERL)
        } else if (Perl6Regex.containsMatchIn(buf)) {
            CommonExtractor(Lang.PERL6)
        } else if (XpmRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.XPM)
        } else null
    },
    "pm6" to { _ ->
        CommonExtractor(Lang.PERL6)
    },
    "pom" to { _ ->
        CommonExtractor(Lang.MAVENPOM)
    },
    "pov" to { _ ->
        CommonExtractor(Lang.POVRAYSDL)
    },
    "pp" to { buf ->
        if (PascalRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.PASCAL)
        } else {
            CommonExtractor(Lang.PUPPET)
        }
    },
    "prc" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "pro" to { buf ->
        if (PrologRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.PROLOG)
        } else if (buf.contains("last_client=")) {
            CommonExtractor(Lang.INI)
        } else if (buf.contains("HEADERS") || buf.contains("SOURCES")) {
            CommonExtractor(Lang.QMAKE)
        } else if (IdlRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.IDL)
        } else null
    },
    "prolog" to { _ ->
        CommonExtractor(Lang.PROLOG)
    },
    "props" to { buf ->
        if (XmlPropsRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.XML)
        } else if (IniPropsRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.INI)
        } else null
    },
    "ps1" to { _ ->
        CommonExtractor(Lang.POWERSHELL)
    },
    "psd1" to { _ ->
        CommonExtractor(Lang.POWERSHELL)
    },
    "psm1" to { _ ->
        CommonExtractor(Lang.POWERSHELL)
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
    "r" to { buf ->
        if (RebolRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.REBOL)
        } else if (RRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.R)
        } else null
    },
    "r2" to { _ ->
        CommonExtractor(Lang.REBOL)
    },
    "r3" to { _ ->
        CommonExtractor(Lang.REBOL)
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
        CommonExtractor(Lang.REBOL)
    },
    "rebol" to { _ ->
        CommonExtractor(Lang.REBOL)
    },
    "rno" to { _ ->
        CommonExtractor(Lang.ROFF)
    },
    "rpy" to { buf ->
        if (PythonRegex.containsMatchIn(buf)) {
            PythonExtractor()
        } else CommonExtractor(Lang.RENPY)
    },
    "rs" to { buf ->
        if (RustRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.RUST)
        } else if (RenderscriptRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.RENDERSCRIPT)
        } else null
    },
    "rsh" to { _ ->
        CommonExtractor(Lang.RENDERSCRIPT)
    },
    "rsx" to { _ ->
        CommonExtractor(Lang.R)
    },
    "s" to { _ ->
        CommonExtractor(Lang.ASSEMBLY)
    },
    "sas" to { _ ->
        CommonExtractor(Lang.SAS)
    },
    "sass" to { _ ->
        CssExtractor()
    },
    "sbt" to { _ ->
        ScalaExtractor
    },
    "sc" to { buf ->
        if (SupercolliderRegexs.any { re -> re.containsMatchIn(buf) }) {
            CommonExtractor(Lang.SUPERCOLLIDER)
        } else if (ScalaRegex.containsMatchIn(buf)) {
            ScalaExtractor
        } else null
    },
    "scala" to { _ ->
        ScalaExtractor
    },
    "scd" to { _ ->
        CommonExtractor(Lang.SUPERCOLLIDER)
    },
    "sch" to { _ ->
        CommonExtractor(Lang.SCHEME)
    },
    "scm" to { _ ->
        CommonExtractor(Lang.SCHEME)
    },
    "scss" to { _ ->
        CssExtractor()
    },
    "sexp" to { _ ->
        CommonExtractor(Lang.COMMONLISP)
    },
    "sh" to { _ ->
        CommonExtractor(Lang.SHELL)
    },
    "shader" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "sld" to { _ ->
        CommonExtractor(Lang.SCHEME)
    },
    "sls" to { _ ->
        CommonExtractor(Lang.SCHEME)
    },
    "sol" to { _ ->
        CommonExtractor(Lang.SOLIDITY)
    },
    "spc" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "sps" to { _ ->
        CommonExtractor(Lang.SCHEME)
    },
    "sql" to { buf ->
        if (PlpgsqlRegexs.any { re -> re.containsMatchIn(buf)}) {
            PlpgsqlExtractor  // PostgreSQL.
        } else if (SqlplRegexs.any { re -> re.containsMatchIn(buf)}) {
            CommonExtractor(Lang.SQLPL)  // IBM DB2.
        } else if (PlsqlRegexs.any { re -> re.containsMatchIn(buf)}) {
            CommonExtractor(Lang.PLSQL)  // Oracle.
        } else {
            CommonExtractor(Lang.SQL)  // Generic SQL.
        }
    },
    "ss" to { _ ->
        CommonExtractor(Lang.SCHEME)
    },
    "st" to { _ ->
        CommonExtractor(Lang.SMALLTALK)
    },
    "swift" to { _ ->
        SwiftExtractor
    },
    "t" to { buf ->
        if (Perl6Regex.containsMatchIn(buf)) {
            CommonExtractor(Lang.PERL6)
        } else {
            CommonExtractor(Lang.PERL)
        }
    },
    "tab" to { _ ->
        CommonExtractor(Lang.SQL)
    },
    "tcl" to { _ ->
        CommonExtractor(Lang.TCL)
    },
    "tesc" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "tese" to { _ ->
        CommonExtractor(Lang.GLSL)
    },
    "tex" to { _ ->
        CommonExtractor(Lang.TEX)
    },
    "tmac" to { _ ->
        CommonExtractor(Lang.ROFF)
    },
    "toc" to { _ ->
        CommonExtractor(Lang.TEX)
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
    "ts" to { buf ->
        if (XmltsRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.XML)
        } else {
            CommonExtractor(Lang.TYPESCRIPT)
        }
    },
    "tsx" to { buf ->
        if (TypescriptRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.TYPESCRIPT)
        } else if (XmlRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.XML)
        } else null
    },
    "udf" to { _ ->
        CommonExtractor(Lang.SQL)
    },
    "ux" to { _ ->
        CommonExtractor(Lang.XML)
    },
    "v" to { buf ->
        if (CoqRegex.containsMatchIn(buf)) {
            CommonExtractor(Lang.COQ)
        } else {
            CommonExtractor(Lang.VERILOG)
        }
    },
    "vb" to { _ ->
        CommonExtractor(Lang.VISUALBASIC)
    },
    "vba" to { _ ->
        CommonExtractor(Lang.VBA)
    },
    "vhdl" to { _ ->
        CommonExtractor(Lang.VHDL)
    },
    "vbhtml" to { _ ->
        CommonExtractor(Lang.VISUALBASIC)
    },
    "vim" to { _ ->
        CommonExtractor(Lang.VIML)
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
        JavascriptExtractor()
    },
    "vw" to { _ ->
        CommonExtractor(Lang.PLSQL)
    },
    "wl" to { _ ->
        CommonExtractor(Lang.MATHEMATICA)
    },
    "wlt" to { _ ->
        CommonExtractor(Lang.MATHEMATICA)
    },
    "xml" to { _ ->
        CommonExtractor(Lang.XML)
    },
    "xpm" to { _ ->
        CommonExtractor(Lang.XPM)
    },
    "xtend" to { _ ->
        CommonExtractor(Lang.XTEND)
    },
    "yap" to { _ ->
        CommonExtractor(Lang.PROLOG)
    }
)
