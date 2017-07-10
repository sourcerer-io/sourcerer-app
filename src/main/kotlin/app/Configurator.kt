// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app

import app.utils.Options
import app.utils.UsernameValidator
import org.apache.commons.codec.digest.DigestUtils
import java.io.File
import java.io.IOException
import org.apache.commons.configuration.ConfigurationException
import org.apache.commons.configuration.PropertiesConfiguration

/**
 * Configurator is a singleton class that manages configuration files and
 * values of non-command specific options.
 */
object Configurator {
    val configFileName = "sourcerer.properties"
    val configUsername = "username"
    val configPassword = "password"
    val configSilent = "silent"

    // Options levels are presented in priority decreasing order.
    private var current: Options = Options()  // Command-line arguments.
    private var config: Options = Options()  // Global user defined config file.
    private val default: Options  // Default values.
        get() {
            val default = Options()
            default.silent = false
            return default
        }

    val options: Options  // Final options that will be used by app.
        get() = mergeLevels()

    // User directory path.
    val userDir = try {
        System.getProperty("user.home")
    }
    catch (e: SecurityException) { null }

    init {
        if (userDir != null) {
            config = loadConfig(userDir)
        }
    }

    // Merges different levels of options into one options object in the next
    // order: current, local, user, default.
    private fun mergeLevels(): Options {
        val levels = arrayListOf(current, config, default)
        val merged = Options()

        for (level in levels) {
            if (merged.username == null) {
                merged.username = level.username
            }
            if (merged.password == null) {
                merged.password = level.password
            }
            if (merged.silent == null) {
                merged.silent = level.silent
            }
        }

        return merged
    }

    // Loads config file from specified path.
    fun loadConfig(path: String): Options {
        val options = Options()

        try {
            val file = File(path, configFileName)

            if (!file.exists() || !file.isFile) {
                return options  // No configuration file
            }

            val config = PropertiesConfiguration(file)

            // Accessing configuration properties. Unknown values should be
            // null to distinguish them from specified values from other levels.
            options.username = config.getString(configUsername, null)
            options.password = config.getString(configPassword, null)
            options.silent = config.getBoolean(configSilent, null)
        }
        catch (e: ConfigurationException) {
            // Error while loading the properties file.
        }
        catch (e: SecurityException) {
            // Read access denied.
        }

        return options
    }

    // Saves config file to specified path. Returns true on success.
    fun saveConfig(path: String, options: Options): Boolean {
        try {
            val file = File(path, configFileName)

            file.createNewFile()  // Creates a new file if it didn't exist.

            val config = PropertiesConfiguration(file)

            if (options.username != null) {
                config.setProperty(configUsername, options.username)
            }
            if (options.password != null) {
                config.setProperty(configPassword, options.password)
            }
            if (options.silent != null) {
                config.setProperty(configSilent, options.silent)
            }

            config.save(file)

            return true
        }
        catch (e: IOException) {
            // IO error occurred.
        }
        catch (e: SecurityException) {
            // Read access denied.
        }
        catch (e: ConfigurationException) {
            // Error while loading or saving the properties file.
        }

        return false
    }

    fun setCurrentOptions(options: Options) {
        options.password = DigestUtils.sha256Hex(options.password)
        current = options
    }

    fun createOptions(pair: List<String>): Options {
        val options = Options()

        if (pair.count() != 2) {
            return options
        }

        val (key, value) = pair

        when (key) {
            configUsername -> {
                if (UsernameValidator().isValidUsername(value)) {
                    options.username = value
                }
            }
            configPassword -> {
                options.password = DigestUtils.sha256Hex(value)

            }
            configSilent -> {
                options.silent = value.toBoolean()
            }
        }

        return options
    }
}
