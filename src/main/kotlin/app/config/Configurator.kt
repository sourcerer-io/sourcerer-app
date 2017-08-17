// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.config

import app.model.LocalRepo
import app.model.Repo
import app.utils.Options

interface Configurator {
    fun setOptions(options: Options)
    fun getUsername(): String
    fun getPassword(): String
    fun isValidCredentials(): Boolean
    fun getLocalRepos(): List<LocalRepo>
    fun getRepos(): List<Repo>
    fun setUsernameCurrent(username: String)
    fun setPasswordCurrent(password: String)
    fun setUsernamePersistent(username: String)
    fun setPasswordPersistent(password: String)
    fun addLocalRepoPersistent(localRepo: LocalRepo)
    fun removeLocalRepoPersistent(localRepo: LocalRepo)
    fun setRepos(repos: List<Repo>)
    fun isFirstLaunch(): Boolean
    fun loadFromFile()
    fun saveToFile()
    fun resetAndSave()
}
