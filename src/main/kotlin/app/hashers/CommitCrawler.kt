// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.hashers

import app.Logger
import app.model.Author
import app.model.Commit
import app.model.DiffContent
import app.model.DiffFile
import app.model.DiffRange
import app.model.Repo
import app.utils.EmptyRepoException
import io.reactivex.Observable
import java.io.BufferedReader
import java.io.InputStreamReader
import org.apache.commons.codec.digest.DigestUtils
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.diff.DiffFormatter
import org.eclipse.jgit.diff.EditList
import org.eclipse.jgit.diff.RawText
import org.eclipse.jgit.lib.ObjectId
import org.eclipse.jgit.lib.Repository
import org.eclipse.jgit.revwalk.RevCommit
import org.eclipse.jgit.revwalk.RevWalk
import org.eclipse.jgit.treewalk.filter.PathFilter
import org.eclipse.jgit.treewalk.TreeWalk
import org.eclipse.jgit.util.io.DisabledOutputStream
import java.util.LinkedList

data class JgitData(var commit: RevCommit? = null,
                    var list: List<JgitDiff>? = null,
                    var paths: List<String>? = null,
                    var date: Long? = null,
                    var email: String? = null,
                    var coauthors: List<Author>? = null)

data class JgitDiff(val diffEntry: DiffEntry, val editList: EditList)

/**
* Iterates over the diffs between commits in the repo's history.
*/
object CommitCrawler {
    private const val REMOTE_HEAD = "refs/remotes/origin/HEAD"
    private const val REMOTE_MASTER_BRANCH = "refs/remotes/origin/master"
    private const val LOCAL_MASTER_BRANCH = "refs/heads/master"
    private const val LOCAL_HEAD = "HEAD"
    private val REFS = listOf(REMOTE_HEAD, REMOTE_MASTER_BRANCH,
                              LOCAL_MASTER_BRANCH, LOCAL_HEAD)
    private val CONF_FILE_PATH = ".sourcerer-conf"
    private val MAX_DIFF_SIZE = 600000
    private val coauthoredRegex = Regex("""Co-authored-by: (.+) <(.+)>""")

    fun getDefaultBranchHead(git: Git): ObjectId {
        for (ref in REFS) {
            val branch = git.repository.resolve(ref) ?: continue

            Logger.debug { "Hashing from $ref" }
            return branch
        }
        throw EmptyRepoException("No remote default, master or HEAD found")
    }

    fun fetchRehashesAndAuthors(git: Git):
        Triple<LinkedList<String>, HashSet<Author>, HashMap<String, Int>> {
        val head: RevCommit = RevWalk(git.repository)
            .parseCommit(getDefaultBranchHead(git))

        val revWalk = RevWalk(git.repository)
        revWalk.markStart(head)

        val commitsRehashes = LinkedList<String>()
        val emails = hashSetOf<String>()
        val names = hashMapOf<String, String>()
        val commitsCount = hashMapOf<String, Int>()
        val coauthorsList = mutableListOf<Author>()

        var commit: RevCommit? = revWalk.next()
        while (commit != null) {
            commitsRehashes.add(DigestUtils.sha256Hex(commit.name))
            val email = commit.authorIdent.emailAddress.toLowerCase()
            val name = commit.authorIdent.name
            if (!emails.contains(email)) {
                emails.add(email)
                names[email] = name
            } else {
                if (name.length > names[email]!!.length) {
                    names[email] = name
                }
            }
            val coauthors = getCoauthors(commit.fullMessage)
            coauthorsList.addAll(coauthors)

            commitsCount[email] = commitsCount.getOrDefault(email, 0) + 1

            commit.disposeBody()
            commit = revWalk.next()
        }
        revWalk.dispose()

        val authors = emails.map { email -> Author(names[email]!!, email) }
            .toHashSet()
        authors.addAll(coauthorsList)

        return Triple(commitsRehashes, authors, commitsCount)
    }

    fun getJGitObservable(git: Git,
                          totalCommitCount: Int = 0,
                          extractCommit: Boolean = true,
                          extractDiffs: Boolean = true,
                          extractPaths: Boolean = false,
                          extractDate: Boolean = false,
                          extractEmail: Boolean = false,
                          extractCoauthors: Boolean = false,
                          filteredEmails: HashSet<String>? = null,
                          tail : RevCommit? = null) :
        Observable<JgitData> = Observable.create { subscriber ->
        val repo: Repository = git.repository
        val revWalk = RevWalk(repo)
        val head: RevCommit =
            try { revWalk.parseCommit(getDefaultBranchHead(git)) }
            catch(e: Exception) { throw Exception("No head was found!") }

        val df = DiffFormatter(DisabledOutputStream.INSTANCE)
        df.setRepository(repo)
        df.isDetectRenames = true

        val confTreeWalk = TreeWalk(repo)
        confTreeWalk.addTree(head.getTree())
        confTreeWalk.setFilter(PathFilter.create(CONF_FILE_PATH))

        var ignoredPaths =
            if (confTreeWalk.next()) {
                getIgnoredPaths(repo, confTreeWalk.getObjectId(0))
            }
            else {
                listOf()
            }

        var commitCount = 0
        revWalk.markStart(head)
        var commit: RevCommit? = revWalk.next()  // Move the walker to the head.
        while (commit != null && commit != tail) {
            commitCount++
            val parentCommit: RevCommit? = revWalk.next()

            // Smart casts are not yet supported for a mutable variable captured
            // in an inline lambda, see
            // https://youtrack.jetbrains.com/issue/KT-7186.
            if (Logger.isTrace) {
                val commitName = commit.name
                val commitMsg = commit.shortMessage
                Logger.trace { "commit: $commitName; '$commitMsg'" }
                if (parentCommit != null) {
                    val parentCommitName = parentCommit.name
                    val parentCommitMsg = parentCommit.shortMessage
                    Logger.trace { "parent commit: $parentCommitName; " +
                        "'$parentCommitMsg'" }
                }
                else {
                    Logger.trace { "parent commit: null" }
                }
            }

            val perc = if (totalCommitCount != 0) {
                (commitCount.toDouble() / totalCommitCount) * 100
            } else 0.0
            Logger.printCommit(commit.shortMessage, commit.name, perc)

            val email = commit.authorIdent.emailAddress.toLowerCase()
            if (filteredEmails != null && !filteredEmails.contains(email)) {
                commit = parentCommit
                continue
            }
            val paths = mutableListOf<String>()

            val diffEntries = df.scan(parentCommit, commit)
            .filter { diff ->
                diff.changeType != DiffEntry.ChangeType.COPY
            }
            .filter { diff ->
                val path = diff.newPath
                for (cnv in VendorConventions) {
                    if (cnv.containsMatchIn(path) ||
                        cnv.containsMatchIn(diff.oldPath)) {
                        return@filter false
                    }
                }

                val fileId =
                    if (path != DiffEntry.DEV_NULL) {
                        diff.newId.toObjectId()
                    } else {
                        diff.oldId.toObjectId()
                    }
                val stream = try {
                    repo.open(fileId).openStream()
                } catch (e: Exception) {
                    null
                }
                stream != null && !RawText.isBinary(stream)
            }
            .filter { diff ->
                val filePath =
                    if (diff.getNewPath() != DiffEntry.DEV_NULL) {
                        diff.getNewPath()
                    } else {
                        diff.getOldPath()
                    }

                // Update ignored paths list. The config file has retroactive
                // force, i.e. if it was added at this commit, then we presume
                // it is applied to all commits, preceding this commit.
                if (diff.getOldPath() == CONF_FILE_PATH) {
                    ignoredPaths =
                        getIgnoredPaths(repo, diff.getNewId().toObjectId())
                }

                if (!ignoredPaths.any { path ->
                    if (path.endsWith("/")) {
                        filePath.startsWith(path)
                    }
                    else {
                        path == filePath
                    }
                }) {
                    paths.add(filePath)
                    true
                } else false
            }

            val jgitData = JgitData()
            if (extractCommit) {
                jgitData.commit = commit
            }
            if (extractDiffs) {
                val diffEdits = diffEntries
                .map { diff ->
                    JgitDiff(diff, df.toFileHeader(diff).toEditList())
                }
                .filter { diff ->
                    diff.editList.fold(0) { acc, edit ->
                        acc + edit.lengthA + edit.lengthB
                    } < MAX_DIFF_SIZE
                }
                jgitData.list = diffEdits
            }
            if (extractPaths) {
                jgitData.paths = paths
            }
            if (extractDate) {
                jgitData.date = commit.authorIdent.getWhen().time / 1000
            }
            if (extractEmail) {
                jgitData.email = email
            }
            if (extractCoauthors) {
                jgitData.coauthors = getCoauthors(commit.fullMessage)
            }

            subscriber.onNext(jgitData)
            commit = parentCommit
        }

        subscriber.onComplete()
    }

    fun getObservable(git: Git,
                      repo: Repo): Observable<Commit> {
        return getObservable(git, getJGitObservable(git), repo)
    }

    fun getObservable(git: Git,
                      jgitObservable: Observable<JgitData>,
                      repo: Repo): Observable<Commit> {
        return jgitObservable.map( { jgitData ->
            // Mapping and stats extraction.
            val commit = Commit(jgitData.commit!!, jgitData.coauthors)
            commit.diffs = getDiffFiles(git.repository, jgitData.list!!)

            // Count lines on all non-binary files. This is additional
            // statistics to CommitStats because not all file extensions
            // may be supported.
            commit.numLinesAdded = commit.diffs.fold(0) { total, file ->
                total + file.getAllAdded().size
            }
            commit.numLinesDeleted = commit.diffs.fold(0) { total, file ->
                total + file.getAllDeleted().size
            }
            commit.repo = repo

            commit
        })
    }

    private fun getDiffFiles(jgitRepo: Repository,
                             jgitDiffs: List<JgitDiff>) : List<DiffFile> {
        return jgitDiffs
            .map { (diff, edits) ->
                // TODO(anatoly): Can produce exception for large object.
                // Investigate for size.
                val new = try {
                    getContentByObjectId(jgitRepo, diff.newId.toObjectId())
                } catch (e: Exception) {
                    Logger.error(e)
                    null
                }
                val old = try {
                    getContentByObjectId(jgitRepo, diff.oldId.toObjectId())
                } catch (e: Exception) {
                    Logger.error(e)
                    null
                }

                val diffFiles = mutableListOf<DiffFile>()
                if (new != null && old != null) {
                    val path = when (diff.changeType) {
                        DiffEntry.ChangeType.DELETE -> diff.oldPath
                        else -> diff.newPath
                    }
                    diffFiles.add(DiffFile(path = path,
                        changeType = diff.changeType,
                        old = DiffContent(old, edits.map { edit ->
                            DiffRange(edit.beginA, edit.endA)
                        }),
                        new = DiffContent(new, edits.map { edit ->
                            DiffRange(edit.beginB, edit.endB)
                        })
                    ))
                }
                diffFiles
            }
            .flatten()
    }

    private fun getContentByObjectId(repo: Repository,
                                     objectId: ObjectId): List<String> {
        return try {
            val obj = repo.open(objectId)
            val rawText = RawText(obj.bytes)
            val content = ArrayList<String>(rawText.size())
            for (i in 0..(rawText.size() - 1)) {
                content.add(rawText.getString(i))
            }
            return content
        } catch (e: Exception) {
            listOf()
        }
    }

    /**
     * Return a list of paths that should be ignored in commit analysis.
     */
    private fun getIgnoredPaths(repo: Repository, objectId: ObjectId?): List<String> {
        return try {
            if (objectId == null) {
                return listOf()
            }

            val list = mutableListOf<String>()
            val fileLoader = repo.open(objectId)
            val reader =
                BufferedReader(InputStreamReader(fileLoader.openStream()))
            var collectIgnored = false
            for (line in reader.lines()) {
                if (line == "" || line.startsWith("#")) {
                    continue
                }

                if (line.startsWith("[")) {
                    collectIgnored = (line == "[ignore]")
                    continue
                }

                if (collectIgnored) {
                    list.add(line)
                }
            }
            list
        }
        catch(e: Exception) {
            listOf()
        }
    }

    private fun getCoauthors(message: String): List<Author> {
        val coauthorsResult = coauthoredRegex.findAll(message)
        val coauthors = mutableListOf<Author>()
        if (coauthorsResult.toList().isNotEmpty()) {
            coauthorsResult.toList().map { result ->
                val coauthorName = result.groupValues[1]
                val coauthorEmail = result.groupValues[2].toLowerCase()
                coauthors.add(Author(coauthorName, coauthorEmail))
            }
        }
        return coauthors
    }
}
