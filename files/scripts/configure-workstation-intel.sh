#!/usr/bin/env bash
set -Eeuo pipefail
# Standard edition uses Fedora Kinoite and does not include NVIDIA packages.
# NVIDIA can be optionally layered later with lydsetup.
if rpm -q akmod-nvidia akmod-nvidia-580xx nvidia-driver >/dev/null 2>&1; then
  echo "Unexpected NVIDIA driver package found in standard image" >&2
  exit 1
fi

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
Lyd Atomic Standard
Fedora Kinoite 45 base
Minimal KDE Plasma workstation
No proprietary NVIDIA driver is included by default.
The NVIDIA driver can be installed later using lydsetup.
Waterfox is provided as a Flathub Flatpak and is the default web browser.
Optional system features are managed with lydsetup.
EOF
