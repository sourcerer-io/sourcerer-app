// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.model

data class LocalRepo(var path: String = "",
                     var hashAllAuthors: Boolean = false) {
    var author: Author = Author()
    var remoteOrigin: String = ""
    var userName: String = ""
}
