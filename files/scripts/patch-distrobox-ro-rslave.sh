#!/usr/bin/env bash
set -Eeuo pipefail

# Fedora's workstation image must contain Distrobox before this compatibility
# patch runs. Keep this patch idempotent so newer upstream releases are safe.

command -v python3 >/dev/null 2>&1 || {
    echo "ERROR: python3 is required to patch Distrobox." >&2
    exit 1
}

distrobox_create="/usr/bin/distrobox-create"
if [[ ! -e "$distrobox_create" ]]; then
    echo "ERROR: Distrobox is not installed; expected $distrobox_create." >&2
    exit 1
fi

distrobox_create="$(readlink -f "$distrobox_create")"
if [[ ! -f "$distrobox_create" ]]; then
    echo "ERROR: Could not resolve the Distrobox create script." >&2
    exit 1
fi

python3 - "$distrobox_create" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

# Current upstream syntax: the mount propagation option is part of the
# same comma-separated Podman volume option list.
fixed = '--volume ${rootdir}:/run/host${rootdir}:ro,rslave"'
upstream_fixed = (
    'rorslave=":ro,rslave"' in text
    and '${rootdir}${rorslave}' in text
)

if fixed in text or upstream_fixed:
    print("Distrobox read-only mount options are already fixed.")
    raise SystemExit(0)

broken = '--volume ${rootdir}:/run/host${rootdir}:ro${rslave}"'
count = text.count(broken)
if count != 1:
    print(
        f"ERROR: Expected one known Distrobox read-only mount expression; "
        f"found {count}. Refusing to modify an unknown version.",
        file=sys.stderr,
    )
    raise SystemExit(1)

path.write_text(text.replace(broken, fixed, 1))
verified = path.read_text()
if fixed not in verified:
    print("ERROR: Distrobox mount-option patch verification failed.", file=sys.stderr)
    raise SystemExit(1)

print("Patched Distrobox read-only bind mounts to use ':ro,rslave'.")
PY
