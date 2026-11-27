#!/usr/bin/env bash
set -Eeuo pipefail

# Fedora 42+ Composefs roots cannot be remounted by systemd-remount-fs.
# Root mount options from /etc/fstab are not applied to the live Composefs
# overlay; attempting the remount fails with:
#   overlay: No changes allowed in reconfiguration
# Fedora's Atomic Desktops workaround is to mask this service and manage any
# required root mount options through kernel arguments. These images do not
# define custom /proc, /sys, or /dev entries in /etc/fstab.
install -d /etc/systemd/system
ln -sfn /dev/null /etc/systemd/system/systemd-remount-fs.service

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

# Keep the base Firefox RPM installed, but hide its launcher in favour of
# Waterfox. This avoids an rpm-ostree override against the Fedora base.
install -d /usr/local/share/applications
for desktop_file in firefox.desktop org.mozilla.firefox.desktop org.mozilla.firefox-rpm.desktop; do
  cat > "/usr/local/share/applications/$desktop_file" <<'DESKTOP'
[Desktop Entry]
Hidden=true
DESKTOP
done

install -D -m 0755 /dev/null /usr/libexec/lyd/lyd-default-waterfox
cat > /usr/libexec/lyd/lyd-default-waterfox <<'BROWSER'
#!/usr/bin/env bash
set -Eeuo pipefail
desktop=net.waterfox.waterfox.desktop
current="$(xdg-settings get default-web-browser 2>/dev/null || true)"
case "$current" in
  ""|firefox.desktop|org.mozilla.firefox.desktop|org.mozilla.firefox-rpm.desktop)
    if command -v xdg-settings >/dev/null 2>&1; then
      xdg-settings set default-web-browser "$desktop" 2>/dev/null || true
    fi
    if command -v xdg-mime >/dev/null 2>&1; then
      xdg-mime default "$desktop" x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml
    fi
    ;;
esac
BROWSER
chmod 0755 /usr/libexec/lyd/lyd-default-waterfox
install -d /etc/xdg/autostart
cat > /etc/xdg/autostart/lyd-default-waterfox.desktop <<'AUTOSTART'
[Desktop Entry]
Type=Application
Name=Lyd Default Browser
Comment=Set Waterfox as the default when migrating from Firefox
Exec=/usr/libexec/lyd/lyd-default-waterfox
OnlyShowIn=KDE;
X-KDE-autostart-phase=2
X-KDE-autostart-enabled=true
NoDisplay=true
AUTOSTART

install -d /usr/share/lyd
cat > /usr/share/lyd/IMAGE-INFO <<'EOF'
Lyd Atomic NVIDIA
Fedora Kinoite 45 base
Minimal KDE Plasma workstation
Proprietary NVIDIA 580.x driver and prebuilt kernel module
Waterfox is provided as a Flathub Flatpak and is the default web browser.
System image switching and updates are managed with lydmanage; see lydhelp.
EOF
