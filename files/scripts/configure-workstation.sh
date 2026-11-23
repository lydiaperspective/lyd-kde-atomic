#!/usr/bin/env bash
set -Eeuo pipefail
# Waterfox is provisioned as a system Flatpak by BlueBuild's default-flatpaks
# module. The base system must not retain Firefox as an RPM browser.
if rpm -q firefox >/dev/null 2>&1; then
  echo "Unexpected Firefox RPM detected in base image" >&2
  exit 1
fi

# Require the proprietary 580xx branch and build the matching kernel module.
rpm -q akmod-nvidia-580xx xorg-x11-drv-nvidia-580xx xorg-x11-drv-nvidia-580xx-cuda
command -v akmods >/dev/null 2>&1 || { echo "akmods is missing" >&2; exit 1; }
rpm -q kernel-devel-matched >/dev/null
akmods --force

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
Proprietary NVIDIA 580xx driver branch
Waterfox is provided as a Flathub Flatpak and is the default web browser.
Optional system features are managed with lydsetup.
EOF
