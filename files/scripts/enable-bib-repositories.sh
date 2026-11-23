#!/usr/bin/env bash
set -Eeuo pipefail

# Fedora 45 moved its DNF5 repository definitions into /usr/share/dnf5/repos.d.
# bootc-image-builder's ISO dependency solver expects the traditional
# /etc/yum.repos.d location, so expose the vendor-managed files there as well.
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
    ln -sfn "$repo_file" "$TARGET_DIR/$repo_name"
done

if [[ ! -e "$TARGET_DIR/fedora.repo" || ! -e "$TARGET_DIR/fedora-updates.repo" ]]; then
    echo "ERROR: Fedora release and updates repositories were not exposed." >&2
    exit 1
fi

if ! grep -Eq '^[[:space:]]*enabled[[:space:]]*=[[:space:]]*1([[:space:]]|$)' \
    "$TARGET_DIR/fedora.repo" "$TARGET_DIR/fedora-updates.repo"; then
    echo "ERROR: Fedora release repositories are not enabled." >&2
    exit 1
fi

echo "Fedora DNF repositories exposed under $TARGET_DIR:"
printf '  %s\n' "${repo_files[@]##*/}"
