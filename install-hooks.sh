#!/usr/bin/env bash
# Version: 0.0.1

set -euo pipefail

# Installer for pre-commit-tests hooks
# - If global core.hooksPath is configured and already contains this repo's hooks, abort.
# - Otherwise set global core.hooksPath to ~/.git-hooks and download latest hooks from remote.

REPO_RAW_BASE="https://raw.githubusercontent.com/IldarMinaev/pre-commit-tests/refs/heads/main/hooks"
TARGET_DIR="$HOME/.git-hooks"

echo "Installing pre-commit-tests hooks to $TARGET_DIR"

CURRENT=$(git config --global --get core.hooksPath || true)

# Try to fetch list of hooks from remote repository (GitHub API). Fall back to local hooks/* if unavailable.
REMOTE_API="https://api.github.com/repos/IldarMinaev/pre-commit-tests/contents/hooks?ref=main"
REMOTE_HOOKS=()
if command -v curl >/dev/null 2>&1; then
    JSON=$(curl -fsSL --max-time 10 "$REMOTE_API" 2>/dev/null || true)
elif command -v wget >/dev/null 2>&1; then
    JSON=$(wget -qO- --timeout=10 "$REMOTE_API" 2>/dev/null || true)
else
    JSON=""
fi

if [ -n "$JSON" ]; then
    # Extract "name" fields from JSON. If parsing fails, REMOTE_HOOKS stays empty.
    mapfile -t REMOTE_HOOKS < <(printf "%s" "$JSON" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]\+"' | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"\\]+)"/\1/')

    if [ ${#REMOTE_HOOKS[@]} -eq 0 ]; then
        echo "Fatal: could not parse hook names from GitHub API response." 1>&2
        exit 1
    fi
fi

if [ -n "$CURRENT" ]; then
    # If any remote hook name exists in the configured hooks path, ensure it belongs to this package.
    for name in "${REMOTE_HOOKS[@]}"; do
        if [ -e "$CURRENT/$name" ]; then
            # Check for markers that indicate the installed hook belongs to this repo/package
            if grep -Eqi 'IldarMinaev/pre-commit-tests|pre-commit-tests|raw.githubusercontent.com/IldarMinaev/pre-commit-tests' "$CURRENT/$name" >/dev/null 2>&1; then
                echo "Found existing hook '$CURRENT/$name' belonging to this package; it will be updated."
            else
                echo "Error: git global core.hooksPath is set to '$CURRENT' and already contains '$name'." 1>&2
                echo "The existing '$CURRENT/$name' does not appear to belong to this package. Please remove it (or change your global core.hooksPath) before running this installer." 1>&2
                exit 1
            fi
        fi
    done
fi

echo "Setting global git core.hooksPath to $TARGET_DIR"
git config --global core.hooksPath "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

# Download each hook from remote and install
if [ ${#REMOTE_HOOKS[@]} -eq 0 ]; then
    echo "No hooks found to install." && exit 0
fi
for name in "${REMOTE_HOOKS[@]}"; do
    url="$REPO_RAW_BASE/$name"
    echo "Installing $name from $url"
    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL --max-time 30 "$url" -o "$TARGET_DIR/$name"; then
            echo "Warning: failed to download $url" 1>&2
            continue
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -qO "$TARGET_DIR/$name" "$url"; then
            echo "Warning: failed to download $url" 1>&2
            continue
        fi
    else
        echo "Error: neither curl nor wget is available to download hooks." 1>&2
        exit 1
    fi
    chmod +x "$TARGET_DIR/$name" || true
done

echo "Hooks installation complete. Git global core.hooksPath is set to $TARGET_DIR"
