// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.api.Api

/**
 * Console user interface.
 */
class ConsoleUi(private val api: Api) : Context {
    var state: ConsoleState = OpenState(this, api)

    init {
        changeState(state)
    }

    override fun changeState(state: ConsoleState) {
        this.state = state
        state.doAction()
        state.next()
    }
}
