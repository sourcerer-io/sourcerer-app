// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package test.tests.extractors

import app.extractors.*
import junit.framework.TestCase.assertTrue
import org.jetbrains.spek.api.Spek
import org.jetbrains.spek.api.dsl.given
import org.jetbrains.spek.api.dsl.it
import kotlin.test.assertEquals

fun assertExtractsLineLibraries(expectedLibrary: String, actualLine: String,
                                extractor: ExtractorInterface) {
    val actualLineLibraries =
            extractor.getLineLibraries(actualLine, listOf(expectedLibrary))
    assertTrue(expectedLibrary in actualLineLibraries)
}

fun assertExtractsNoLibraries(actualLine: String,
                              extractor: ExtractorInterface) {
    val actualLineLibraries =
            extractor.getLineLibraries(actualLine, listOf())
    assertEquals(listOf(), actualLineLibraries)
}

fun assertExtractsImport(expectedImport: String, actualLine: String,
                         extractor: ExtractorInterface) {
    val actualLineImport = extractor.extractImports(listOf(actualLine))
    assertTrue(expectedImport in actualLineImport)
}

class ExtractorTest : Spek({

    given(" code line contains library code" ) {
        it("python extractor extracts the library") {
            val line = "with tf.Session() as sess"
            assertExtractsLineLibraries("tensorflow",
                    line, PythonExtractor())
        }

        it("java extractor extracts the library") {
            val line = "private JdbcTemplate jdbcTemplate=new JdbcTemplate();"
            assertExtractsLineLibraries("org.springframework",
                    line, JavaExtractor())
        }

        it("javascript extractor extracts the library") {
            val line = "new Vue({"
            assertExtractsLineLibraries("vue",
                    line, JavascriptExtractor())
        }

        it("ruby extractor extracts the library") {
            val line1 = "img = Magick::Image.read_inline(Base64.encode64(image)).first"
            assertExtractsLineLibraries("RMagick",
                    line1, RubyExtractor())
            val line2 = "fximages << {image: img.adaptive_threshold(3, 3, 0), name: \"Adaptive Threshold\"}"
            assertExtractsLineLibraries("RMagick",
                    line2, RubyExtractor())
        }

        it("go extractor extracts the library") {
            val line = "if DB, found = revel.Config.String(\"bloggo.db\"); !found {"
            assertExtractsLineLibraries("revel",
                    line, GoExtractor())
        }

        it("objectiveC extractor extracts the library") {
            val line = "[[NSFileManager defaultManager] removeItemAtURL:[RLMRealmConfiguration defaultConfiguration].fileURL error:nil];"
            assertExtractsLineLibraries("Realm",
                    line, ObjectiveCExtractor())
        }

        it("swift extractor extracts the library") {
            val line = "class City: RLMObject {"
            assertExtractsLineLibraries("Realm",
                    line, SwiftExtractor())
        }

        it("cpp extractor extracts the library") {
            val line1 = "leveldb::Options options;"
            assertExtractsLineLibraries("leveldb",
                    line1, CppExtractor())
            val line2 = "leveldb::Status status = leveldb::DB::Open(options, \"./testdb\", &tmp);"
            assertExtractsLineLibraries("leveldb",
                    line2, CppExtractor())
        }

        it("csharp extractor extracts the library") {
            val line = "Algorithm = (h, v, i) => new ContrastiveDivergenceLearning(h, v)"
            assertExtractsLineLibraries("Accord",
                    line, CSharpExtractor())
        }

        it("php extractor extracts the library") {
            val line = "public function listRepos(string \$user, int \$limit): Call;"
            assertExtractsLineLibraries("Tebru\\Retrofit",
                    line, PhpExtractor())
        }

        it("c extractor extracts the library") {
            val line = "grpc_test_init(argc, argv);"
            assertExtractsLineLibraries("grpc",
                    line, CExtractor())
        }

        it("kotlin extractor extracts the library") {
            val line = "FuelManager.instance.apply {"
            assertExtractsLineLibraries("com.github.kittinunf.fuel",
                    line, KotlinExtractor())
        }

        it("ruby extractor extracts rails") {
            val line = "class Article < ApplicationRecord"
            assertExtractsLineLibraries("rails",
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

        it("swift extractor returns empty list") {
            val line = "import Foundation"
            assertExtractsNoLibraries(line, SwiftExtractor())
        }

        it("csharp extractor returns empty list") {
            val line = "static void Main(string[] args)"
            assertExtractsNoLibraries(line, CSharpExtractor())
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

    given("import name.h") {
        it("imports name") {
            assertExtractsImport("protobuf", "#include \"protobuf.h\"", CppExtractor())
        }
    }

    given("import library with multiple ways to import") {
        it("imports in both cases") {
            var lib = "opencv"
            val line1 = "#include \"opencv/module/header.h\""
            assertExtractsImport(lib, line1, CppExtractor())
            val line2 = "#include \"opencv2/module/header.h\""
            assertExtractsImport(lib, line2, CppExtractor())
        }
    }

    given("line contains import") {
        it("kotlin extractor extracts import") {
            val line = "import kategory.optics.*"
            val lib = "kategory"
            assertExtractsImport(lib, line, KotlinExtractor())
        }
    }

    given("import cv2 or cv") {
        it("imports opencv") {
            val lib = "opencv"
            val line1 = "import cv2"
            assertExtractsImport(lib, line1, PythonExtractor())
            val line2 = "import cv"
            assertExtractsImport(lib, line2, PythonExtractor())
        }
    }

    given("one line import in go file") {
        it("extracts library name") {
            val lib = "macagon"
            val line = "import \"macagon\""
            assertExtractsImport(lib, line, GoExtractor())
        }
    }

    given("multiline import in go file") {
        it("extracts library name") {
            val lib = "macagon"
            val lines = listOf("import (",
                               "\"macagon\"",
                               "\"github.com/astaxie/beego\"",
                               ")")
            val actualLineImports = GoExtractor().extractImports(lines)
            assertTrue(lib in actualLineImports)
        }
    }

    given("github  url as import in go file") {
        it("extracts library name") {
            val lib = "beego"
            val lines = listOf("import (",
                    "\"macagon\"",
                    "\"github.com/astaxie/beego\"",
                    ")")
            val actualLineImports = GoExtractor().extractImports(lines)
            assertTrue(lib in actualLineImports)
        }
    }

    given("js comment line") {
        it("doesn't extract libraries") {
            var lines = listOf("// It doesn't use Ember 1")
            var actualLineImports = JavascriptExtractor().extractImports(lines)
            assertTrue(actualLineImports.isEmpty())

            lines = listOf("/* It doesn't use ember 2", "* and you Ember ",
                                "* too Ember */")
            actualLineImports = JavascriptExtractor().extractImports(lines)
            assertTrue(actualLineImports.isEmpty())
        }
    }

})
