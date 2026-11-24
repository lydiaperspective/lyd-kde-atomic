#!/usr/bin/env bash
set -Eeuo pipefail
# Standard edition intentionally uses the Fedora Kinoite graphics stack.

systemctl enable lyd-swapfile.service

install -d /etc/xdg
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
while IFS= read -r desktop_file; do
  [[ -n "$desktop_file" ]] || continue
  cat > "/usr/local/share/applications/$desktop_file" <<'DESKTOP'
[Desktop Entry]
Hidden=true
DESKTOP
done < <(find /usr/share/applications -maxdepth 1 -type f -iname '*firefox*.desktop' -printf '%f\\n' 2>/dev/null)

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
    xdg-settings set default-web-browser "$desktop" 2>/dev/null || true
    xdg-mime default "$desktop" x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml
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
Optional system features are preinstalled and managed with lydsetup.
EOF
