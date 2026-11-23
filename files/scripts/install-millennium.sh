#!/usr/bin/env bash
set -Eeuo pipefail

# Millennium 3.6.3 stable Linux x86_64 release.
# Use the public browser-download URL (the GitHub API asset endpoint returns
# HTTP 403 in some unauthenticated build environments) and verify the
# immutable SHA-256 digest published in the release metadata.
VERSION="3.6.3"
ASSET="millennium-v${VERSION}-linux-x86_64.tar.gz"
EXPECTED_SHA256="9d9a5f8448cf92f4634d6ea49b5263409157cccf5b68a8ff10e962c8d7e52c28"
ASSET_URL="https://github.com/SteamClientHomebrew/Millennium/releases/download/v${VERSION}/${ASSET}"

for cmd in curl tar sha256sum; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing build dependency: $cmd" >&2
    exit 1
  }
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/files"

echo "Downloading Millennium v${VERSION} Linux x86_64 release asset..."
curl --fail --location --silent --show-error --retry 3 --retry-all-errors \
  --connect-timeout 20 --max-time 300 \
  -H "User-Agent: Lyd-Atomic-build" \
  "$ASSET_URL" -o "$WORK/$ASSET"

echo "Verifying Millennium release checksum..."
ACTUAL_SHA256="$(sha256sum "$WORK/$ASSET" | awk '{print $1}')"
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
  echo "Millennium checksum mismatch: expected $EXPECTED_SHA256, got $ACTUAL_SHA256" >&2
  exit 1
fi

echo "Extracting Millennium into the image..."
tar -xzf "$WORK/$ASSET" -C "$WORK/files"
test -d "$WORK/files/usr/lib/millennium" || {
  echo "Millennium archive did not contain usr/lib/millennium." >&2
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
