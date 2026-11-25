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

# Discover on the HTPC is intentionally Flatpak-only. The default launcher
# otherwise loads every available backend, including PackageKit/rpm-ostree,
# which exposes host system packages and can attempt to activate PackageKit.
discover_desktop=/usr/share/applications/org.kde.discover.desktop
if [[ -f "$discover_desktop" ]]; then
    sed -i -E '/^Exec=plasma-discover([[:space:]]|$)/ {
        /^Exec=plasma-discover --backends flatpak([[:space:]]|$)/! s|^Exec=plasma-discover|Exec=plasma-discover --backends flatpak|
    }' "$discover_desktop"
fi

# PackageKit is not used by this Flatpak-only image. Mask its service/socket
# and offline updater so they cannot be started by activation or update hooks.
for unit in packagekit.service packagekit.socket packagekit-offline-update.service; do
    ln -sfn /dev/null "/etc/systemd/system/$unit"
done

chmod 0755 /usr/libexec/lyd/htpc-autologin-setup
# Enable wireless networking and Bluetooth at every boot. The image includes
# NetworkManager's Wi-Fi backend, wpa_supplicant, BlueZ, and KDE Bluedevil.
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable sddm.service
systemctl enable lyd-htpc-autologin.service
systemctl enable lyd-htpc-remote.service
systemctl enable lyd-systemd-daemon-reload.service
systemctl enable lyd-htpc-updates.timer
modprobe uinput || true

if ! flatpak remote-list --system --columns=name | grep -Fxq flathub; then
    flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Tailscale is available but intentionally disabled until configured.
systemctl disable tailscaled.service 2>/dev/null || true

echo "Lyd HTPC configuration complete."
