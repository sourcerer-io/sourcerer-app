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
            Author("Dmitry Yablokov", "yablokov@yandex-team.ru"))
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

            MetaHasher(repo, mockApi).calculateAndSendFacts(authors)
            assertFactInt(FactCodes.REPO_TEAM_SIZE, 0, 6, facts = facts)
        }

        afterGroup {
            testRepo.destroy()
        }
    }
})
