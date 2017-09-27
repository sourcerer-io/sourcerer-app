// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

import app.api.Api
import app.config.Configurator

/**
 * Console user interface.
 */
class ConsoleUi(api: Api,
                configurator: Configurator) : Context {
    var state: ConsoleState = OpenState(this, api, configurator)

    init {
        changeState(state)
    }

    override fun changeState(state: ConsoleState) {
        this.state = state
        state.doAction()
        state.next()
    }
}
