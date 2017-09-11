// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

/**
 * [start] (inclusive) and [end] (exclusive) specifies range of changed lines.
 */
data class DiffRange(val start: Int, val end: Int)
