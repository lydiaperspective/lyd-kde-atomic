#!/usr/bin/env bash
set -Eeuo pipefail
# Waterfox is provisioned as a system Flatpak by BlueBuild's default-flatpaks
# module. The base system must not retain Firefox as an RPM browser.
if rpm -q firefox >/dev/null 2>&1; then
  echo "Unexpected Firefox RPM detected in base image" >&2
  exit 1
fi

# BlueBuild's Fedora 45 Kinoite NVIDIA base image carries the proprietary
# 580-series driver and a prebuilt, signed kernel module. Verify the branch
# rather than silently shipping a different driver series.
rpm -q nvidia-driver
NVIDIA_VERSION="$(modinfo -F version nvidia)"
if [[ "$NVIDIA_VERSION" != 580.* ]]; then
  echo "Expected proprietary NVIDIA 580.x, found: $NVIDIA_VERSION" >&2
  exit 1
fi
command -v nvidia-smi >/dev/null 2>&1 || { echo "nvidia-smi is missing from the NVIDIA base image" >&2; exit 1; }

# Make Waterfox the system-wide default for web links and HTML documents.
install -d /etc/xdg
cat > /etc/xdg/mimeapps.list <<'EOF'
[Default Applications]
x-scheme-handler/http=net.waterfox.waterfox.desktop
x-scheme-handler/https=net.waterfox.waterfox.desktop
text/html=net.waterfox.waterfox.desktop
application/xhtml+xml=net.waterfox.waterfox.desktop
EOF

install -d /usr/share/lyd
cat > /usr/share/lyd/IMAGE-INFO <<'EOF'
Lyd KDE Atomic
Fedora Kinoite 45 base
Minimal KDE Plasma workstation
Proprietary NVIDIA 580.x driver and prebuilt kernel module
Waterfox is provided as a Flathub Flatpak and is the default web browser.
Optional system features are managed with lydsetup.
EOF
