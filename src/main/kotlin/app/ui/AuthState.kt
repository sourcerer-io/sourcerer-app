// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.BuildConfig
import app.Configurator
import app.api.Api
import app.utils.PasswordHelper
import app.utils.RequestException

/**
 * Authorization console UI state.
 */
class AuthState constructor(private val context: Context,
                            private val api: Api) : ConsoleState {
    var username = ""
    var password = ""
    var connectionError = false

    override fun doAction() {
        if (!Configurator.isValidCredentials()) {
            getUsername()
            getPassword()
        }

        while (!tryAuth() && !connectionError) {
            getPassword()
        }
    }

    override fun next() {
        if (!connectionError) {
            context.changeState(ListRepoState(context, api))
        } else {
            context.changeState(CloseState(context, api))
        }
    }

    fun getUsername() {
        println("Enter username:")
        username = readLine() ?: ""
        Configurator.setUsernameCurrent(username)
    }

    fun getPassword() {
        println("Enter password:")
        password = PasswordHelper.readPassword()
        Configurator.setPasswordCurrent(password)
    }

    fun saveCredentialsIfChanged() {
        if (username.isNotEmpty()) {
            Configurator.setUsernamePersistent(username)
        }
        if (password.isNotEmpty()) {
            Configurator.setPasswordPersistent(password)
        }
        if (username.isNotEmpty() || password.isNotEmpty()) {
            Configurator.saveToFile()
        }
    }

    fun tryAuth(): Boolean {
        try {
            println("Authenticating...")
            api.authorize()

            val user = api.getUser()
            Configurator.setRepos(user.repos)

            println("You are successfully authenticated. Your profile page is "
                    + BuildConfig.PROFILE_URL + Configurator.getUsername())
            saveCredentialsIfChanged()
            return true
        } catch (e: RequestException) {
            if (e.isAuthError) {
                println("Incorrect username or password. Try again.")
            } else {
                connectionError = true
                println("Connection problems. Try again later.")
            }
        }
        return false
    }
}
