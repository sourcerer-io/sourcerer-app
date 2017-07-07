// Copyright 2017 Sourcerer Inc. All Rights Reserved.

package app

import app.utils.Args
import com.beust.jcommander.JCommander
import com.beust.jcommander.ParameterException

fun main(argv : Array<String>) {
    val args = Args()
    try {
        JCommander.newBuilder()
                .addObject(args)
                .build()
                .parse(*argv)
    } catch (e: ParameterException) {
        println(e.message)
        return
    }

    println(arrayOf(args.username, args.password, args.path).joinToString())

    val greeter = Greeter(args)
    greeter.run()
}
