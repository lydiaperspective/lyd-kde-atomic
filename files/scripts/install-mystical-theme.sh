#!/usr/bin/env bash
set -Eeuo pipefail

REAPPLY=0
if [[ "${1:-}" == "--reapply" && $# -eq 1 ]]; then
  REAPPLY=1
elif (($# > 0)); then
  echo "Usage: $0 [--reapply]" >&2
  exit 2
fi

# Pin the shared theme repository so image builds remain reproducible.
THEME_REPO=https://github.com/lydiaperspective/lyd-kde-themes.git
THEME_COMMIT=5b2cad161b12914115d718d36f515a5349ebfd3f
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

command -v git >/dev/null 2>&1 || { echo "git is required to stage Mystical theme assets" >&2; exit 1; }
git clone --quiet --filter=blob:none "$THEME_REPO" "$WORK/theme"
git -C "$WORK/theme" checkout --quiet "$THEME_COMMIT"

SOURCE="$WORK/theme/themes/mystical"
test -f "$SOURCE/colors/Mystical.colors"
test -f "$SOURCE/look-and-feel/org.lydark.mystical.desktop/metadata.json"
test -f "$SOURCE/plasma-style/org.lydark.mystical.desktop/metadata.json"
test -f "$SOURCE/wallpaper/metadata.json"
test -f "$WORK/theme/scripts/lyd-mystical-first-login"

install -d /usr/share/color-schemes /usr/share/plasma/look-and-feel /usr/share/plasma/desktoptheme /usr/share/wallpapers /usr/share/lyd/mystical

# Configure the SDDM login screen separately from the Plasma desktop theme.
# The Breeze greeter remains responsible for login controls; Mystical supplies
# its matching wallpaper as a system-owned, greeter-readable PNG.
SDDM_BACKGROUND=/usr/share/backgrounds/lyd-mystical-sddm.png
install -d /usr/share/backgrounds /etc/sddm.conf.d /usr/share/sddm/themes/breeze
rsvg-convert -w 2560 -h 1440 "$SOURCE/wallpaper/contents/images/1920x1080.svg" -o "$SDDM_BACKGROUND"
cat > /usr/share/sddm/themes/breeze/theme.conf.user <<'SDDM_THEME'
[General]
type=image
background=/usr/share/backgrounds/lyd-mystical-sddm.png
color=#171426
SDDM_THEME
cat > /etc/sddm.conf.d/10-lyd-mystical.conf <<'SDDM_CONFIG'
[Theme]
Current=breeze
SDDM_CONFIG
install -m 0644 "$SOURCE/colors/Mystical.colors" /usr/share/color-schemes/Mystical.colors
cp -a "$SOURCE/look-and-feel/org.lydark.mystical.desktop" /usr/share/plasma/look-and-feel/
# Keep the desktop look and feel while leaving icon and cursor choices to KDE.
sed -i '/^\[kdeglobals\]\[Icons\]$/,/^$/d' /usr/share/plasma/look-and-feel/org.lydark.mystical.desktop/contents/defaults
cp -a "$SOURCE/plasma-style/org.lydark.mystical.desktop" /usr/share/plasma/desktoptheme/
cp -a "$SOURCE/wallpaper" /usr/share/wallpapers/org.lydark.mystical.wallpaper
# The custom Mystical icon theme is intentionally disabled for now.
# Use Breeze Dark icons with the dark Mystical desktop until custom artwork is ready.
# Add coordinated GRUB and animated Plymouth assets. Record the
# exact source revision so the boot setup service can detect image updates.
bash "$WORK/theme/scripts/install-mystical-boot-assets.sh"
# The shared theme installer also stages its optional Xcursor theme. Keep the
# GRUB and Plymouth artwork, but leave KDE's cursor theme at its Breeze default.
rm -rf /usr/share/icons/Mystical/cursors
rm -f /etc/xdg/kcminputrc
printf '%s\n' "$THEME_COMMIT" > /usr/share/lyd/mystical-theme-version
systemctl enable lyd-mystical-boot-setup.service

install -m 0644 "$SOURCE/README.md" /usr/share/lyd/mystical/README.md

# Install the project's first-login wallpaper helper. It only applies the
# bundled wallpaper once, preserving the user's later wallpaper choices.
install -D -m 0755 "$WORK/theme/scripts/lyd-mystical-first-login" /usr/libexec/lyd/lyd-mystical-first-login
install -d /etc/xdg/autostart
cat > /etc/xdg/autostart/lyd-mystical-wallpaper.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Lyd Mystical Wallpaper
Comment=Set the Mystical moonlit garden wallpaper on first login
Exec=/usr/libexec/lyd/lyd-mystical-first-login
OnlyShowIn=KDE;
X-KDE-autostart-phase=2
EOF

# Konsole's matching colour scheme and profile are maintained in the theme repo.
KONSOLE="$WORK/theme/konsole"
if [[ -d "$KONSOLE" ]]; then
  install -d /usr/share/konsole
  install -m 0644 "$KONSOLE/Lyd-Mystical.colorscheme" /usr/share/konsole/
  install -m 0644 "$KONSOLE/Lyd-Mystical.profile" /usr/share/konsole/
fi

# Seed system-wide defaults for new users; per-user settings take precedence.
install -d /etc/xdg
cat > /etc/xdg/kdeglobals <<'EOF'
[General]
ColorScheme=Mystical
AccentColor=152,116,196
BrowserApplication=net.waterfox.waterfox.desktop

[KDE]
LookAndFeelPackage=org.lydark.mystical.desktop
widgetStyle=Breeze

EOF
cat > /etc/xdg/plasmarc <<'EOF'
[Theme]
name=org.lydark.mystical.desktop
EOF
cat > /etc/xdg/ksplashrc <<'EOF'
[KSplash]
Theme=org.lydark.mystical.desktop
EOF

# Keep a privileged reapply entry point on installed systems. The same pinned
# installer is used for image builds and for later theme restoration.
install -D -m 0755 "$BASH_SOURCE" /usr/libexec/lyd/lyd-mystical-theme-reapply

if (( REAPPLY )); then
  # Force the boot setup service to regenerate Plymouth's initramfs and GRUB
  # configuration even when the pinned theme revision has not changed.
  rm -f /var/lib/lyd/mystical-theme-version
  systemctl daemon-reload
  systemctl start lyd-mystical-boot-setup.service
fi
