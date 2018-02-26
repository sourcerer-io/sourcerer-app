// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package test.tests.hashers

import app.FactCodes
import app.api.MockApi
import app.hashers.MetaHasher
import app.model.Author
import app.model.Repo
import org.jetbrains.spek.api.Spek
import org.jetbrains.spek.api.dsl.given
import org.jetbrains.spek.api.dsl.it
import test.utils.TestRepo
import test.utils.assertFactInt
import test.utils.assertNoFact

class MetaHasherTest : Spek({
    val repoPath = "../testrepo-meta-hasher-"
    val repo = Repo(rehash = "rehash", commits = listOf())

    given("repo for team size fact") {
        val testRepo = TestRepo(repoPath + "team-size-fact")
        val authors = hashSetOf(
            Author("Alexander Ivanov", "ivanov.alexander@gmail.com"),
            Author("Maxim Zayac", "maxim95@sourcerer.io"),
            Author("yablonskaya", "lyablonskaya@sourcerer.io"),
            Author("Lubov Yablonskaya", "lyablonskaya@sourcerer.io"),
            Author("Alexander Ivanov", "aleks@riseup.net"),
            Author("Roman Romov", "roman.romov@gmail.com"),
            Author("Liubov Yablonskaya", "lyablonskaya@sourcerer.io"),
            Author("Taleh Yandex", "yandex007@ya.ru"),
            Author("Maxim Zayac", "mak-zayac@yandex.ru"),
            Author("Dmitry Yablokov", "dmitry.yablokov@gmail.com"),
            Author("yablokov", "yablokov@phystech.edu"),
            Author("Yablokov Dmitriy Andreevich", "d.yablokov@tinkoff.ru"),
            Author("Dmitry Yablokov", "yablokov@phystech.edu"),
            Author("Dmitry Yablokov", "yablokov@yandex-team.ru"),
            Author("John Brown", "john@mail.mail"),
            Author("Johnny Brown", "john123@mail.mail"))
        val commits = hashMapOf(
            Pair("aleks@upupup.net", 0),
            Pair("d.yablokov@tinkoff.ru", 10),
            Pair("dmitry.yablokov@gmail.com", 10),
            Pair("ivanov.alexander@gmail.com", 10),
            Pair("john123@mail.mail", 10),
            Pair("john@mail.mail", 10),
            Pair("lyablonskaya@sourcerer.io", 10),
            Pair("mak-zayac@yandex.ru", 10),
            Pair("maxim95@sourcerer.io", 10),
            Pair("roman.romov@gmail.com", 10),
            Pair("yablokov@phystech.edu", 10),
            Pair("yablokov@yandex-team.ru", 20),
            Pair("yandex007@ya.ru", 20)
        )
        val userEmails = listOf(
            "john123@mail.mail",
            "john@mail.mail"
        )
        val authorsList = authors.toList()
        val mockApi = MockApi(mockRepo = repo)
        val facts = mockApi.receivedFacts

        afterEachTest {
            facts.clear()
        }

        it("sends facts") {
            for (i in 0..authors.size - 1) {
                val line = "line number $i"
                val fileName = "file$i.txt"
                testRepo.createFile(fileName, listOf(line))
                testRepo.commit(message = "$line in $fileName",
                                author = authorsList[i])
            }

            MetaHasher(repo, mockApi).calculateAndSendFacts(authors, commits,
                userEmails)

            assertFactInt(FactCodes.COMMIT_SHARE, 0, 20,
                Author(email = userEmails.first()), facts = facts)
            assertFactInt(FactCodes.COMMIT_SHARE_REPO_AVG, 0, 20, facts = facts)
            assertFactInt(FactCodes.REPO_TEAM_SIZE, 0, 7, facts = facts)
        }

        it("sends facts (user not contributor)") {
            for (i in 0..authors.size - 1) {
                val line = "line number $i"
                val fileName = "file$i.txt"
                testRepo.createFile(fileName, listOf(line))
                testRepo.commit(message = "$line in $fileName",
                    author = authorsList[i])
            }

            MetaHasher(repo, mockApi).calculateAndSendFacts(authors, commits,
                listOf())

            assertNoFact(FactCodes.COMMIT_SHARE, 0,
                Author(email = userEmails.first()), facts = facts)
            assertFactInt(FactCodes.COMMIT_SHARE_REPO_AVG, 0, 20, facts = facts)
            assertFactInt(FactCodes.REPO_TEAM_SIZE, 0, 7, facts = facts)
        }

        afterGroup {
            testRepo.destroy()
        }
    }
})
