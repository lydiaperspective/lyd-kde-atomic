#!/usr/bin/env bash
set -Eeuo pipefail
# Standard edition intentionally uses the Fedora Kinoite graphics stack.

systemctl enable lyd-swapfile.service

# Make Waterfox and Breeze explicit system-wide KDE defaults for this edition.
install -d /etc/xdg
kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key BrowserApplication net.waterfox.waterfox.desktop
kwriteconfig6 --file /etc/xdg/kdeglobals --group Icons --key Theme breeze

# Existing user configs take precedence over /etc/xdg defaults, so reapply
# Breeze at Plasma login without changing any other user KDE preferences.
install -D -m 0755 /dev/null /usr/libexec/lyd/lyd-standard-breeze-icons
cat > /usr/libexec/lyd/lyd-standard-breeze-icons <<'ICON_HELPER'
#!/usr/bin/env bash
set -Eeuo pipefail
config_file="${XDG_CONFIG_HOME:-$HOME/.config}/kdeglobals"
mkdir -p "$(dirname "$config_file")"
kwriteconfig6 --file "$config_file" --group Icons --key Theme breeze
ICON_HELPER
chmod 0755 /usr/libexec/lyd/lyd-standard-breeze-icons
install -d /etc/xdg/autostart
cat > /etc/xdg/autostart/lyd-standard-breeze-icons.desktop <<'AUTOSTART'
[Desktop Entry]
Type=Application
Name=Lyd Breeze Icon Defaults
Comment=Use the Breeze icon theme on the Standard edition
Exec=/usr/libexec/lyd/lyd-standard-breeze-icons
OnlyShowIn=KDE;
X-KDE-autostart-phase=2
X-KDE-autostart-enabled=true
NoDisplay=true
AUTOSTART
cat > /etc/xdg/mimeapps.list <<'EOF'
[Default Applications]
x-scheme-handler/http=net.waterfox.waterfox.desktop
x-scheme-handler/https=net.waterfox.waterfox.desktop
text/html=net.waterfox.waterfox.desktop
application/xhtml+xml=net.waterfox.waterfox.desktop
EOF

# Fedora Kinoite carries Firefox in its base image. Keep the RPM available for
# recovery, but hide its launcher so Waterfox is the visible browser choice.
install -d /usr/local/share/applications
for desktop_file in firefox.desktop org.mozilla.firefox.desktop org.mozilla.firefox-rpm.desktop; do
  cat > "/usr/local/share/applications/$desktop_file" <<'DESKTOP'
[Desktop Entry]
Hidden=true
DESKTOP
done

# System defaults cover new accounts. Existing accounts get a one-time
# migration from Firefox to Waterfox at their next Plasma login; later browser
# choices are left untouched.
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
Lyd Atomic Standard
Fedora Kinoite 45 base
Minimal KDE Plasma workstation
This edition uses the standard Fedora graphics stack.
Waterfox is provided as a Flathub Flatpak and is the default web browser.
The Fedora base Firefox launcher is hidden; the RPM remains available in the base image.
System image switching and updates are managed with lydmanage; see lydhelp.
EOF
