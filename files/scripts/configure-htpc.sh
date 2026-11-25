#!/usr/bin/env bash
set -Eeuo pipefail

chmod 0755 /usr/libexec/lyd/htpc-autologin-setup
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable sddm.service
systemctl enable lyd-htpc-autologin.service
systemctl enable lyd-htpc-remote.service
modprobe uinput || true

if ! flatpak remote-list --system --columns=name | grep -Fxq flathub; then
    flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

echo "Lyd HTPC configuration complete."
