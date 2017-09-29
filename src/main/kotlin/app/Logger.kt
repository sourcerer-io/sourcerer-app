// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app

/**
 * Singleton class that logs events of different levels.
 */
object Logger {
    /**
     * Current log level. All that higher than this level will not be displayed.
     */
    const val LEVEL = 3

    /**
     * Error level.
     */
    const val ERROR = 0

    /**
     * Warning level.
     */
    const val WARN = 1

    /**
     * Information level.
     */
    const val INFO = 2

    /**
     * Debug level.
     */
    const val DEBUG = 3

    /**
     * Log error message with exception info.
     */
    fun error(message: String) {
        if (LEVEL >= ERROR) {
            println("[e] $message.")
        }
    }

    /**
     * Log error message with exception info.
     */
    fun error(message: String, e: Throwable) {
        if (LEVEL >= ERROR) {
            println("[e] $message: $e")
        }
    }

    /**
     * Log warning message.
     */
    fun warn(message: String) {
        if (LEVEL >= WARN) {
            println("[w] $message.")
        }
    }

    /**
     * Log information message.
     */
    fun info(message: String) {
        if (LEVEL >= INFO) {
            println("[i] $message.")
        }
    }

    /**
     * Log debug message.
     */
    fun debug(message: String) {
        if (LEVEL >= DEBUG) {
            println("[d] $message.")
        }
    }
}
