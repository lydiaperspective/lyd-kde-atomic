#!/usr/bin/env bash
set -Eeuo pipefail

# Millennium 3.6.3 stable release. The upstream release checksum is verified
# before any files are copied into the image.
VERSION="3.6.3"
ASSET="millennium-v${VERSION}-linux-x86_64.tar.gz"
BASE="https://github.com/SteamClientHomebrew/Millennium/releases/download/v${VERSION}"

for cmd in curl tar sha256sum; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing build dependency: $cmd" >&2
    exit 1
  }
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/files"

echo "Downloading Millennium v${VERSION} for Linux x86_64..."
curl --fail --location --silent --show-error "$BASE/$ASSET" -o "$WORK/$ASSET"
curl --fail --location --silent --show-error "$BASE/$ASSET.sha256" -o "$WORK/$ASSET.sha256"

echo "Verifying Millennium release checksum..."
(
  cd "$WORK"
  sha256sum --check "$ASSET.sha256"
)

echo "Extracting Millennium into the image..."
tar -xzf "$WORK/$ASSET" -C "$WORK/files"
test -d "$WORK/files/usr/lib/millennium" || {
  echo "Millennium archive did not contain usr/lib/millennium." >&2
  exit 1
}
test -d "$WORK/files/usr/share/millennium" || {
  echo "Millennium archive did not contain usr/share/millennium." >&2
  exit 1
}
cp -a "$WORK/files/." /

for library in \
  /usr/lib/millennium/libmillennium_pvs64 \
  /usr/lib/millennium/libmillennium_luavm_x86 \
  /usr/lib/millennium/libmillennium_luavm_x64; do
  [[ ! -e "$library" ]] || chmod +x "$library"
done

echo "Millennium v${VERSION} is included in the Lyd Atomic workstation image."
