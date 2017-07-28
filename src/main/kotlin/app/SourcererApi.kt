// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app

import app.model.Commit
import app.model.User
import app.utils.RequestException
import com.github.kittinunf.fuel.Fuel
import com.github.kittinunf.fuel.core.FuelError
import com.github.kittinunf.fuel.core.FuelManager
import com.github.kittinunf.fuel.core.Request
import com.github.kittinunf.result.Result

/**
 * Sourcerer API.
 */
object SourcererApi {
    init {
        FuelManager.instance.basePath = "http://localhost:8080"
    }

    val username
        get() = Configurator.getUsername()

    val password
        get() = Configurator.getPassword()

    private fun createRequestGetUser(): Request {
        return Fuel.get("/user/info").authenticate(username, password)
    }

    private fun createRequestPostCommit(commit: Commit): Request {
        return Fuel.post("/commit").authenticate(username, password)
                   .body(commit.serialize())
    }

    private fun <T> makeBlockingRequest(request: Request, requestName: String,
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
        }

    }

    private fun makeAsyncRequest(request: Request, requestName: String,
                                 success: (String) -> Unit,
                                 failure: (String) -> Unit) {
        Logger.debug("Request $requestName initialized")
        request.responseString { _, _, result ->
            when (result) {
                is Result.Success -> {
                    Logger.debug("Request $requestName success")
                    success(result.get())
                }
                is Result.Failure -> {
                    Logger.error("Request $requestName error",
                                 result.getException())
                    failure(result.get())
                }
            }
        }
        Logger.debug("Request $requestName success")
    }

    fun getUserBlocking(): User {
        return makeBlockingRequest(createRequestGetUser(),
                       "getUserBlocking",
                                   { body -> User().parseFrom(body) })
    }

    fun getUserAsync(success: (String) -> Unit, failure: (String) -> Unit) {
        makeAsyncRequest(createRequestGetUser(), "getUserAsync",
                success, failure)
    }

    fun postCommitBlocking(commit: Commit): String {
        return makeBlockingRequest(createRequestPostCommit(commit),
                       "postCommitBlocking", { it })
    }

    fun postCommitAsync(commit: Commit, success: (String) -> Unit,
                   failure: (String) -> Unit) {
        makeAsyncRequest(createRequestPostCommit(commit),
                "postCommitAsync", success, failure)
    }
}
