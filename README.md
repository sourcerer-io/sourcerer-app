
<h1 style="font-weight:normal">
  <a href="https://sourcerer.io"><img src=https://user-images.githubusercontent.com/20287615/34189346-d426d4c2-e4ef-11e7-9da4-cc76a1ed111d.png alt="Sourcerer Logo", width=50></a>
    sourcerer.io
</h1>
  An intelligent profile for software engineers
<br>

What is it?
===========

![profile-sliced-sized](https://user-images.githubusercontent.com/20287615/34188912-b3aaf8ba-e4ed-11e7-861c-2adf13a921ac.png)
<br>

Once you feed it some git repos, you will get a beautiful profile that will help
you learn things about yourself, connect to others, and become a better
engineer. Example profiles: <https://sourcerer.io/sergey>,
<https://sourcerer.io/frankie>, <https://sourcerer.io/ice1snice>.

Profile is the first step. Some of the things on our roadmap:
news that is relevant to your code, engineers to follow and learn from,
technology and libraries you should know about, projects
that could use your help.

Both open source and closed source repos are fine. Sourcerer app does not upload
source code anywhere, and it never will. The app looks at repos locally on your
machine, and then sends stats to sourcerer.io. The best way to verify is to
look at the code. [src/main/proto/sourcerer.proto](https://github.com/sourcerer-io/sourcerer-app/blob/develop/src/main/proto/sourcerer.proto)
is a good start as it describes the client-server protocol.

You will need an account, sign up on <https://sourcerer.io/>

Prerequirements
=================

* Sourcerer alpha/beta access
* Linux or macOS
* Java 8+ Platform ([JRE](http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html) for Linux or [JDK](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html) for macOS)
* Git repositories with master branch with at least one commit

Install/uninstall
=================

To install sourcerer run the following command:

```
curl -s https://sourcerer.io/app/install | bash
```

To remove sourcerer from your machine:

```
sourcerer --uninstall
```

Build
=====

To build and run this application, you'll need latest versions of Git, Gradle and JDK installed on your computer. From your command line:

```
# Clone this repository
$ git clone https://github.com/sourcerer-io/sourcerer-app.git

# Go into the repository
$ cd sourcerer-app

# Build
$ gradle build

# Run the app
$ java -jar build/libs/sourcerer-app.jar
```

Contribution
============

We welcome contributions to Sourcerer App by the community. Check the [Contribution guide](https://github.com/sourcerer-io/sourcerer-app/blob/master/CONTRIBUTING.md) for more information.
