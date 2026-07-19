#!/usr/bin/env bash
# Extracts a Go module path from a git remote URL.
#
# Usage:
#   git-module-name.sh [remote-url]
#
# With no argument, reads `git remote get-url origin`.
# Prints the module path (e.g. "github.com/org/repo") on stdout.
# Exits non-zero with a message on stderr if no URL is available.
#
# Handles: ssh (git@host:org/repo.git), ssh:// (with/without port),
# https/http/git protocols, nested groups, trailing ".git" and "/".

set -euo pipefail

url="${1:-}"

if [[ -z "$url" ]]; then
	url="$(git remote get-url origin 2>/dev/null || true)"
fi

if [[ -z "$url" ]]; then
	echo "error: no remote URL given and 'origin' remote not found" >&2
	echo "ask the user for the module path (e.g. github.com/org/repo)" >&2
	exit 1
fi

path="$url"
path="${path#*://}" # strip scheme: https://, ssh://, git://, ...
path="${path#*@}"   # strip user: git@, ...

if [[ "$path" =~ ^([^:]+):[0-9]+/(.+)$ ]]; then
	# host:port/path (ssh:// with port) -> host/path
	path="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
else
	# scp-like syntax host:path -> host/path
	path="${path/:/\/}"
fi

path="${path%/}"    # strip trailing slash
path="${path%.git}" # strip .git suffix
path="${path%/}"    # strip slash left behind by ".git/"

# Sanity check: host/path with no leftovers of user, port, or whitespace.
if [[ ! "$path" =~ ^[a-zA-Z0-9._-]+(/[a-zA-Z0-9._~-]+)+$ ]]; then
	echo "error: could not parse module path from remote URL: $url" >&2
	exit 1
fi

echo "$path"
