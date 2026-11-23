#!/usr/bin/env bash
set -Eeuo pipefail
# NVIDIA proprietary driver packages are present in the image but are not
# activated by default. lydsetup can perform the user-facing configuration.

systemctl enable lyd-swapfile.service

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
NVIDIA driver packages are preinstalled but not enabled by default.
Use lydsetup to review the NVIDIA driver setup and module status.
Waterfox is provided as a Flathub Flatpak and is the default web browser.
Optional system features are preinstalled and managed with lydsetup.
EOF
