// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

/**
 * State pattern context.
 */
interface Context {
    fun changeState(state: ConsoleState)
}
