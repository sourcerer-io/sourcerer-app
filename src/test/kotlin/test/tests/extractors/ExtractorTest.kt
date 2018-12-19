// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package test.tests.extractors

import app.extractors.*
import junit.framework.TestCase.assertTrue
import org.jetbrains.spek.api.Spek
import org.jetbrains.spek.api.dsl.given
import org.jetbrains.spek.api.dsl.it
import org.jetbrains.spek.api.dsl.xit
import kotlin.test.assertEquals
import kotlin.test.assertNull

fun assertExtractsLineLibraries(expectedLibrary: String, actualLine: String,
                                extractor: ExtractorInterface) {
    val actualLineLibraries =
        extractor.determineLibs(actualLine, listOf(expectedLibrary))
    assertTrue(expectedLibrary in actualLineLibraries)
}

fun assertExtractsNoLibraries(actualLine: String,
                              extractor: ExtractorInterface) {
    val actualLineLibraries =
        extractor.determineLibs(actualLine, listOf())
    assertEquals(listOf(), actualLineLibraries)
}

fun assertExtractsImport(expectedImport: String, actualLine: String,
                         extractor: ExtractorInterface) {
    val actualLineImport = extractor.extractImports(listOf(actualLine))
    assertTrue(expectedImport in actualLineImport)
}

fun assertMapsIndex(expectedIndex: String, actualImport: String,
                    language: String, extractor: ExtractorInterface) {
    val actualIndex = extractor.mapImportToIndex(actualImport, language)
    assertEquals(expectedIndex, actualIndex)
}

fun assertMapsNothing(actualImport: String, language: String,
                      extractor: ExtractorInterface) {
    val actualIndex = extractor.mapImportToIndex(actualImport, language)
    assertNull(actualIndex)
}

class ExtractorTest : Spek({
    given(" code line contains library code" ) {
        it("python extractor extracts the library") {
            val line = "with tf.Session() as sess"
            assertExtractsLineLibraries("py.tensorflow",
                line, PythonExtractor())
        }

        it("java extractor extracts the library") {
            val line = "private JdbcTemplate jdbcTemplate=new JdbcTemplate();"
            assertExtractsLineLibraries("java.spring-framework",
                line, JavaExtractor())
        }

        it("javascript extractor extracts the library") {
            val line = "new Vue({"
            assertExtractsLineLibraries("js.vue",
                line, JavascriptExtractor())
        }

        it("ruby extractor extracts the library") {
            val line1 = "img = Magick::Image.read_inline(Base64.encode64(image)).first"
            assertExtractsLineLibraries("rb.rmagick",
                line1, RubyExtractor())
            val line2 = "fximages << {image: img.adaptive_threshold(3, 3, 0), name: \"Adaptive Threshold\"}"
            assertExtractsLineLibraries("rb.rmagick",
                line2, RubyExtractor())
        }

        it("go extractor extracts the library") {
            val line = "if DB, found = revel.Config.String(\"bloggo.db\"); !found {"
            assertExtractsLineLibraries("go.revel",
                line, GoExtractor())
        }

        it("objectiveC extractor extracts the library") {
            val line = "[[NSFileManager defaultManager] removeItemAtURL:[RLMRealmConfiguration defaultConfiguration].fileURL error:nil];"
            assertExtractsLineLibraries("objc.realm",
                line, ObjectiveCExtractor())
        }

        it("cpp extractor extracts the library") {
            val line1 = "leveldb::Options options;"
            assertExtractsLineLibraries("cpp.level-db",
                line1, CppExtractor())
            val line2 = "leveldb::Status status = leveldb::DB::Open(options, \"./testdb\", &tmp);"
            assertExtractsLineLibraries("cpp.level-db",
                line2, CppExtractor())
        }

        it("csharp extractor extracts the library") {
            val line = "Algorithm = (h, v, i) => new ContrastiveDivergenceLearning(h, v)"
            assertExtractsLineLibraries("cs.accord-net",
                line, CSharpExtractor())
        }

        it("fsharp extractor extracts the library") {
            val line = "Algorithm = fun (h, v, i) -> ContrastiveDivergenceLearning(h, v)"
            assertExtractsLineLibraries("cs.accord-net",
                line, FSharpExtractor())
        }

        it("php extractor extracts the library") {
            val line = "public function listRepos(string \$user, int \$limit): Call;"
            assertExtractsLineLibraries("php.retrofit-php",
                line, PhpExtractor())
        }

        xit("c extractor extracts the library") {
            val line = "grpc_test_init(argc, argv);"
            assertExtractsLineLibraries("c.grpc",
                line, CExtractor())
        }

        it("kotlin extractor extracts the library") {
            val line = "FuelManager.instance.apply {"
            assertExtractsLineLibraries("kt.fuel",
                line, KotlinExtractor())
        }

        it("ruby extractor extracts rails") {
            val line = "class Article < ActiveRecord::Base"
            assertExtractsLineLibraries("rb.rails",
                line, RubyExtractor())
        }
    }

    given("code line doesn't use libraries" ) {
        it("python extractor returns empty list") {
            val line = "from collections import Counter"
            assertExtractsNoLibraries(line, PythonExtractor())
        }

        it("java extractor returns empty list") {
            val line = "throw new RuntimeException(e);"
            assertExtractsNoLibraries(line, JavaExtractor())
        }

        it("javascript extractor returns empty list") {
            val line = "console.log(self.commits[0].html_url)"
            assertExtractsNoLibraries(line, JavascriptExtractor())
        }

        it("ruby extractor returns empty list") {
            val line = "require \"RMagick\""
            assertExtractsNoLibraries(line, RubyExtractor())
        }

        it("go extractor returns empty list") {
            val line = "var found bool"
            assertExtractsNoLibraries(line, GoExtractor())
        }

        it("objectivec extractor returns empty list") {
            val line = "@end"
            assertExtractsNoLibraries(line, ObjectiveCExtractor())
        }

        it("php extractor returns empty list") {
            val line = "<?php"
            assertExtractsNoLibraries(line, PhpExtractor())
        }

        it("csharp extractor returns empty list") {
            val line = "static void Main(string[] args)"
            assertExtractsNoLibraries(line, CSharpExtractor())
        }

        it("fsharp extractor returns empty list") {
            val line = "let main()"
            assertExtractsNoLibraries(line, FSharpExtractor())
        }

        it("cpp extractor returns empty list") {
            val line = "std::cerr << status.ToString() << std::endl;"
            assertExtractsNoLibraries(line, CppExtractor())
        }

        it("c extractor returns empty list") {
            val line = "int main(int argc, char **argv) {"
            assertExtractsNoLibraries(line, CExtractor())
        }

        it("kotlin extractor returns empty list") {
            val line = "val password = \"P@\$\\\$vv0|2|)\""
            assertExtractsNoLibraries(line, KotlinExtractor())
        }
    }

    given("line contains import") {
        it("kotlin extractor extracts import") {
            val import = "kategory.optics."
            val line = "import $import*"
            assertExtractsImport(import, line, KotlinExtractor())
        }
    }

    given("import cv2 or cv") {
        it("extracts import") {
            val line1 = "import cv2"
            assertExtractsImport("cv2", line1, PythonExtractor())
            val line2 = "import cv"
            assertExtractsImport("cv", line2, PythonExtractor())
        }
    }

    given("one line import in go file") {
        it("extracts library name") {
            val import = "macagon"
            val line = "import \"macagon\""
            assertExtractsImport(import, line, GoExtractor())
        }
    }

    given("multiline import in go file") {
        it("extracts library name") {
            val import = "macagon"
            val lines = listOf("import (",
                "\"macagon\"",
                "\"github.com/astaxie/beego\"",
                ")")
            val actualLineImports = GoExtractor().extractImports(lines)
            assertTrue(import in actualLineImports)
        }
    }

    given("github  url as import in go file") {
        it("extracts github url") {
            val url = "github.com/astaxie/beego"
            val lines = listOf("import (",
                    "\"macagon\"", "\"" + url + "\"", ")")
            val actualLineImports = GoExtractor().extractImports(lines)
            assertTrue(url in actualLineImports)
        }
    }

    given("Dart") {
        it("Dart single-line comment") {
            var lines = listOf("// import 'dart:math';")
            var actualLineImports = DartExtractor.extractImports(lines)
            actualLineImports.forEach {
                assertMapsNothing(it, Lang.DART, DartExtractor)
            }
        }
        it("Dart multi-line comment") {
            var lines = listOf("/* import 'dart:math'; */")
            var actualLineImports = DartExtractor.extractImports(lines)
            actualLineImports.forEach {
                assertMapsNothing(it, Lang.DART, DartExtractor)
            }
        }
        it("Dart import") {
            var line = "import 'dart:math';"
            val import = "dart:math"
            assertExtractsImport(import, line, DartExtractor)
        }
    }

    given("js comment line") {
        it("doesn't extract libraries") {
            var lines = listOf("// It doesn't use Ember 1")
            val extractor = JavascriptExtractor()
            var actualLineImports = extractor.extractImports(lines)
            actualLineImports.forEach {
                assertMapsNothing(it, Lang.JAVASCRIPT, extractor)
            }

            lines = listOf("/* It doesn't use ember 2", "* and you Ember ",
                "* too Ember */")
            actualLineImports = extractor.extractImports(lines)
            actualLineImports.forEach {
                assertMapsNothing(it, Lang.JAVASCRIPT, extractor)
            }
        }
    }

    given("Cpp") {
        it("imports name.h") {
            val import = "protobuf.h"
            val line = "#include \"$import\""
            assertExtractsImport(import, line, CppExtractor())
        }

        it("imports library with multiple ways to import") {
            val lib = "cpp.open-cv"
            val import1 = "opencv/module/header.h"
            val import2 = "opencv2/module/header.h"
            val line1 = "#include \"$import1\""
            val line2 = "#include \"$import2\""
            val extractor = CppExtractor()

            assertExtractsImport(import1, line1, extractor)
            assertExtractsImport(import2, line2, extractor)

            var actualImport = extractor.extractImports(listOf(line1))[0]
            assertMapsIndex(lib, actualImport, Lang.CPP, extractor)
            actualImport = extractor.extractImports(listOf(line2))[0]
            assertMapsIndex(lib, actualImport, Lang.CPP, extractor)

        }

        it("extracts Qt library") {
            val lib = "cpp.qt"
            val import = "QFileDialog"
            val line = "#include <$import>"
            val extractor = CppExtractor()
            assertExtractsImport(import, line, extractor)
            val actualImport = extractor.extractImports(listOf(line))[0]
            assertMapsIndex(lib, actualImport, Lang.CPP, extractor)
        }
    }

    given("Elixir") {
        it("Elixir comment") {
            var lines = listOf("# use Ecto.Repo")
            var actualLineImports = ElixirExtractor.extractImports(lines)
            actualLineImports.forEach {
                assertMapsNothing(it, Lang.ELIXIR, ElixirExtractor)
            }
        }
        it("Elixir use") {
            var line = " use Ecto.Repo"
            val import = "Ecto"
            assertExtractsImport(import, line, ElixirExtractor)
        }
        it("Elixir import") {
            var line = " import Ecto.Repo"
            val import = "Ecto"
            assertExtractsImport(import, line, ElixirExtractor)
        }
        it("Elixir require") {
            var line = " require Ecto.Repo"
            val import = "Ecto"
            assertExtractsImport(import, line, ElixirExtractor)
        }
    }

    given("PLpgSQL") {
        it("PLpgSQL single-line comment") {
            var lines = listOf("-- CREATE EXTENSION ltree")
            var actualLineImports = PlpgsqlExtractor.extractImports(lines)
            actualLineImports.forEach {
                assertMapsNothing(it, Lang.PLPGSQL, PlpgsqlExtractor)
            }
        }
        it("PLpgSQL multi-line comment") {
            var lines = listOf("/* CREATE EXTENSION ltree */")
            var actualLineImports = PlpgsqlExtractor.extractImports(lines)
            actualLineImports.forEach {
                assertMapsNothing(it, Lang.PLPGSQL, PlpgsqlExtractor)
            }
        }
        it("PLpgSQL extension") {
            var line = """ execute("CREATE EXTENSION ltree")"""
            val import = "ltree"
            assertExtractsImport(import, line, PlpgsqlExtractor)
        }
        it("PLpgSQL language") {
            var line = """ execute("CREATE LANGUAGE plr")"""
            val import = "plr"
            assertExtractsImport(import, line, PlpgsqlExtractor)
        }
    }

    given("Rust") {
        it("Rust imports") {
            var lines = listOf(
                    "extern crate foo;",
                    "extern crate boo;"
            )
            var actualLineImports = RustExtractor().extractImports(lines)
            assertEquals(actualLineImports, listOf("foo", "boo"))

            lines = listOf(
                    "// extern crate foo;",
                    "/* extern crate boo; */"
            )
            actualLineImports = RustExtractor().extractImports(lines)
            assertTrue(actualLineImports.isEmpty())
        }
    }

    given("Scala") {
        it("Scala single-line comment") {
            val lines = listOf("// import users._")
            val actualLineImports = ScalaExtractor.extractImports(lines)
            assertTrue(actualLineImports.isEmpty())
        }
        it("Scala multi-line comment") {
            val lines = listOf("/* import users._ */")
            val actualLineImports = ScalaExtractor.extractImports(lines)
            assertTrue(actualLineImports.isEmpty())
        }
        it("Scala imports") {
            val line = "import users._"
            assertExtractsImport("users.", line, ScalaExtractor)
        }
        it("Scala imports _root_") {
            val line = "import _root_.users._"
            assertExtractsImport("users.", line, ScalaExtractor)
        }
        it("Scala imports compound name") {
            val line = "import com.google.selfdrivingcar.camera.Lens"
            assertExtractsImport("com.google.selfdrivingcar.camera.", line,
                    ScalaExtractor)
        }
        it("Scala imports multiple import") {
            val line = "import akka.stream.scaladsl.{Flow, Sink, Source}"
            assertExtractsImport("akka.stream.scaladsl.", line, ScalaExtractor)
        }
        it("maps import to index") {
            val lib = "scala.slick"
            val line = "import slick.jdbc.JdbcProfile"
            val extractor = ScalaExtractor

            assertExtractsImport("slick.jdbc.", line, extractor)

            val actualImport = extractor.extractImports(listOf(line))[0]
            assertMapsIndex(lib, actualImport, Lang.SCALA, extractor)
        }
    }

    given("Swift") {
        it("Swift single-line comment") {
            val lines = listOf("// class City: RLMObject {")
            val actualLineImports = SwiftExtractor.extractImports(lines)
            assertTrue(actualLineImports.isEmpty())
        }
        it("Swift multi-line comment") {
            val lines = listOf("/* class City: RLMObject { */")
            val actualLineImports = SwiftExtractor.extractImports(lines)
            assertTrue(actualLineImports.isEmpty())
        }
        it("Swift imports") {
            val line = "import UIKit"
            assertExtractsImport("UIKit", line, SwiftExtractor)
        }
        it("Swift no libraries") {
            val line = "import Foundation"
            assertExtractsNoLibraries(line, SwiftExtractor)
        }
        it("Swift libraries") {
            val line = "class City: RLMObject {"
            assertExtractsLineLibraries("swift.realm", line, SwiftExtractor)
        }
    }
})
