# [Swift] Pull Request Changelog Generator

> Version: 0.1.1

## Usage
1. Build the docker image
2. Make sure you change the BRANCH and BRANCH_MASTER variables in the container.
3. Make sure the /app/repo path in the container mapped to your git repo.
3. Run it.

## What it does
It gets every commit between BRANCH_MASTER and BRANCH and generates a list of changes depending on the commit messages.

1. It ignores commit messages starting with --
2. It ignores single line commit messages, if the message does not resolve an issue (resolves, fixes etc #88)
3. It ignores the first line in a multiline commit message.

## Add command
Add this to .bashrc
```
function generateChangelog() {
        (docker run --rm -it -v "${PWD}":/app/repo -e BRANCH="origin/development" -e BRANCH_MASTER="origin/master" oisann/swift-pr-changelog-generator:latest)
}
```

## TODO
- [x] Generate a simple CHANGELOG
- [ ] Add commandline arguments for running outside a container.
- [ ] Prepending to an existing CHANGELOG, with the title of the Pull Request as a header
- [ ] Automatically generate CHANGELOG on merge
