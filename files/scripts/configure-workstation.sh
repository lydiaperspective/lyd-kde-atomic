#!/usr/bin/env bash
set -Eeuo pipefail
# Keep the base browser set intentionally empty; Waterfox is provisioned as a
# system Flatpak by BlueBuild's default-flatpaks module.
if rpm -q firefox firefox-wayland firefox-langpacks >/dev/null 2>&1; then
  echo "Unexpected Firefox RPM detected in base image" >&2
  exit 1
fi
install -d /usr/share/lyd
cat > /usr/share/lyd/IMAGE-INFO <<'EOF'
Lyd KDE Atomic
Minimal KDE Plasma workstation
Waterfox is provided as a Flathub Flatpak.
Optional system features are managed with lydsetup.
EOF
