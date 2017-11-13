// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.api

import app.BuildConfig
import app.Logger
import app.config.Configurator
import app.model.Author
import app.model.AuthorGroup
import app.model.Commit
import app.model.CommitGroup
import app.model.Fact
import app.model.FactGroup
import app.model.Repo
import app.model.User
import com.github.kittinunf.fuel.core.FuelManager
import com.github.kittinunf.fuel.core.Method
import com.github.kittinunf.fuel.core.Request
import com.github.kittinunf.fuel.core.Response
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

class ServerApi (private val configurator: Configurator) : Api {
    companion object {
        private val HEADER_VERSION_CODE = "app-version-code"
        private val HEADER_CONTENT_TYPE = "Content-Type"
        private val HEADER_CONTENT_TYPE_PROTO = "application/octet-stream"
        private val HEADER_COOKIE = "Cookie"
        private val HEADER_SET_COOKIE = "Set-Cookie"
        private val KEY_TOKEN = "Token="
    }

    private val fuelManager = FuelManager()
    private var token = ""

    private fun cookieRequestInterceptor() = { req: Request ->
        if (token.isNotEmpty()) {
            req.header(Pair(HEADER_COOKIE, KEY_TOKEN + token))
        }
        req
    }

    private fun cookieResponseInterceptor() = { _: Request, res: Response ->
        val newToken = res.headers[HEADER_SET_COOKIE]
            ?.find { it.startsWith(KEY_TOKEN) }
        if (newToken != null && newToken.isNotBlank()) {
            token = newToken.substringAfter(KEY_TOKEN).substringBefore(';')
        }
        res
    }

    init {
        fuelManager.basePath = BuildConfig.API_BASE_PATH
        fuelManager.addRequestInterceptor { cookieRequestInterceptor() }
        fuelManager.addResponseInterceptor { cookieResponseInterceptor() }
    }

    private val username
        get() = configurator.getUsername()

    private val password
        get() = configurator.getPassword()

    private fun post(path: String): Request {
        return fuelManager.request(Method.POST, path)
    }

    private fun get(path: String): Request {
        return fuelManager.request(Method.GET, path)
    }

    private fun delete(path: String): Request {
        return fuelManager.request(Method.DELETE, path)
    }

    private fun createRequestGetToken(): Request {
        return post("/auth").authenticate(username, password)
                   .header(getVersionCodeHeader())
    }

    private fun createRequestGetUser(): Request {
        return get("/user")
    }

    private fun createRequestGetRepo(repoRehash: String): Request {
        return get("/repo/$repoRehash")
    }

    private fun createRequestPostRepo(repo: Repo): Request {
        return post("/repo").header(getContentTypeHeader())
                            .body(repo.serialize())
    }

    private fun createRequestPostCommits(commits: CommitGroup): Request {
        return post("/commits").header(getContentTypeHeader())
                               .body(commits.serialize())
    }

    private fun createRequestDeleteCommits(commits: CommitGroup): Request {
        return delete("/commits").header(getContentTypeHeader())
                                 .body(commits.serialize())
    }

    private fun createRequestPostFacts(facts: FactGroup): Request {
        return post("/facts").header(getContentTypeHeader())
                             .body(facts.serialize())
    }

    private fun createRequestPostAuthors(authors: AuthorGroup): Request {
        return post("/authors").header(getContentTypeHeader())
                               .body(authors.serialize())
    }

    private fun <T> makeRequest(request: Request,
                                requestName: String,
                                parser: (ByteArray) -> T): Result<T> {
        var error: ApiError? = null
        var data: T? = null

        try {
            Logger.debug { "Request $requestName initialized" }
            val (_, res, result) = request.responseString()
            val (_, e) = result
            if (e == null) {
                Logger.debug { "Request $requestName success" }
                data = parser(res.data)
            } else {
                error = ApiError(e)
            }
        } catch (e: InvalidProtocolBufferException) {
            error = ApiError(e)
        } catch (e: InvalidParameterException) {
            error = ApiError(e)
        }

        return Result(data, error)
    }

    private fun getVersionCodeHeader(): Pair<String, String> {
        return Pair(HEADER_VERSION_CODE, BuildConfig.VERSION_CODE.toString())
    }

    private fun getContentTypeHeader(): Pair<String, String> {
        return Pair(HEADER_CONTENT_TYPE, HEADER_CONTENT_TYPE_PROTO)
    }

    override fun authorize(): Result<Unit> {
        return makeRequest(createRequestGetToken(), "getToken", {})
    }

    override fun getUser(): Result<User> {
        return makeRequest(createRequestGetUser(), "getUser",
                           { body -> User(body) })
    }

    override fun getRepo(repoRehash: String): Result<Repo> {
        if (repoRehash.isBlank()) {
            throw IllegalArgumentException()
        }

        return makeRequest(createRequestGetRepo(repoRehash), "getRepo",
                           { body -> Repo(body) })
    }

    override fun postRepo(repo: Repo): Result<Unit> {
        return makeRequest(createRequestPostRepo(repo),
                           "postRepo", {})
    }

    override fun postCommits(commitsList: List<Commit>): Result<Unit> {
        val commits = CommitGroup(commitsList)
        return makeRequest(createRequestPostCommits(commits),
                           "postCommits", {})
    }

    override fun deleteCommits(commitsList: List<Commit>): Result<Unit> {
        val commits = CommitGroup(commitsList)
        return makeRequest(createRequestDeleteCommits(commits),
                           "deleteCommits", {})
    }

    override fun postFacts(factsList: List<Fact>): Result<Unit> {
        val facts = FactGroup(factsList)
        return makeRequest(createRequestPostFacts(facts), "postFacts", {})
    }

    override fun postAuthors(authorsList: List<Author>): Result<Unit> {
        val authors = AuthorGroup(authorsList)
        return makeRequest(createRequestPostAuthors(authors), "postAuthors", {})
    }
}
