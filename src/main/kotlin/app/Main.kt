// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app

import app.ui.ConsoleUi
import app.utils.CommandConfig
import app.utils.CommandAdd
import app.utils.CommandList
import app.utils.CommandRemove
import app.utils.Options
import app.utils.PasswordHelper
import app.utils.RepoHelper
import com.beust.jcommander.JCommander

fun main(argv: Array<String>) {
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

    jc.parse(*argv)

    options.password = PasswordHelper.hashPassword(options.password)
    Configurator.options = options

    if (options.help) {
        showHelp(jc)
        return
    }

    if (options.setup) {
        doSetup()
        return
    }

    when (jc.parsedCommand) {
        commandAdd.name -> doAdd(commandAdd)
        commandConfig.name -> doConfig(commandConfig)
        commandList.name -> doList(commandList)
        commandRemove.name -> doRemove(commandRemove)
        else -> startUi()
    }
}

fun startUi() {
    val consoleUi = ConsoleUi()
}

fun doAdd(commandAdd: CommandAdd) {
    val path = commandAdd.path
    if (path != null && RepoHelper.isValidRepo(path)) {
        Configurator.addRepoPersistent(Repo(path))
        Configurator.saveToFile()
        println("Added git repository at $path.")
    } else {
        Logger.error("No valid git repository found at $path.")
    }
}

fun doConfig(commandOptions: CommandConfig) {
    val (key, value) = commandOptions.pair

    if (!arrayListOf("username", "password").contains(key)) {
        Logger.error("No such key $key")
        return
    }

    when (key) {
        "username" -> Configurator.setUsernamePersistent(value)
        "password" -> Configurator.setPasswordPersistent(value)
    }

    Configurator.saveToFile()
}

fun doList(commandList: CommandList) {
    RepoHelper.printRepos(Configurator.getRepos(), "Tracked repositories:",
            "No tracked repositories")
}

fun doRemove(commandRemove: CommandRemove) {
    val path = commandRemove.path
    if (path != null) {  // Don't validate because path can be deleted already.
        Configurator.removeRepoPersistent(Repo(path))
        Configurator.saveToFile()
        println("Repository removed from tracking list.")
    } else {
        println("Repository not found in tracking list.")
    }
}

fun doSetup() {
    if (!Configurator.isFirstLaunch()) {
        println("Are you sure that you want to setup Sourcerer again? [y/n]")
        if ((readLine() ?: "").toLowerCase() == "y") {
            Configurator.resetAndSave()
        }
    }
    startUi()
}

fun showHelp(jc: JCommander) {
    println("Sourcerer hashes your git repositories into intelligent "
            + "engineering profiles. If you don't have an account, "
            + "please, proceed to http://sourcerer.io/register. More info at "
            + "http://sourcerer.io.")
    jc.usage()  // Will show detailed info about usage based on annotations.
}
