#!/usr/bin/env bash
set -Eeuo pipefail

# Bazzite's SteamOS session manager reads this key when the user selects
# "Exit to Desktop" from Steam Gaming Mode.
platform=/usr/share/steamos-manager/platform.toml
[[ -f "$platform" ]] || {
    echo "Missing SteamOS platform configuration: $platform" >&2
    exit 1
}

python3 - "$platform" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
lines = path.read_text().splitlines()
updated = []
in_session = False
session_found = False
desktop_written = False
for line in lines:
    if line.strip() == "[session]":
        if in_session and not desktop_written:
            updated.append('desktop = "plasma-bigscreen-wayland.desktop"')
            desktop_written = True
        in_session = True
        session_found = True
        desktop_written = False
        updated.append(line)
        continue
    if line.lstrip().startswith("[") and line.rstrip().endswith("]"):
        if in_session and not desktop_written:
            updated.append('desktop = "plasma-bigscreen-wayland.desktop"')
            desktop_written = True
        in_session = False
    if in_session and re.match(r"^\s*desktop\s*=", line):
        if not desktop_written:
            updated.append('desktop = "plasma-bigscreen-wayland.desktop"')
            desktop_written = True
        continue
    updated.append(line)

if in_session and not desktop_written:
    updated.append('desktop = "plasma-bigscreen-wayland.desktop"')
if not session_found:
    updated.extend(["", "[session]", 'desktop = "plasma-bigscreen-wayland.desktop"'])

path.write_text("\n".join(updated) + "\n")
PY

# Bigscreen has a launcher but no traditional desktop. Install the action in
# the application menu and seed it onto new users' desktops as well.
install -d /usr/share/applications /etc/skel/Desktop
cat > /usr/share/applications/lyd-switch-to-gamescope.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Switch to Gamescope
Comment=Return to Steam Gaming Mode
Exec=/usr/bin/return-to-gamemode
Icon=steam
Terminal=false
Categories=System;
DESKTOP
install -m 0755 /usr/share/applications/lyd-switch-to-gamescope.desktop /etc/skel/Desktop/lyd-switch-to-gamescope.desktop

# Set Waterfox as the browser for new users and as the system fallback.
mkdir -p /etc/skel/.config
cat > /usr/share/applications/mimeapps.list <<'MIMEAPPS'
[Default Applications]
text/html=net.waterfox.waterfox.desktop
application/xhtml+xml=net.waterfox.waterfox.desktop
x-scheme-handler/http=net.waterfox.waterfox.desktop
x-scheme-handler/https=net.waterfox.waterfox.desktop
MIMEAPPS
install -m 0644 /usr/share/applications/mimeapps.list /etc/skel/.config/mimeapps.list

# Match the server and HTPC images by reloading unit files at every boot.
systemctl enable lyd-systemd-daemon-reload.service

# Configure Plasma's Wayland virtual keyboard for Bigscreen touch input. These
# same settings are used by Bazzite's restore-virtual-keyboard command.
install -d /etc/xdg /etc/skel/.config
for config in /etc/xdg/kwinrc /etc/skel/.config/kwinrc; do
    kwriteconfig6 --file "$config" --group Wayland --key InputMethod /usr/share/applications/org.kde.plasma.keyboard.desktop
    kwriteconfig6 --file "$config" --group Wayland --key VirtualKeyboardEnabled --type bool true
done
