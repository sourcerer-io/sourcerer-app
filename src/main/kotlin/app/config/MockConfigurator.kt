// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.config

import app.model.LocalRepo
import app.model.Repo
import app.utils.Options

class MockConfigurator(var mockUsername: String = "",
                       var mockPassword: String = "",
                       var mockIsValidCredentials: Boolean = true,
                       var mockIsFirstLaunch: Boolean = true,
                       var mockRepos: MutableList<Repo> = mutableListOf(),
                       var mockLocalRepos: MutableList<LocalRepo> =
                           mutableListOf(),
                       var uuid: String = "") : Configurator {
    var mockCurrent: Config = Config()
    var mockPersistent: Config = Config()
    var mockOptions: Options = Options()

    override fun setOptions(options: Options) {
        mockOptions = options
    }

    override fun getUsername(): String {
        return mockUsername
    }

    override fun getPassword(): String {
        return mockPassword
    }

    override fun isValidCredentials(): Boolean {
        return mockIsValidCredentials
    }

    override fun getLocalRepos(): List<LocalRepo> {
        return mockLocalRepos
    }

    override fun getRepos(): List<Repo> {
        return mockRepos
    }

    override fun setUsernameCurrent(username: String) {
        mockCurrent.username = username
    }

    override fun setPasswordCurrent(password: String) {
        mockCurrent.password = password
    }

    override fun getUuidPersistent(): String {
        return uuid
    }

    override fun setUsernamePersistent(username: String) {
        mockPersistent.username = username
    }

    override fun setPasswordPersistent(password: String) {
        mockPersistent.password = password
    }

    override fun addLocalRepoPersistent(localRepo: LocalRepo) {
        mockPersistent.localRepos.remove(localRepo)
        mockPersistent.localRepos.add(localRepo)
    }

    override fun removeLocalRepoPersistent(localRepo: LocalRepo) {
        mockPersistent.localRepos.remove(localRepo)
    }

    override fun setRepos(repos: List<Repo>) {
        mockRepos = repos.toMutableList()
    }

    override fun isFirstLaunch(): Boolean {
        return mockIsFirstLaunch
    }

    override fun loadFromFile() {}

    override fun saveToFile() {}

    override fun resetAndSave() {}
}
