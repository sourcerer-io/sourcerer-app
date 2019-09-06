// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package test.tests.hashers

import app.api.MockApi
import app.extractors.ExtractorInterface
import app.hashers.CommitHasher
import app.hashers.CommitCrawler
import app.model.*
import app.utils.RepoHelper
import org.eclipse.jgit.api.Git
import org.jetbrains.spek.api.Spek
import org.jetbrains.spek.api.dsl.given
import org.jetbrains.spek.api.dsl.it
import test.utils.TestRepo
import java.io.File
import java.util.stream.StreamSupport.stream
import kotlin.streams.toList
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class CommitHasherTest : Spek({
    fun getRepoRehash(git: Git, localRepo: LocalRepo): String {

        val initialRevCommit = stream(git.log().call().spliterator(), false)
            .toList().first()
        return RepoHelper.calculateRepoRehash(Commit(initialRevCommit).rehash,
            localRepo)
    }

    fun getLastCommit(git: Git): Commit {
        val revCommits = stream(git.log().call().spliterator(), false).toList()
        val lastCommit = Commit(revCommits.first())
        return lastCommit
    }

    fun cleanRepos() {
        Runtime.getRuntime().exec("src/test/delete_repo.sh").waitFor()
    }

    val userName = "First Contributor"
    val userEmail = "test@domain.com"

    val secondUserName = "Second Contributor"
    val secondUserEmail = "test2@domain.com"

    // Creation of test repo.
    cleanRepos()
    val repoPath = "./tmp_repo/.git"
    val git = Git.init().setGitDir(File(repoPath)).call()
    val config = git.repository.config
    config.setString("user", null, "name", userName)
    config.setString("user", null, "email", userEmail)
    config.save()

    // Common parameters for CommitHasher.
    val gitHasher = Git.open(File(repoPath))
    val initialCommit = Commit(git.commit().setMessage("Initial commit").call())
    val repoRehash = RepoHelper.calculateRepoRehash(initialCommit.rehash,
        LocalRepo(repoPath).also { it.author = Author(userName, userEmail) })
    val repo = Repo(rehash = repoRehash,
                    initialCommitRehash = initialCommit.rehash)
    val emails = hashSetOf(userEmail, secondUserEmail)

    given("repo with initial commit and no history") {
        repo.commits = listOf()

        val errors = mutableListOf<Throwable>()
        val mockApi = MockApi(mockRepo = repo)
        val observable = CommitCrawler.getObservable(gitHasher, repo)
        CommitHasher(repo, mockApi, repo.commits.map {it.rehash}, emails)
            .updateFromObservable(observable, { e -> errors.add(e) })

        it ("has no errors") {
            assertEquals(0, errors.size)
        }

        it("send added commits") {
            assertEquals(1, mockApi.receivedAddedCommits.size)
        }

        it("doesn't send deleted commits") {
            assertEquals(0, mockApi.receivedDeletedCommits.size)
        }
    }

    given("repo with initial commit") {
        repo.commits = listOf(getLastCommit(git))

        val errors = mutableListOf<Throwable>()
        val mockApi = MockApi(mockRepo = repo)
        val observable = CommitCrawler.getObservable(gitHasher, repo)
        CommitHasher(repo, mockApi, repo.commits.map {it.rehash}, emails)
            .updateFromObservable(observable, { e -> errors.add(e) })

        it ("has no errors") {
            assertEquals(0, errors.size)
        }

        it("doesn't send added commits") {
            assertEquals(0, mockApi.receivedAddedCommits.size)
        }

        it("doesn't send deleted commits") {
            assertEquals(0, mockApi.receivedDeletedCommits.size)
        }
    }

    given("happy path: added one commit") {
        repo.commits = listOf(getLastCommit(git))

        val errors = mutableListOf<Throwable>()
        val mockApi = MockApi(mockRepo = repo)
        val revCommit = git.commit().setMessage("Second commit.").call()
        val addedCommit = Commit(revCommit)
        val observable = CommitCrawler.getObservable(gitHasher, repo)
        CommitHasher(repo, mockApi, repo.commits.map {it.rehash}, emails)
            .updateFromObservable(observable, { e -> errors.add(e) })

        it ("has no errors") {
            assertEquals(0, errors.size)
        }

        it("doesn't send deleted commits") {
            assertEquals(0, mockApi.receivedDeletedCommits.size)
        }

        it("posts one commit as added") {
            assertEquals(1, mockApi.receivedAddedCommits.size)
        }

        it("should be that the posted commit is added one") {
            assertEquals(addedCommit, mockApi.receivedAddedCommits.last())
        }
    }

    /*given("happy path: added a few new commits") {
        repo.commits = listOf(getLastCommit(git))

        val errors = mutableListOf<Throwable>()
        val mockApi = MockApi(mockRepo = repo)

        val otherAuthorsNames = listOf("a", "b", "a")
        val otherAuthorsEmails = listOf("a@a", "b@b", "a@a")
        for (i in 0..2) {
            git.commit().setMessage("Create $i.")
                        .setAuthor(otherAuthorsNames.get(i),
                                   otherAuthorsEmails.get(i))
                        .call()
        }
        val authorCommits = mutableListOf<Commit>()
        for (i in 0..4) {
            val message = "Created $i by author."
            val revCommit = git.commit().setMessage(message).call()
            authorCommits.add(Commit(revCommit))
        }
        val observable = CommitCrawler.getObservable(gitHasher, repo)
        CommitHasher(repo, mockApi, repo.commits.map {it.rehash}, emails)
            .updateFromObservable(observable, { e -> errors.add(e) })

        it ("has no errors") {
            assertEquals(0, errors.size)
        }

        it("posts five commits as added") {
            assertEquals(5, mockApi.receivedAddedCommits.size)
        }

        it("doesn't send deleted commits ") {
            assertEquals(0, mockApi.receivedDeletedCommits.size)
        }

        it("processes author's commits") {
            assertEquals(authorCommits.asReversed(),
                         mockApi.receivedAddedCommits)
        }
    }

    given("fork event") {
        val forkedRepoPath = "./forked_repo/"
        val originalRepoPath = "./original_repo/"
        val forked = Git.cloneRepository()
                .setURI("https://github.com/yaronskaya/sourcerer-app.git")
                .setDirectory(File(forkedRepoPath))
                .call()
        val original = Git.cloneRepository()
                .setURI("https://github.com/sourcerer-io/sourcerer-app.git")
                .setDirectory(File(originalRepoPath))
                .call()
        val forkedLocalRepo = LocalRepo(forkedRepoPath)
        val originalLocalRepo = LocalRepo(originalRepoPath)

        val forkedRepoRehash = getRepoRehash(forked, forkedLocalRepo)
        val originalRepoRehash = getRepoRehash(original, originalLocalRepo)

        it("assigns different hashes for the original and the forked repos") {
            assertNotEquals(originalRepoRehash, forkedRepoRehash)
        }

        forked.repository.close()
        forked.close()
        original.repository.close()
        original.close()
    }

    given("lost server") {
        repo.commits = listOf(getLastCommit(git))

        val errors = mutableListOf<Throwable>()
        val mockApi = MockApi(mockRepo = repo)

        // Add some commits.
        val addedCommits = mutableListOf<Commit>()
        for (i in 0..3) {
            val message = "Created $i by author."
            val revCommit = git.commit().setMessage(message).call()
            addedCommits.add(Commit(revCommit))
        }

        // Remove one commit from server history.
        val removedCommit = addedCommits.removeAt(1)
        repo.commits = addedCommits.toList().asReversed()

        val observable = CommitCrawler.getObservable(gitHasher, repo)
        CommitHasher(repo, mockApi, repo.commits.map {it.rehash}, emails)
            .updateFromObservable(observable, { e -> errors.add(e) })

        it ("has no errors") {
            assertEquals(0, errors.size)
        }

        it("adds posts one commit as added and received commit is lost one") {
            assertEquals(1, mockApi.receivedAddedCommits.size)
            assertEquals(removedCommit, mockApi.receivedAddedCommits.last())
        }

        it("doesn't posts deleted commits") {
            assertEquals(0, mockApi.receivedDeletedCommits.size)
        }
    }*/

    given("commits with syntax stats") {

        val lines = listOf("x = [i**2 for i in range(9999)]", "def fn()", "x " +
                "= 1",
                "x = map(lambda x: x**2, range(9999))",
                "x = map(lambda x: x**2, map(lambda x: x**3, range(10))",
                "x = map(lambda x: x**2, range(10))," +
                        "map(lambda x: x**3, range(10)))")

        val author = Author(userName, userEmail)

        val testRepoPath = "../testrepo-commit-hasher-"
        val testRepo = TestRepo(testRepoPath + "python-facts")

        val mockApi = MockApi(mockRepo = repo)
        val observable = CommitCrawler.getObservable(testRepo.git, repo)

        it("sends stats") {
            for (i in 0..lines.size - 1) {
                val line = lines[i]
                val fileName = "file$i.py"
                testRepo.createFile(fileName, listOf(line))
                testRepo.commit(message = "$line in $fileName", author = author)
            }

            val errors = mutableListOf<Throwable>()

            val rehashes = (0..lines.size - 1).map { "r$it" }

            CommitHasher(repo, mockApi, rehashes, emails)
                    .updateFromObservable(observable, { e -> errors.add(e) })

            assertEquals(0, errors.size)

            val syntaxStats = mockApi.receivedAddedCommits
                .fold(mutableListOf<CommitStats>()) { allStats, commit ->
                    allStats.addAll(commit.stats)
                    allStats
                }.filter { it.type == ExtractorInterface.TYPE_SYNTAX }

            val mapStats = syntaxStats.filter { it.tech == "python>map" }
            val listStats = syntaxStats.filter { it.tech == "python>list" }
            assertEquals(3, mapStats.size)
            assertEquals(1, listStats.size)
            assertEquals(5, mapStats.map { it.numLinesAdded }.sum())
            assertEquals(0, mapStats.map { it.numLinesDeleted }.sum())

            assertEquals(1, listStats.map { it.numLinesAdded }.sum())
            assertEquals(0, listStats.map { it.numLinesDeleted }.sum())
        }

        afterGroup {
            testRepo.destroy()
        }
    }

    given("cpp repo") {
        val testRepo = TestRepo("../testrepo-commit-hasher-cpp-stats")
        val lines = listOf("#include <iostream>",
                "template <typename s, Input... inputs>",
                "struct Play<s, x, xs...> {",
                "    using type = cons<s, play<step_t<x, s>, xs...>>;", "};",
                "        template<typename x>")

        val author = Author(userName, userEmail)

        val mockApi = MockApi(mockRepo = repo)
        val observable = CommitCrawler.getObservable(testRepo.git, repo)

        it("sends stats") {
            for (i in 0..lines.size - 1) {
                val line = lines[i]
                val fileName = "file$i.cpp"
                testRepo.createFile(fileName, listOf(line))
                testRepo.commit(message = "$line in $fileName", author = author)
            }

            val errors = mutableListOf<Throwable>()

            val rehashes = (0..lines.size - 1).map { "r$it" }

            CommitHasher(repo, mockApi, rehashes, emails)
                    .updateFromObservable(observable, { e -> errors.add(e) })

            assertEquals(0, errors.size)

            val syntaxStats = mockApi.receivedAddedCommits
                    .fold(mutableListOf<CommitStats>()) { allStats, commit ->
                        allStats.addAll(commit.stats)
                        allStats
                    }.filter { it.type == ExtractorInterface.TYPE_SYNTAX }

            val templateStats = syntaxStats.filter { it.tech == "cpp>template" }
            assertEquals(2, templateStats.size)
            assertEquals(2, templateStats.map { it.numLinesAdded }.sum())
            assertEquals(0, templateStats.map { it.numLinesDeleted }.sum())
        }

    }
    given("commits with svelte files") {
        val lines = listOf("line 1", "line 2")

        val author = Author(userName, userEmail)

        val testRepoPath = "../testrepo-extractor-"
        val testRepo = TestRepo(testRepoPath + "svelte")

        val mockApi = MockApi(mockRepo = repo)
        val observable = CommitCrawler.getObservable(testRepo.git, repo)

        it("sends stats") {
            for (i in 0..lines.size - 1) {
                val line = lines[i]
                val fileName = "file$i.svelte"
                testRepo.createFile(fileName, listOf(line))
                testRepo.commit(message = "$line in $fileName", author = author)
            }

            val errors = mutableListOf<Throwable>()

            val rehashes = (0..lines.size - 1).map { "r$it" }

            CommitHasher(repo, mockApi, rehashes, emails)
                    .updateFromObservable(observable, { e -> errors.add(e) })

            assertEquals(0, errors.size)

            val syntaxStats = mockApi.receivedAddedCommits
                    .fold(mutableListOf<CommitStats>()) { allStats, commit ->
                        allStats.addAll(commit.stats)
                        allStats
                    }.filter { it.type == ExtractorInterface.TYPE_LIBRARY }

            val svelteStats = syntaxStats.filter { it.tech == "js.svelte" }
            assertEquals(2, svelteStats.size)
            assertEquals(2, svelteStats.map { it.numLinesAdded }.sum())
            assertEquals(0, svelteStats.map { it.numLinesDeleted }.sum())
        }

        afterGroup {
            testRepo.destroy()
        }
    }

    given("commits with quasar files") {
        val lines = listOf("module.exports = function (ctx) { }")

        val author = Author(userName, userEmail)

        val testRepoPath = "../testrepo-extractor-"
        val testRepo = TestRepo(testRepoPath + "quasar")

        val mockApi = MockApi(mockRepo = repo)
        val observable = CommitCrawler.getObservable(testRepo.git, repo)

        it("sends stats") {
            val fileName = "quasar.conf.js"
            testRepo.createFile(fileName, lines)
            testRepo.commit(message = "add quasar config", author = author)

            val errors = mutableListOf<Throwable>()

            val rehashes = (0..lines.size - 1).map { "r$it" }

            CommitHasher(repo, mockApi, rehashes, emails)
                    .updateFromObservable(observable, { e -> errors.add(e) })

            assertEquals(0, errors.size)

            val syntaxStats = mockApi.receivedAddedCommits
                    .fold(mutableListOf<CommitStats>()) { allStats, commit ->
                        allStats.addAll(commit.stats)
                        allStats
                    }.filter { it.type == ExtractorInterface.TYPE_LIBRARY }

            val quasarStats = syntaxStats.filter { it.tech == "js.quasar" }
            assertEquals(1, quasarStats.size)
            assertEquals(1, quasarStats.map { it.numLinesAdded }.sum())
            assertEquals(0, quasarStats.map { it.numLinesDeleted }.sum())
        }

        afterGroup {
            testRepo.destroy()
        }
    }

    given("commits with typescript files") {
        val lines = listOf("new Vue({", "line 2")

        val author = Author(userName, userEmail)

        val testRepoPath = "../testrepo-extractor-"
        val testRepo = TestRepo(testRepoPath + "typescript")

        val mockApi = MockApi(mockRepo = repo)
        val observable = CommitCrawler.getObservable(testRepo.git, repo)

        it("sends stats") {
            for (i in 0..lines.size - 1) {
                val line = lines[i]
                val fileName = "file$i.ts"
                testRepo.createFile(fileName, listOf(line))
                testRepo.commit(message = "$line in $fileName", author = author)
            }

            val errors = mutableListOf<Throwable>()

            val rehashes = (0..lines.size - 1).map { "r$it" }

            CommitHasher(repo, mockApi, rehashes, emails)
                    .updateFromObservable(observable, { e -> errors.add(e) })

            assertEquals(0, errors.size)

            val stats = mockApi.receivedAddedCommits
                    .fold(mutableListOf<CommitStats>()) { allStats, commit ->
                        allStats.addAll(commit.stats)
                        allStats
                    }
            val languageStats = stats.filter { it.type == ExtractorInterface.TYPE_LANGUAGE }
            val techStats = stats.filter { it.type == ExtractorInterface.TYPE_LIBRARY }
            assertEquals(2, languageStats.size)
            languageStats.forEach { stat ->
                assertEquals("typescript", stat.tech)
            }
            assertEquals(1, techStats.map { it.numLinesAdded }.sum())
            techStats.forEach { stat ->
                assertEquals("js.vue", stat.tech)
            }
        }

        afterGroup {
            testRepo.destroy()
        }
    }

    given("commits with scss stats") {

        val lines = listOf("first line in css file", "",
                "third line in css file")

        val author = Author(userName, userEmail)

        val testRepoPath = "../testrepo-extractor-"
        val testRepo = TestRepo(testRepoPath + "css")

        val mockApi = MockApi(mockRepo = repo)
        val observable = CommitCrawler.getObservable(testRepo.git, repo)

        it("sends stats") {
            for (i in 0..lines.size - 1) {
                val line = lines[i]
                val fileName = "file$i.scss"
                testRepo.createFile(fileName, listOf(line))
                testRepo.commit(message = "$line in $fileName", author = author)
            }

            val errors = mutableListOf<Throwable>()

            val rehashes = (0..lines.size - 1).map { "r$it" }

            CommitHasher(repo, mockApi, rehashes, emails)
                    .updateFromObservable(observable, { e -> errors.add(e) })

            assertEquals(0, errors.size)

            val syntaxStats = mockApi.receivedAddedCommits
                    .fold(mutableListOf<CommitStats>()) { allStats, commit ->
                        allStats.addAll(commit.stats)
                        allStats
                    }.filter { it.type == ExtractorInterface.TYPE_LIBRARY }

            val scssStats = syntaxStats.filter { it.tech == "scss" }
            assertEquals(2, scssStats.size)
            assertEquals(2, scssStats.map { it.numLinesAdded }.sum())
            assertEquals(0, scssStats.map { it.numLinesDeleted }.sum())
        }

        afterGroup {
            testRepo.destroy()
        }
    }

    given("commit with multiple authors") {
        val lines = listOf("line 1", "line 2", "line 3", "line 4")

        val author1 = Author(userName, userEmail)
        val author2 = Author(secondUserName, secondUserEmail)

        val testRepoPath = "../testrepo-multiple-authors"
        val testRepo = TestRepo(testRepoPath)

        val mockApi = MockApi(mockRepo = repo)

        it("sends stats") {
            for (i in 0..lines.size - 1) {
                val line = lines[i]
                val fileName = "file$i.ext"
                testRepo.createFile(fileName, listOf(line))
                val message = "$line in $fileName\n\nCo-authored-by: ${author2
                        .name} <${author2.email}>"
                testRepo.commit(message = message, author = author1)
            }
            val gitHasherIn = Git.open(File(testRepoPath))
            val jgitObservable = CommitCrawler.getJGitObservable(gitHasherIn,
                extractCoauthors = true)
            val observable = CommitCrawler.getObservable(gitHasherIn,
                    jgitObservable, repo)

            val errors = mutableListOf<Throwable>()

            val rehashes = (0..lines.size - 1).map { "r$it" }

            CommitHasher(repo, mockApi, rehashes, emails)
                    .updateFromObservable(observable, { e -> errors.add(e) })

            assertEquals(0, errors.size)

            val stats = mockApi.receivedAddedCommits
            val actualAuthors = stats.map { it.author }.toHashSet()
            assertEquals(2, actualAuthors.size)
            assertTrue(author1 in actualAuthors)
            assertTrue(author2 in actualAuthors)
        }
    }

    cleanRepos()
})
