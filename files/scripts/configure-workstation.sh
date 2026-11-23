#!/usr/bin/env bash
set -Eeuo pipefail
# Keep the base browser set intentionally empty; Waterfox is provisioned as a
# system Flatpak by BlueBuild's default-flatpaks module.
if rpm -q firefox firefox-wayland firefox-langpacks >/dev/null 2>&1; then
  echo "Unexpected Firefox RPM detected in base image" >&2
  exit 1
fi

# Require the 580xx legacy branch rather than silently accepting the current
# NVIDIA branch, which no longer supports Maxwell/Pascal/Volta GPUs.
rpm -q akmod-nvidia-580xx xorg-x11-drv-nvidia-580xx xorg-x11-drv-nvidia-580xx-cuda
command -v akmods >/dev/null 2>&1 || { echo "akmods is missing" >&2; exit 1; }
akmods --force

install -d /usr/share/lyd
cat > /usr/share/lyd/IMAGE-INFO <<'EOF'
Lyd KDE Atomic
Fedora Kinoite 45 base
Minimal KDE Plasma workstation
Proprietary NVIDIA 580xx driver branch
Waterfox is provided as a Flathub Flatpak.
Optional system features are managed with lydsetup.
EOF
