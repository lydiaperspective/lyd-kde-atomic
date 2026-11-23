#!/usr/bin/env bash
set -Eeuo pipefail
# Waterfox is provisioned as a system Flatpak and configured as the default browser.
# The Kinoite base may also retain its Firefox RPM; it is not the default.
# Verify the NVIDIA userspace driver is present and on the expected branch.
# Do not use modinfo here: image builds do not have the host's booted kernel
# module tree, so a valid prebuilt NVIDIA module may not be visible at build
# time. Kernel-module availability is a runtime/boot validation.
NVIDIA_PACKAGE="$(rpm -q --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}' nvidia-driver)"
echo "Detected NVIDIA driver package: $NVIDIA_PACKAGE"
if [[ ! "$NVIDIA_PACKAGE" =~ ^nvidia-driver-580\. ]]; then
  echo "Expected proprietary NVIDIA 580.x, found: $NVIDIA_PACKAGE" >&2
  exit 1
fi
command -v nvidia-smi >/dev/null 2>&1 || { echo "nvidia-smi is missing from the NVIDIA base image" >&2; exit 1; }

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
Lyd Atomic NVIDIA
Fedora Kinoite 45 base
Minimal KDE Plasma workstation
Proprietary NVIDIA 580.x driver and prebuilt kernel module
Waterfox is provided as a Flathub Flatpak and is the default web browser.
Optional system features are managed with lydsetup.
EOF
