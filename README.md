<h1 style="font-weight:normal">
  <a href="https://sourcerer.io">
    <img src=https://user-images.githubusercontent.com/20287615/34189346-d426d4c2-e4ef-11e7-9da4-cc76a1ed111d.png alt="Sourcerer" width=35>
  </a>
  &nbsp;sourcerer.io&nbsp;
  <a href="https://sourcerer.io/start"><img src=https://img.shields.io/badge/sourcerer-start%20now-brightgreen.svg?colorA=087c08></a>
  <a href="https://github.com/sourcerer-io/sourcerer-app/releases"><img src=https://img.shields.io/github/release/sourcerer-io/sourcerer-app.svg?colorB=58839b></a>
  <a href="https://github.com/sourcerer-io/sourcerer-app/blob/master/LICENSE.md"><img src=https://img.shields.io/github/license/sourcerer-io/sourcerer-app.svg?colorB=ff0000></a>
</h1>

A visual profile for software engineers.
<br>

<p align="center">
  <img alt="sergey" src="https://user-images.githubusercontent.com/20287615/42118899-cc2c0b94-7bbb-11e8-86a8-96dcd044b5e2.gif">
</p>

Features
========
* Profile creation with a single click
* Support of 100 languages (even exotic ones like COBOL)
* Detection of more than [1,000 libraries](https://github.com/sourcerer-io/awesome-libraries) in code with per-line statistics
* Visual presentation your development experience
* *Finally!* Summary of all repositories you've contributed to :tada:
* Interesting facts about yourself

Creating your profile is just the first step for us at Sourcerer. Some of the things on our roadmap include:
* Engineers to follow and learn from
* Technology and libraries you should know about
* Projects that could use your help

Get started
===========
The easiest way to get started is with your open source repos. Go to [sourcerer.io/start](https://sourcerer.io/start), and select *Build with GitHub* and watch your profile build. 

For closed source repos, you will need to use this app. If you already created an account using GitHub, you would have received an email with credentials for the app. If not, You will need a new account, which you can get at [sourcerer.io/join](https://sourcerer.io/join>).

Showcase
========
<center>
  <table>
    <tr>
      <td><a href="https://sourcerer.io/chdemko"><img width="120" alt="chdemko" src="https://user-images.githubusercontent.com/20287615/42243607-c7f6c40c-7ec6-11e8-9f8e-d4450d1d92d1.png"></a></td>
      <td><a href="https://sourcerer.io/chendaniely"><img width="120" alt="chendaniely" src="https://user-images.githubusercontent.com/20287615/42243623-d1bd479a-7ec6-11e8-983c-00945c926dc6.png"></a></td>
      <td><a href="https://sourcerer.io/lauragift21"><img width="120" alt="lauragift21" src="https://user-images.githubusercontent.com/20287615/42243624-d1d24cd0-7ec6-11e8-84c0-3a1aad54a774.png"></a></td>
      <td><a href="https://sourcerer.io/maracuja-juice"><img width="120" alt="maracuja-juice" src="https://user-images.githubusercontent.com/20287615/42243626-d1eb19c2-7ec6-11e8-8e94-fa02d8f11894.png"></a></td>
    </tr>
    <tr>
      <td><a href="https://sourcerer.io/marisbotero"><img width="120" alt="marisbotero" src="https://user-images.githubusercontent.com/20287615/42243627-d203bb58-7ec6-11e8-945e-49b878f07436.png"></a></td>
      <td><a href="https://sourcerer.io/nordes"><img width="120" alt="nordes" src="https://user-images.githubusercontent.com/20287615/42243628-d21df464-7ec6-11e8-9147-31b99ea3465d.png"></a></td>
      <td><a href="https://sourcerer.io/ppapadeas"><img width="120" alt="ppapadeas" src="https://user-images.githubusercontent.com/20287615/42243629-d23b27e6-7ec6-11e8-92c1-0c3edc2f3dba.png"></a></td>
      <td><a href="https://sourcerer.io/praharshjain"><img width="120" alt="praharshjain" src="https://user-images.githubusercontent.com/20287615/42243630-d2562abe-7ec6-11e8-8ad3-fd6ca3ddd413.png"></a></td>
    </tr>
  </table>
</center>

Requirements
============
* Web browser

or

* Linux or macOS or Windows
* Java 8+ Platform ([JRE](http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html) for Linux and Windows or [JDK](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html) for macOS)

Usage
=====
To install sourcerer run the following command:

```
curl -s https://sourcerer.io/app/install | bash
```

To run wizard use `sourcerer` command

Internals
=========
The app looks at repos locally on your machine, and then sends stats to sourcerer.io. The best way to verify is to look at the code. Protobuf messages declared in [src/main/proto/sourcerer.proto](https://github.com/sourcerer-io/sourcerer-app/blob/develop/src/main/proto/sourcerer.proto) is a good start as it describes the client-server protocol.
The Sourcerer app does **NOT** upload source code anywhere, and it **NEVER** will.

FAQ
===
### How can I process private repos?
We process only public repos using GitHub OAuth. To process private repos you need to run sourcerer app locally. See [Get started](#get-started) for instructions. Sourcerer app sends only statistical information to our servers and never sends code.

### Why do you need GitHub permissions?
We use emails to identify commit authorship, read orgs access to get list of public repositories that you've contributed to. You also need to grant access to read this public information from an organization.

### Other questions
See [sourcerer.io/faq](https://sourcerer.io/faq).

Contributing
============
We love contributions! Check out the [Contribution guide](https://github.com/sourcerer-io/sourcerer-app/blob/master/CONTRIBUTING.md) for more information. Simplest and really helpful for the community would be contribution meta information to our [supported libraries list](https://github.com/sourcerer-io/awesome-libraries). If you an author of a library you show definitely add yours to the list or you can help to someone whose work you use.

[![0](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/images/0)](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/links/0)
[![1](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/images/1)](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/links/1)
[![2](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/images/2)](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/links/2)
[![3](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/images/3)](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/links/3)
[![4](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/images/4)](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/links/4)
[![5](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/images/5)](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/links/5)
[![6](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/images/6)](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/links/6)
[![7](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/images/7)](https://sourcerer.io/fame/sergey48k/sourcerer-io/sourcerer-app/links/7)

Build
=====
To build and run this application locally, you'll need latest versions of Git, Gradle and JDK installed on your computer. From your command line:

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

License
=======
Sourcerer is under the MIT license. See the [LICENSE](https://github.com/sourcerer-io/sourcerer-app/blob/develop/LICENSE.md) for more information.

Links
=====
* [Sourcerer Site](https://sourcerer.io/)
* [Sourcerer Blog](https://blog.sourcerer.io)
* [Follow Sourcerer on Twitter](https://twitter.com/sourcerer_io)
* [Follow Sourcerer on Facebook](https://www.facebook.com/sourcerer.io/)
