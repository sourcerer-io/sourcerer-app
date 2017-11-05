// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.Analytics
import app.BuildConfig
import app.Logger
import app.api.Api
import app.config.Configurator
import app.utils.PasswordHelper
import app.utils.RequestException

/**
 * Authorization console UI state.
 */
class AuthState constructor(private val context: Context,
                            private val api: Api,
                            private val configurator: Configurator)
    : ConsoleState {
    var username = ""
    var password = ""
    var connectionError = false

    override fun doAction() {
        if (!configurator.isValidCredentials()) {
            getUsername()
            getPassword()
        }

        while (!tryAuth() && !connectionError) {
            getPassword()
        }
    }

    override fun next() {
        if (!connectionError) {
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
            api.authorize()

            val user = api.getUser()
            configurator.setRepos(user.repos)

            println("You are successfully authenticated. Your profile page is "
                    + BuildConfig.PROFILE_URL + configurator.getUsername())
            saveCredentialsIfChanged()

            Logger.username = configurator.getUsername()
            Logger.info(Logger.Events.AUTH) { "Auth success" }

            return true
        } catch (e: RequestException) {
            if (e.isAuthError) {
                if(e.httpBodyMessage.isNotBlank()) {
                    println(e.httpBodyMessage)
                } else {
                    println("Authentication error. Try again.")
                }
            } else {
                connectionError = true
                println("Connection problems. Try again later.")
            }
        }
        return false
    }
}
