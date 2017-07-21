// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

/**
 * Update repositories console UI state.
 */
class UpdateRepoState constructor(val context: Context) : ConsoleState {
    override fun doAction() {
        // TODO(anatoly): Implement.
        println("Hashing your git repositories.")
        println("The repositories has been hashed. See result online on your "
                + "Sourcerer profile.")
    }

    override fun next() {
        context.changeState(CloseState(context))
    }
}
