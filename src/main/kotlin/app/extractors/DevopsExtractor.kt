// Copyright 2019 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.extractors

import app.model.CommitStats
import app.model.DiffFile

class DevopsExtractor(private val techName: String) : ExtractorInterface {
    companion object {
        const val DEVOPS = "devops."
        const val JENKINS = "jenkins"
        const val CIRCLECI = "circleci"
        const val GITLAB_CI = "gitlab-ci"
        const val GITHUB_ACTIONS = "github-actions"
        const val TRAVIS = "travis"
        const val K8S = "k8s"
        const val DOCKER = "docker"
        const val DRONE = "drone"
    }

    override fun extract(files: List<DiffFile>): List<CommitStats> {
        return listOf(CommitStats(
            numLinesAdded = files.map { it.getAllAdded().size }.sum(),
            numLinesDeleted = files.map { it.getAllDeleted().size }.sum(),
            type = ExtractorInterface.TYPE_LIBRARY,
            tech = DEVOPS + techName
        )).filter { it.numLinesAdded > 0 || it.numLinesDeleted > 0 }
    }
}
