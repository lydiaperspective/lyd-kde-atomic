#!/usr/bin/env bash
set -Eeuo pipefail

# The open-driver base supplies the kernel module and userspace stack.
command -v nvidia-smi >/dev/null 2>&1 || {
  echo "nvidia-smi is missing from the NVIDIA open base image" >&2
  exit 1
}
rpm -q nvidia-driver >/dev/null 2>&1 || {
  echo "The NVIDIA userspace driver package is missing from the open base image" >&2
  exit 1
}

systemctl enable lyd-swapfile.service

# Set Breeze Dark icons as the system default, migrate existing Plasma profiles at
# login, and configure the separate SDDM greeter icon theme.
install -d /etc/xdg /etc/xdg/autostart /usr/libexec/lyd /etc/sddm.conf.d /usr/share/sddm/themes/breeze
kwriteconfig6 --file /etc/xdg/kdeglobals --group Icons --key Theme breeze-dark

install -D -m 0755 /dev/null /usr/libexec/lyd/lyd-set-breeze-icons
cat > /usr/libexec/lyd/lyd-set-breeze-icons <<'ICON_HELPER'
#!/usr/bin/env bash
set -u
config_file="${XDG_CONFIG_HOME:-$HOME/.config}/kdeglobals"
command -v kwriteconfig6 >/dev/null 2>&1 || exit 0
mkdir -p "$(dirname "$config_file")" || exit 0
kwriteconfig6 --file "$config_file" --group Icons --key Theme breeze-dark >/dev/null 2>&1 || exit 0
ICON_HELPER
chmod 0755 /usr/libexec/lyd/lyd-set-breeze-icons

cat > /etc/xdg/autostart/lyd-set-breeze-icons.desktop <<'AUTOSTART'
[Desktop Entry]
Type=Application
Name=Lyd Breeze Dark Icons
Comment=Apply Breeze Dark icons to Plasma and the lock screen
Exec=/usr/bin/bash /usr/libexec/lyd/lyd-set-breeze-icons
TryExec=/usr/bin/bash
OnlyShowIn=KDE;
X-KDE-autostart-phase=1
X-KDE-autostart-enabled=true
NoDisplay=true
AUTOSTART

# SDDM is a separate Qt greeter: its theme configuration must select the icon
# theme explicitly; the Plasma kdeglobals setting does not configure SDDM.
sddm_theme_config=/usr/share/sddm/themes/breeze/theme.conf.user
if [[ ! -f "$sddm_theme_config" ]]; then
  printf '[General]\n' > "$sddm_theme_config"
fi
sed -i '/^iconTheme[[:space:]]*=/d' "$sddm_theme_config"
if grep -q '^\[General\]' "$sddm_theme_config"; then
  sed -i '/^\[General\]/a iconTheme=breeze-dark' "$sddm_theme_config"
else
  printf '\n[General]\niconTheme=breeze-dark\n' >> "$sddm_theme_config"
fi
cat > /etc/sddm.conf.d/20-lyd-breeze.conf <<'SDDM'
[Theme]
Current=breeze
SDDM

install -d /etc/xdg
kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key BrowserApplication net.waterfox.waterfox.desktop

cat > /etc/xdg/mimeapps.list <<'EOF'
[Default Applications]
x-scheme-handler/http=net.waterfox.waterfox.desktop
x-scheme-handler/https=net.waterfox.waterfox.desktop
text/html=net.waterfox.waterfox.desktop
application/xhtml+xml=net.waterfox.waterfox.desktop
EOF

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
Lyd Atomic NVIDIA Open
Fedora Kinoite 45 base
KDE Plasma workstation with the current NVIDIA open kernel module driver.
Waterfox and SyncThingy are provided as system Flathaks.
EOF
