#!/usr/bin/env bash
set -Eeuo pipefail

# Fedora 45 stores distribution repository definitions under /usr/share.
# bootc-image-builder's depsolver needs real repository files in the
# conventional /etc/yum.repos.d directory. Copy them instead of symlinking:
# the depsolver operates against an installroot and must not depend on
# symlink traversal between repository directories.
SOURCE_DIR="/usr/share/dnf5/repos.d"
TARGET_DIR="/etc/yum.repos.d"

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "ERROR: Fedora DNF5 repository directory is missing: $SOURCE_DIR" >&2
    exit 1
fi

shopt -s nullglob
repo_files=("$SOURCE_DIR"/*.repo)
if (( ${#repo_files[@]} == 0 )); then
    echo "ERROR: No repository definitions found in $SOURCE_DIR" >&2
    exit 1
fi

install -d -m 0755 "$TARGET_DIR"

for repo_file in "${repo_files[@]}"; do
    repo_name="$(basename "$repo_file")"
    install -m 0644 "$repo_file" "$TARGET_DIR/$repo_name"
done

for required_repo in fedora.repo fedora-updates.repo; do
    if [[ ! -s "$TARGET_DIR/$required_repo" ]]; then
        echo "ERROR: Required repository file is missing: $TARGET_DIR/$required_repo" >&2
        exit 1
    fi
done

# Confirm DNF5 can actually parse and see enabled repositories, rather than
# merely checking that .repo files exist on disk.
if ! command -v dnf5 >/dev/null 2>&1; then
    echo "ERROR: dnf5 is unavailable; cannot validate ISO build repositories." >&2
    exit 1
fi

enabled_repos="$(dnf5 repo list --enabled)"
if [[ -z "$enabled_repos" ]]; then
    echo "ERROR: DNF5 found no enabled repositories after preparing $TARGET_DIR." >&2
    exit 1
fi

echo "Enabled DNF5 repositories available to bootc-image-builder:"
printf '%s\n' "$enabled_repos"
