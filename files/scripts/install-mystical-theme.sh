#!/usr/bin/env bash
set -Eeuo pipefail

# Pin the shared theme repository so image builds remain reproducible.
THEME_REPO=https://github.com/lydiaperspective/lyd-kde-themes.git
THEME_COMMIT=34c3f016b3461abedc1b779208f446767deb7609
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

install -d /usr/share/color-schemes /usr/share/plasma/look-and-feel /usr/share/plasma/desktoptheme /usr/share/wallpapers /usr/share/icons /usr/share/lyd/mystical
install -m 0644 "$SOURCE/colors/Mystical.colors" /usr/share/color-schemes/Mystical.colors
cp -a "$SOURCE/look-and-feel/org.lydark.mystical.desktop" /usr/share/plasma/look-and-feel/
cp -a "$SOURCE/plasma-style/org.lydark.mystical.desktop" /usr/share/plasma/desktoptheme/
cp -a "$SOURCE/wallpaper" /usr/share/wallpapers/org.lydark.mystical.wallpaper
python3 "$SOURCE/build-icon-theme.py" "$WORK/Mystical"
cp -a "$WORK/Mystical" /usr/share/icons/Mystical
cp -a "$SOURCE/icons" /usr/share/lyd/mystical/
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

[KDE]
LookAndFeelPackage=org.lydark.mystical.desktop
widgetStyle=Breeze

[Icons]
Theme=Mystical
EOF
cat > /etc/xdg/plasmarc <<'EOF'
[Theme]
name=org.lydark.mystical.desktop
EOF
cat > /etc/xdg/ksplashrc <<'EOF'
[KSplash]
Theme=org.lydark.mystical.desktop
EOF
