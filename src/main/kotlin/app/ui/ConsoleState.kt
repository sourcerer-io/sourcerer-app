// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.ui

/**
 * State pattern interface for console user interface.
 */
interface ConsoleState {
    fun doAction()
    fun next()
}
