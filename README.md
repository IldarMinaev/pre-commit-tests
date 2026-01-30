# Example of or pre-commit hooks

## Prerequisites

* Installed git (for windows: with git-shell)
* Installed python3
* Installed pre-commit

## Install hooks from remote

To install the latest hooks from the remote repository and configure your global hooks directory, run:

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/IldarMinaev/pre-commit-tests/refs/heads/main/install-hooks.sh)"

```

This will set `core.hooksPath` to `~/.git-hooks` and download the latest hook scripts into that directory.