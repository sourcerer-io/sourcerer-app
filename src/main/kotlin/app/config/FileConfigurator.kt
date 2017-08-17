// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.config

import app.Logger
import app.model.LocalRepo
import app.model.Repo
import app.utils.Options
import app.utils.PasswordHelper
import com.fasterxml.jackson.annotation.JsonAutoDetect.Visibility
import com.fasterxml.jackson.annotation.PropertyAccessor
import com.fasterxml.jackson.core.JsonParseException
import com.fasterxml.jackson.databind.JsonMappingException
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory
import com.fasterxml.jackson.module.kotlin.KotlinModule
import java.io.IOException
import java.lang.IllegalStateException
import java.nio.file.Files
import java.nio.file.InvalidPathException
import java.nio.file.NoSuchFileException
import java.nio.file.Paths

/**
 * Singleton class that manage configs and CLI options.
 */
class FileConfigurator : Configurator {
    /**
     * Persistent configuration file name.
     */
    private val CONFIG_FILE_NAME = ".sourcerer"

    // Config levels are presented in priority decreasing order.

    /**
     * Configuration based on CLI arguments or temporary user entered data.
     */
    private var current: Config = Config()

    /**
     * Persistent configuration saved in [userDir] in YAML format.
     */
    private var persistent: Config = Config()

    /**
     * Default configuration.
     */
    private val default: Config = Config()

    /**
     * Merger of all configuration levels. Is used to get properties.
     */
    private val config: Config
        get() = default.merge(persistent).merge(current)

    /**
     * Command-line arguments. Updates [current] on set.
     */
    private var options: Options = Options()

    /**
     * Used to temporarily save list of repos that known by server.
     */
    private var repos: List<Repo> = listOf()

    /**
     * User directory path is where persistent config stored.
     */
    private val userDir = try {
        System.getProperty("user.home")
    }
    catch (e: SecurityException) {
        Logger.error("Cannot access user directory", e)
        null
    }

    /**
     * Jackson's ObjectMapper.
     */
    private val mapper = createMapper()

    /**
     * Initializer that loads persistent config.
     */
    init {
        loadFromFile()
    }

    /**
     * Creates and setups Jackson's ObjectMapper.
     */
    private fun createMapper(): ObjectMapper {
        return ObjectMapper(YAMLFactory())  // Enable YAML parsing.
                // Map only fields (not getters, etc).
                .setVisibility(PropertyAccessor.ALL, Visibility.NONE)
                .setVisibility(PropertyAccessor.FIELD, Visibility.ANY)
                .registerModule(KotlinModule())  // Enable Kotlin support.
    }

    override fun setOptions(options: Options) {
        current.merge(options)
        this.options = options
    }

    /**
     * Gets username from merger of all configuration levels.
     */
    override fun getUsername(): String {
        return config.username
    }

    /**
     * Gets hashed password from merger of all configuration levels.
     */
    override fun getPassword(): String {
        return config.password
    }

    /**
     * Checks for non empty credentials from merger of all configuration levels.
     */
    override fun isValidCredentials(): Boolean {
        return config.username.isNotEmpty() && config.password.isNotEmpty()
    }

    /**
     * Gets list of repos from merger of all configuration levels.
     */
    override fun getLocalRepos(): List<LocalRepo> {
        return config.localRepos.toList()
    }

    /**
     * Gets list of temprorary saved repos.
     */
    override fun getRepos(): List<Repo> {
        return repos
    }

    /**
     * Sets username to current launch temprorary config.
     */
    override fun setUsernameCurrent(username: String) {
        current.username = username
    }

    /**
     * Sets and hashes password to current launch temprorary config.
     */
    override fun setPasswordCurrent(password: String) {
        current.password = PasswordHelper.hashPassword(password)
    }

    /**
     * Sets username to persistent config. Use [saveToFile] to save.
     */
    override fun setUsernamePersistent(username: String) {
        persistent.username = username
    }

    /**
     * Sets and hashes password to persistent config. Use [saveToFile] to save.
     */
    override fun setPasswordPersistent(password: String) {
        persistent.password = PasswordHelper.hashPassword(password)
    }

    /**
     * Add repo to persistent config. Use [saveToFile] to save.
     */
    override fun addLocalRepoPersistent(localRepo: LocalRepo) {
        persistent.addRepo(localRepo)
    }

    /**
     * Remove repo from persistent config. Use [saveToFile] to save.
     */
    override fun removeLocalRepoPersistent(localRepo: LocalRepo) {
        persistent.removeRepo(localRepo)
    }

    /**
     * Temporarily sets list of repos.
     */
    override fun setRepos(repos: List<Repo>) {
        this.repos = repos
    }

    /**
     * Defines whether this is the first run. If any fields are defined then no.
     */
    override fun isFirstLaunch(): Boolean {
        return persistent.password.isEmpty()
                && persistent.username.isEmpty()
                && persistent.localRepos.isEmpty()
    }

    /**
     * Loads [persistent] configuration from config file stored in [userDir].
     */
    override fun loadFromFile() {
        if (userDir == null) {
            return
        }

        // Сonfig initialization in case an exception is thrown.
        var loadConfig = Config()

        try {
            loadConfig = Files.newBufferedReader(Paths.get(userDir,
                CONFIG_FILE_NAME)).use {
                mapper.readValue(it, Config::class.java)
            }
        } catch (e: IOException) {
            if(e is NoSuchFileException){
                Logger.info("No config file found")
            } else {
                Logger.error("Cannot access config file", e)
            }
        } catch (e: SecurityException) {
            Logger.error("Cannot access config file", e)
        } catch (e: InvalidPathException) {
            Logger.error("Cannot access config file", e)
        } catch (e: JsonParseException) {
            Logger.error("Cannot parse config file", e)
        } catch (e: JsonMappingException) {
            Logger.error("Cannot parse config file", e)
        } catch (e: IllegalStateException) {
            Logger.error("Cannot parse config file", e)
        }

        persistent = loadConfig
    }

    /**
     * Saves [persistent] configuration to config file stored in [userDir].
     */
    override fun saveToFile() {
        try {
            Files.newBufferedWriter(Paths.get(userDir, CONFIG_FILE_NAME)).use {
                mapper.writeValue(it, persistent)
            }
        } catch (e: IOException) {
            Logger.error("Cannot save config file", e)
        } catch (e: SecurityException) {
            Logger.error("Cannot save config file", e)
        } catch (e: InvalidPathException) {
            Logger.error("Cannot save config file", e)
        } catch (e: JsonParseException) {
            Logger.error("Cannot parse config file", e)
        } catch (e: JsonMappingException) {
            Logger.error("Cannot parse config file", e)
        } catch (e: IllegalStateException) {
            Logger.error("Cannot parse config file", e)
        }
    }

    /**
     * Resets all configurations, CLI options and config file.
     */
    override fun resetAndSave() {
        options = Options()
        persistent = Config()
        saveToFile()
    }
}
