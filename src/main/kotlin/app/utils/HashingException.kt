// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

class HashingException(val errors: List<Throwable>) : Exception()

class EmptyRepoException(message: String) : Exception(message)
