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

echo "Lyd HTPC configuration complete."
