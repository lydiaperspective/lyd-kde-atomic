#!/usr/bin/env bash
set -euo pipefail

# Distrobox 1.8.2.5 concatenates ":ro" and ":rslave" as separate
# volume-option fields. Podman requires these options to be comma-separated.
# Upstream fixed this in Distrobox 1.8.2.6.

distrobox_create="$(readlink -f /usr/bin/distrobox-create)"

if [[ ! -f "$distrobox_create" ]]; then
    echo "ERROR: /usr/bin/distrobox-create was not found." >&2
    exit 1
fi

broken='--volume ${rootdir}:/run/host${rootdir}:ro${rslave}"'
fixed='--volume ${rootdir}:/run/host${rootdir}:ro,rslave"'

if grep -Fq -- "$fixed" "$distrobox_create" ||
   { grep -Fq 'rorslave=":ro,rslave"' "$distrobox_create" &&
     grep -Fq '${rootdir}${rorslave}' "$distrobox_create"; }; then
    echo "Distrobox read-only mount options are already fixed."
    exit 0
fi

matches="$(grep -Fc -- "$broken" "$distrobox_create" || true)"
if [[ "$matches" -ne 1 ]]; then
    echo "ERROR: Expected exactly one Distrobox 1.8.2.5 read-only mount expression; found $matches." >&2
    echo "Refusing to modify an unknown Distrobox version." >&2
    exit 1
fi

sed -i "s|${broken}|${fixed}|" "$distrobox_create"

if ! grep -Fq -- "$fixed" "$distrobox_create"; then
    echo "ERROR: Distrobox mount-option patch verification failed." >&2
    exit 1
fi

echo "Patched Distrobox read-only bind mounts to use Podman's valid ':ro,rslave' syntax."
