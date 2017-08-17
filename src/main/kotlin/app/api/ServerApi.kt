// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.api

import app.BuildConfig
import app.Logger
import app.config.Configurator
import app.model.Commit
import app.model.Commits
import app.model.Repo
import app.model.User
import app.utils.RequestException
import com.github.kittinunf.fuel.Fuel
import com.github.kittinunf.fuel.core.FuelError
import com.github.kittinunf.fuel.core.FuelManager
import com.github.kittinunf.fuel.core.Request
import com.github.kittinunf.fuel.core.Response
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

class ServerApi (private val configurator: Configurator) : Api {
    private val HEADER_VERSION_CODE = "app-version-code"
    private val HEADER_CONTENT_TYPE = "Content-Type"
    private val HEADER_CONTENT_TYPE_PROTO = "application/octet-stream"
    private val HEADER_COOKIE = "Cookie"
    private val HEADER_SET_COOKIE = "Set-Cookie"
    private val KEY_TOKEN = "token="

    private var token = ""

    private fun cookieRequestInterceptor(): (Request) -> Request =
        { request: Request ->
            if (token.isNotEmpty()) {
                request.header(Pair(HEADER_COOKIE, KEY_TOKEN + token))
            }
            request
        }

    private fun cookieResponseInterceptor(): (Request, Response) -> Response =
        { request: Request, response: Response ->
            val newToken = response.httpResponseHeaders[HEADER_SET_COOKIE]
                ?.find { it.startsWith(KEY_TOKEN) }
            if (newToken != null && newToken.isNotBlank()) {
                token = newToken.substringAfter(KEY_TOKEN)
                    .substringBefore(';')
            }
            response
        }

    init {
        val fuelManager = FuelManager.instance
        fuelManager.basePath = "http://localhost:8080"
        fuelManager.addRequestInterceptor { cookieRequestInterceptor() }
        fuelManager.addResponseInterceptor { cookieResponseInterceptor() }
    }

    private val username
        get() = configurator.getUsername()

    private val password
        get() = configurator.getPassword()

    private fun createRequestGetToken(): Request {
        return Fuel.get("/token").authenticate(username, password)
                   .header(getVersionCodeHeader())
    }

    private fun createRequestGetUser(): Request {
        return Fuel.get("/user")
    }

    private fun createRequestGetRepo(repoRehash: String): Request {
        return Fuel.get("/repo/$repoRehash")
    }

    private fun createRequestPostRepo(repo: Repo): Request {
        return Fuel.post("/repo").header(getContentTypeHeader())
                   .body(repo.serialize())
    }

    private fun createRequestPostCommits(commits: Commits): Request {
        return Fuel.post("/commits").header(getContentTypeHeader())
                   .body(commits.serialize())
    }

    private fun createRequestDeleteCommits(commits: Commits): Request {
        return Fuel.delete("/commits").header(getContentTypeHeader())
                   .body(commits.serialize())
    }

    private fun <T> makeRequest(request: Request,
                                requestName: String,
                                parser: (String) -> T): T {
        try {
            Logger.debug("Request $requestName initialized")
            val (_, _, result) = request.responseString()
            val body = result.get()
            Logger.debug("Request $requestName success")
            return parser(body)
        } catch (e: FuelError) {
            Logger.error("Request $requestName error", e)
            throw RequestException(e)
        } catch (e: InvalidProtocolBufferException) {
            Logger.error("Request $requestName error while parsing", e)
            throw RequestException(e)
        } catch (e: InvalidParameterException) {
            Logger.error("Request $requestName error while parsing", e)
            throw RequestException(e)
        }
    }

    private fun getVersionCodeHeader(): Pair<String, String> {
        return Pair(HEADER_VERSION_CODE, BuildConfig.VERSION_CODE.toString())
    }

    private fun getContentTypeHeader(): Pair<String, String> {
        return Pair(HEADER_CONTENT_TYPE, HEADER_CONTENT_TYPE_PROTO)
    }

    override fun authorize() {
        return makeRequest(createRequestGetToken(), "getToken", {})
    }

    override fun getUser(): User {
        return makeRequest(createRequestGetUser(), "getUser",
                           { body -> User(body) })
    }

    override fun getRepo(repoRehash: String): Repo {
        if (repoRehash.isBlank()) {
            throw IllegalArgumentException()
        }

        return makeRequest(createRequestGetRepo(repoRehash), "getRepo",
                           { body -> Repo(body) })
    }

    override fun postRepo(repo: Repo) {
        makeRequest(createRequestPostRepo(repo),
                    "postRepo", {})
    }

    override fun postCommits(commitsList: List<Commit>) {
        val commits = Commits(commitsList)
        makeRequest(createRequestPostCommits(commits),
                    "postCommits", {})
    }

    override fun deleteCommits(commitsList: List<Commit>) {
        val commits = Commits(commitsList)
        makeRequest(createRequestDeleteCommits(commits),
                    "deleteCommits", {})
    }
}
