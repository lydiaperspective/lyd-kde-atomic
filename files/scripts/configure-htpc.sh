#!/usr/bin/env bash
set -Eeuo pipefail

# Plasma Bigscreen is the dedicated living-room session for this image.
# A first-boot unit selects the first regular user created by Anaconda and
# configures SDDM autologin for that account.
systemctl enable sddm.service
systemctl enable lyd-htpc-autologin.service

# Ensure the standard Flathub system remote is available for first boot and
# for later Flatpak updates.
if ! flatpak remote-list --system --columns=name | grep -Fxq flathub; then
    flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

echo "Lyd HTPC configuration complete."
