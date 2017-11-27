// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.config

import app.model.LocalRepo
import app.model.User
import app.utils.Options

interface Configurator {
    fun setOptions(options: Options)
    fun getUsername(): String
    fun getPassword(): String
    fun isValidCredentials(): Boolean
    fun getLocalRepos(): List<LocalRepo>
    fun getUser(): User
    fun setUsernameCurrent(username: String)
    fun setPasswordCurrent(password: String)
    fun getUuidPersistent(): String
    fun setUsernamePersistent(username: String)
    fun setPasswordPersistent(password: String)
    fun addLocalRepoPersistent(localRepo: LocalRepo)
    fun removeLocalRepoPersistent(localRepo: LocalRepo)
    fun setUser(user: User)
    fun isFirstLaunch(): Boolean
    fun loadFromFile()
    fun saveToFile()
    fun resetAndSave()
}
