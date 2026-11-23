#!/usr/bin/env bash
set -Eeuo pipefail
THEME_REPO=https://github.com/lydiaperspective/lyd-kde-deb-live.git
THEME_COMMIT=36451eb09ff509dbf5dbdf18e2504f8f5348ce31
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
command -v git >/dev/null 2>&1 || { echo "git is required to stage Mystical theme assets" >&2; exit 1; }
git clone --quiet --filter=blob:none "$THEME_REPO" "$WORK/theme"
git -C "$WORK/theme" checkout --quiet "$THEME_COMMIT"
SOURCE="$WORK/theme/themes/mystical"
test -f "$SOURCE/colors/Mystical.colors"
install -d /usr/share/color-schemes /usr/share/plasma/look-and-feel /usr/share/plasma/desktoptheme /usr/share/wallpapers /usr/share/icons /usr/share/lyd/mystical
install -m 0644 "$SOURCE/colors/Mystical.colors" /usr/share/color-schemes/Mystical.colors
cp -a "$SOURCE/look-and-feel/org.lydark.mystical.desktop" /usr/share/plasma/look-and-feel/
cp -a "$SOURCE/plasma-style/org.lydark.mystical.desktop" /usr/share/plasma/desktoptheme/
cp -a "$SOURCE/wallpaper" /usr/share/wallpapers/org.lydark.mystical.wallpaper
python3 "$SOURCE/build-icon-theme.py" "$WORK/Mystical"
cp -a "$WORK/Mystical" /usr/share/icons/Mystical
cp -a "$SOURCE/icons" /usr/share/lyd/mystical/
install -m 0644 "$SOURCE/README.md" /usr/share/lyd/mystical/README.md
install -D -m 0644 "$SOURCE/colors/Mystical.colors" /usr/share/lyd/mystical/Mystical.colors
# Seed system-wide defaults for new users; existing per-user settings remain theirs.
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
