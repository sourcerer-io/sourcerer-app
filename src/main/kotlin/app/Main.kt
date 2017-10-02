// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app

import app.api.ServerApi
import app.config.FileConfigurator
import app.model.LocalRepo
import app.ui.ConsoleUi
import app.utils.CommandConfig
import app.utils.CommandAdd
import app.utils.CommandList
import app.utils.CommandRemove
import app.utils.Options
import app.utils.PasswordHelper
import app.utils.RepoHelper
import app.utils.UiHelper
import com.beust.jcommander.JCommander
import com.beust.jcommander.MissingCommandException

fun main(argv : Array<String>) {
    Thread.setDefaultUncaughtExceptionHandler { _, e: Throwable? ->
        Logger.error("Uncaught exception", e)
    }
    Main(argv)
}

class Main(argv: Array<String>) {
    private val configurator = FileConfigurator()
    private val api = ServerApi(configurator)

    init {
        Analytics.uuid = configurator.getUuidPersistent()
        Analytics.trackStart()

        val options = Options()
        val commandAdd = CommandAdd()
        val commandConfig = CommandConfig()
        val commandList = CommandList()
        val commandRemove = CommandRemove()
        val jc: JCommander = JCommander.newBuilder()
            .programName("sourcerer")  // Used for usage method.
            .addObject(options)
            .addCommand(commandAdd.name, commandAdd)
            .addCommand(commandConfig.name, commandConfig)
            .addCommand(commandList.name, commandList)
            .addCommand(commandRemove.name, commandRemove)
            .build()

        try {
            jc.parse(*argv)
            options.password = PasswordHelper.hashPassword(options.password)
            configurator.setOptions(options)

            if (options.help) {
                showHelp(jc)
            } else if (options.setup) {
                doSetup()
            } else when (jc.parsedCommand) {
                commandAdd.name -> doAdd(commandAdd)
                commandConfig.name -> doConfig(commandConfig)
                commandList.name -> doList()
                commandRemove.name -> doRemove(commandRemove)
                else -> startUi()
            }
        } catch (e: MissingCommandException) {
            Logger.error(
                message = "No such command: ${e.unknownCommand}",
                code = "no-command"
            )
        }

        Analytics.trackExit()
    }

    private fun startUi() {
        ConsoleUi(api, configurator)
    }

    private fun doAdd(commandAdd: CommandAdd) {
        val path = commandAdd.path
        if (path != null && RepoHelper.isValidRepo(path)) {
            val localRepo = LocalRepo(path)
            localRepo.hashAllContributors = commandAdd.hashAll
            configurator.addLocalRepoPersistent(localRepo)
            configurator.saveToFile()
            println("Added git repository at $path.")

            Analytics.trackConfigChanged()
        } else {
            Logger.error(message = "No valid git repository found at $path.",
                         code = "repo-invalid")
        }
    }

    private fun doConfig(commandOptions: CommandConfig) {
        val (key, value) = commandOptions.pair

        if (!arrayListOf("username", "password").contains(key)) {
            Logger.error(message = "No such key $key",
                         code = "invalid-params")
            return
        }

        when (key) {
            "username" -> configurator.setUsernamePersistent(value)
            "password" -> configurator.setPasswordPersistent(value)
        }

        configurator.saveToFile()

        Analytics.trackConfigChanged()
    }

    private fun doList() {
        RepoHelper.printRepos(configurator.getLocalRepos(),
                              "Tracked repositories:",
                              "No tracked repositories")
    }

    private fun doRemove(commandRemove: CommandRemove) {
        val path = commandRemove.path
        // Don't validate because repository may be deleted already.
        if (path != null) {
            configurator.removeLocalRepoPersistent(LocalRepo(path))
            configurator.saveToFile()
            println("Repository removed from tracking list.")

            Analytics.trackConfigChanged()
        } else {
            println("Repository not found in tracking list.")
        }
    }

    private fun doSetup() {
        if (!configurator.isFirstLaunch()) {
            if (UiHelper.confirm("Are you sure that you want to setup "
                + "Sourcerer again?", defaultIsYes = false)) {
                configurator.resetAndSave()
            }
        }
        startUi()
    }

    private fun showHelp(jc: JCommander) {
        println("Sourcerer hashes your git repositories into intelligent "
            + "engineering profiles. If you don't have an account, "
            + "please, proceed to http://sourcerer.io/register. More info at "
            + "http://sourcerer.io.")
        jc.usage()  // Will show detailed info about usage based on annotations.
    }
}
