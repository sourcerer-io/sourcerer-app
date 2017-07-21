// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

/**
 * Console user interface.
 */
class ConsoleUi : Context {
    var state: ConsoleState = OpenState(this)

    init {
        changeState(state)
    }

    override fun changeState(state: ConsoleState) {
        this.state = state
        state.doAction()
        state.next()
    }
}
