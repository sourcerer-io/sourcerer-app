// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app

import app.utils.CommandConfig
import app.utils.CommandExplore
import app.utils.Options
import com.beust.jcommander.JCommander
import com.beust.jcommander.ParameterException
import kotlin.system.exitProcess

fun main(argv: Array<String>) {
    val commandExplore = "explore"
    val commandConfig = "config"

    val options = Options()
    val explore = CommandExplore()
    val config = CommandConfig()
    val jc: JCommander = JCommander.newBuilder()
            .programName("sourcerer")  // Used for usage method.
            .addObject(options)
            .addCommand(commandExplore, explore)
            .addCommand(commandConfig, config)
            .build()

    Configurator.setCurrentOptions(options)

    try {
        jc.parse(*argv)
    } catch (e: ParameterException) {
        println(e.message)
        exitProcess(1)  // Reporting failure with non-zero exit code.
    }

    when (jc.parsedCommand) {
        commandExplore -> explore(explore)
        commandConfig -> config(config)
        else -> help(jc)  // Show help info if no command specified.
    }

    println(arrayOf(options.username, options.password).joinToString())
    println(jc.parsedCommand)
    println(explore.path)
}

fun explore(commandOptions: CommandExplore) {
    RepoExplorer(commandOptions).explore()
}

fun config(commandOptions: CommandConfig) {
    val options = Configurator.createOptions(commandOptions.pair)
    val userDir = Configurator.userDir
    if (userDir != null) {
        Configurator.saveConfig(userDir, options)
    }
}

fun help(jc: JCommander) {
    println("Sourcerer app. More info at http://sourcerer.io.")
    jc.usage()  // Will show detailed info about usage based on annotations.
}
