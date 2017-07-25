// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.Configurator
import app.SourcererApi
import app.utils.PasswordHelper

/**
 * Authorization console UI state.
 */
class AuthState constructor(val context: Context) : ConsoleState {
    override fun doAction() {
        var username = ""
        var password = ""
        var isCredentialsUnknown = !Configurator.isValidCredentials()

        if (isCredentialsUnknown) {
            println("Enter Sourcerer account username:")
            username = readLine() ?: ""
            Configurator.setUsernameCurrent(username)
        }

        while (true) {
            if (isCredentialsUnknown) {
                println("Enter Sourcerer account password:")
                password = PasswordHelper.readPassword()
                Configurator.setPasswordCurrent(password)
            }

            println("Authorising...")
            val result = SourcererApi.getUserBlocking().profileUrl

            if (result.isNotEmpty()) {  // TODO(anatoly): Check for status 200.
                println("You are successfully authorised. Your profile page is "
                        + "http://sourcerer.io/007.")

                // Save username and password to config file.
                if (isCredentialsUnknown) {
                    Configurator.setUsernamePersistent(username)
                    Configurator.setPasswordPersistent(password)
                    Configurator.saveToFile()
                }

                break
            }

            isCredentialsUnknown = true
        }
    }

    override fun next() {
        context.changeState(ListRepoState(context))
    }
}
