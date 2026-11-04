#!/usr/bin/env bash
# Minimal "Apple TV style" home: Vibe Launcher (dock + full-screen art, no clutter).
# Safe on Wisdom Share — does NOT disable com.cvte.tv.launcher.space.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="${SCRIPT_DIR}/platform-tools"
APK_DIR="${SCRIPT_DIR}/apks"
ADB_PORT="${ADB_PORT:-5555}"

VIBE_URL="https://github.com/maydings/vibe-launcher/releases/latest/download/vibe-launcher.apk"
VIBE_SHA256="1acb15a4785c321a0d2439f71af299c0bd3234cb745efba9f34f545051bfe3a8"
VIBE_PKG="com.maydings.vibelauncher"
VIBE_HOME="${VIBE_PKG}/com.maydings.vibelauncher.MainActivity"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${CYAN}→${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
fail() { echo -e "${RED:-\033[0;31m}✗${NC} $*" >&2; exit 1; }

[[ $# -ge 1 ]] || { echo "Usage: $0 TV_IP"; exit 1; }
TV_IP="$1"

if [[ -x "${TOOLS_DIR}/adb" ]]; then ADB=("${TOOLS_DIR}/adb")
elif command -v adb >/dev/null 2>&1; then ADB=(adb)
else fail "ADB not found (run from ~/tv-beautify)."; fi

adb_shell() { "${ADB[@]}" shell "$@"; }

sha256_file() {
  sha256sum "$1" 2>/dev/null | awk '{print $1}' || shasum -a 256 "$1" | awk '{print $1}'
}

"${ADB[@]}" disconnect "${TV_IP}:${ADB_PORT}" >/dev/null 2>&1 || true
"${ADB[@]}" connect "${TV_IP}:${ADB_PORT}" >/dev/null
state="$("${ADB[@]}" devices | awk -v ip="${TV_IP}:${ADB_PORT}" '$1==ip {print $2}')"
[[ "$state" == "device" ]] || fail "TV not connected."

ok "Connected to ${TV_IP}"

info "Ensuring Wisdom Share launcher stays enabled (required for boot) ..."
adb_shell pm enable --user 0 com.cvte.tv.launcher.space 2>/dev/null || true

mkdir -p "$APK_DIR"
apk="${APK_DIR}/vibe-launcher.apk"
if [[ ! -f "$apk" ]] || [[ "$(sha256_file "$apk")" != "$VIBE_SHA256" ]]; then
  info "Downloading Vibe Launcher (minimal Apple-TV-style UI) ..."
  curl -fsSL -o "$apk" "$VIBE_URL"
  [[ "$(sha256_file "$apk")" == "$VIBE_SHA256" ]] || warn "Checksum mismatch — continuing anyway"
fi

info "Installing Vibe Launcher ..."
"${ADB[@]}" install -r "$apk" | tail -1
ok "Vibe Launcher installed"

info "Setting Vibe as default Home activity ..."
adb_shell cmd package set-home-activity --user 0 "$VIBE_HOME" 2>/dev/null \
  || adb_shell cmd package set-home-activity "$VIBE_HOME" 2>/dev/null || true

adb_shell appops set "$VIBE_PKG" APP_AUTO_START allow 2>/dev/null || true
adb_shell dumpsys deviceidle whitelist "+${VIBE_PKG}" 2>/dev/null || true

info "Opening Vibe Launcher ..."
adb_shell am start -n "$VIBE_HOME" 2>/dev/null || true

cat <<EOF

${BOLD}${GREEN}Minimal setup on the remote (like the Instagram reel)${NC}

  1. In ${BOLD}Vibe Launcher → Settings${NC} (top bar):
     • ${BOLD}Default launcher${NC} → choose ${BOLD}Vibe Launcher${NC} (not stock TV home)
  2. ${BOLD}Dock${NC}: keep only 4–6 apps (e.g. YouTube, VLC, Netflix, Browser)
     • Remove extras — press and hold / options on each tile
  3. Press ${BOLD}Down${NC} only when you need the full app list (hidden by default feel)
  4. Optional: Settings → ${BOLD}Debloat${NC} to hide junk (safe lists; do NOT disable cvte launcher)

  ${YELLOW}FLauncher / Projectivy:${NC} you can hide or uninstall in Settings → Apps if unused.

  Boot ${BOLD}WISDOM SHARE${NC} video at power-on: still needs factory menu (1147) or root — separate issue.

EOF

ok "Done."
