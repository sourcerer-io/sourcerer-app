// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.BuildConfig
import app.Logger
import app.api.Api
import app.config.Configurator
import app.utils.PasswordHelper
import app.api.ApiError
import app.api.ifNotNullThrow
import app.api.isWithServerCode

/**
 * Authorization console UI state.
 */
class AuthState constructor(private val context: Context,
                            private val api: Api,
                            private val configurator: Configurator)
    : ConsoleState {
    var username = ""
    var password = ""
    var retry = true
    var authorized = false

    override fun doAction() {
        if (!configurator.isValidCredentials()) {
            getUsername()
            getPassword()
        }

        authorized = tryAuth()
        while (!authorized && retry) {
            getPassword()
            authorized = tryAuth()
        }
    }

    override fun next() {
        if (authorized) {
            context.changeState(ListRepoState(context, api, configurator))
        } else {
            context.changeState(CloseState())
        }
    }

    fun getUsername() {
        println("Enter username:")
        username = readLine() ?: ""
        configurator.setUsernameCurrent(username)
    }

    fun getPassword() {
        println("Enter password:")
        password = PasswordHelper.readPassword()
        configurator.setPasswordCurrent(password)
    }

    fun saveCredentialsIfChanged() {
        if (username.isNotEmpty()) {
            configurator.setUsernamePersistent(username)
        }
        if (password.isNotEmpty()) {
            configurator.setPasswordPersistent(password)
        }
        if (username.isNotEmpty() || password.isNotEmpty()) {
            configurator.saveToFile()
        }
    }

    fun tryAuth(): Boolean {
        try {
            println("Authenticating...")
            val (_, error) = api.authorize()
            if (error.isWithServerCode(Api.OUT_OF_DATE)) {
                println("App is out of date. Please get new version at " +
                        "https://sourcerer.io")
                retry = false
                return false
            }
            // Other request errors should be processed by try/catch.
            error.ifNotNullThrow()

            val user = api.getUser().getOrThrow()
            configurator.setUser(user)

            println("You are successfully authenticated. Your profile page is "
                    + BuildConfig.PROFILE_URL + configurator.getUsername())

            saveCredentialsIfChanged()
            Logger.username = configurator.getUsername()
            Logger.info(Logger.Events.AUTH) { "Auth success" }

            return true
        } catch (e: ApiError) {
            if (e.isAuthError) {
                if (e.httpBodyMessage.isNotBlank()) {
                    println(e.httpBodyMessage)
                } else {
                    println("Authentication error. Try again.")
                }
            } else {
                Logger.error(e)
                println("Connection problems. Try again later.")
                retry = false
            }
        }

        return false
    }
}
