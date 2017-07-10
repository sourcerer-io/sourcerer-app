// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

import com.beust.jcommander.Parameter
import com.beust.jcommander.Parameters

@Parameters(separators = "=",
        commandDescription = "Explore statistics on specific repository")
class CommandExplore {
    // Path to analyzed repository.
    @Parameter(description = "REPOPATH",
            validateWith = arrayOf(PathValidator::class))
    var path: String? = null
}
