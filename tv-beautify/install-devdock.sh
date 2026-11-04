#!/usr/bin/env bash
# Build (if needed) and install YOUR custom DevDock launcher on the TV.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TV_IP="${1:?Usage: $0 TV_IP}"
APK="${SCRIPT_DIR}/apks/DevDock-launcher.apk"
ADB_PORT="${ADB_PORT:-5555}"
DEVDOCK_PKG="com.devdock.tvlauncher"
DEVDOCK_HOME="${DEVDOCK_PKG}/com.devdock.tvlauncher.MainActivity"

if [[ ! -f "$APK" ]]; then
  "${SCRIPT_DIR}/build-devdock.sh"
fi

if [[ -x "${SCRIPT_DIR}/platform-tools/adb" ]]; then ADB=("${SCRIPT_DIR}/platform-tools/adb")
else ADB=(adb); fi

# Wallpapers for DevDock (same pack as curated home)
WALL_DIR="${SCRIPT_DIR}/wallpapers/curated"
REMOTE_WALL="/sdcard/Download/DevTV/walls"
mkdir -p "$WALL_DIR"
"${ADB[@]}" connect "${TV_IP}:${ADB_PORT}" >/dev/null 2>&1 || true
"${ADB[@]}" shell mkdir -p "$REMOTE_WALL" 2>/dev/null || true
if [[ ! -f "$WALL_DIR/01-mountain-night.jpg" ]]; then
  curl -fsSL -o "$WALL_DIR/01-mountain-night.jpg" \
    "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=1920&q=85" || true
fi
[[ -f "$WALL_DIR/01-mountain-night.jpg" ]] && "${ADB[@]}" push "$WALL_DIR/01-mountain-night.jpg" "$REMOTE_WALL/" >/dev/null 2>&1 || true

"${ADB[@]}" connect "${TV_IP}:${ADB_PORT}" >/dev/null
"${ADB[@]}" install -r "$APK" | tail -1

"${ADB[@]}" shell cmd package set-home-activity --user 0 "$DEVDOCK_HOME" 2>/dev/null || true
"${ADB[@]}" shell appops set "$DEVDOCK_PKG" APP_AUTO_START allow 2>/dev/null || true

for pkg in me.efesser.flauncher com.spocky.projengmenu com.maydings.vibelauncher com.conreo.couchytv com.omeda.arc; do
  "${ADB[@]}" shell pm uninstall -k --user 0 "$pkg" 2>/dev/null || true
done

"${ADB[@]}" shell am start -n "$DEVDOCK_HOME" 2>/dev/null || true

cat <<EOF

✓ DevDock (your launcher) installed.

Press Home → choose DevDock.

Wallpapers: /sdcard/Download/DevTV/walls/*.jpg (changes each time you open Home)
Custom app list: /sdcard/Download/DevTV/devdock_apps.json
  Example: ["com.netflix.ninja","org.videolan.vlc"]

Edit defaults in repo: tv-beautify/devdock-launcher/app/src/main/assets/default_apps.json
Rebuild on laptop: ./build-devdock.sh && ./install-devdock.sh ${TV_IP}

Do NOT disable com.cvte.tv.launcher.space (Wisdom boot).

EOF
