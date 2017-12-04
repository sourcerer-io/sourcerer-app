# Contribution

We welcome contributions to [Sourcerer App](https://github.com/sourcerer-io/sourcerer-app) by the community.

See [README](https://github.com/sourcerer-io/sourcerer-app) for more information about prerequirements and building project.

## How to report a problem

Please search before creating a new issue. Feel free to add issues related to the app or [sourcerer](https://sourcerer.io) site.

## Submitting сhanges

* Open a new issue in the [issue tracker](https://github.com/sourcerer-io/sourcerer-app/issues).
* Fork and clone the repo with `git clone https://github.com/your-username/sourcerer-app.git`.
* Create a new branch based off the `develop` branch.
* Make changes.
* Make sure all tests pass.
* Submit a pull request, referencing any issues it addresses.

We will review your Pull Request as soon as possible. Thank you for contributing!

## Integration testing

We will work on a special environment for contributors in the nearest future. For now one should use his personal or additional account on site.

## Style guides
### Commit messages

Format:
```type(component): message (jira issue tag, github issue number with #)```

Message types:
* **feat** is used when new feature is provided;
* **wip** is used when making regular commit and changes don't match any other types;
* **fix** is used when you fix a bug;
* **chore** is used when changes are about organization, not about logic;
* **docs** is used when you add/change documentation.
Component is a decomposition unit your commit affected. Write message in present simple.

Examples:
feat(logger): add rotating
chore: remove redundant commas, add copyright
wip: pass models to routers
fix: program exit is prevented when button is pressed (COMP-1, #123)

### Kotlin style guide
* Code has a column limit of 80 characters.
* Inline comments should be indented with 2 spaces from code.

We are using [Kotlin Coding Conventions](https://kotlinlang.org/docs/reference/coding-conventions.html).

## Code of conduct
We value input from each member of the community, however we urge you to abide by [code of conduct](https://github.com/sourcerer-io/sourcerer-app/blob/master/CODE_OF_CONDUCT.md).
