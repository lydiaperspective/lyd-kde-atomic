#!/usr/bin/env bash
set -Eeuo pipefail
# Intel variant intentionally uses the standard Fedora Kinoite base and does
# not install NVIDIA proprietary drivers or NVIDIA-specific kernel modules.
if rpm -q akmod-nvidia akmod-nvidia-580xx nvidia-driver >/dev/null 2>&1; then
  echo "Unexpected NVIDIA driver package found in Intel image" >&2
  exit 1
fi

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
Lyd KDE Atomic — Intel / generic graphics edition
Fedora Kinoite 45 base
Minimal KDE Plasma workstation
No proprietary NVIDIA driver is included.
Waterfox is provided as a Flathub Flatpak and is the default web browser.
Optional system features are managed with lydsetup.
EOF
