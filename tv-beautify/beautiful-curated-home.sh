#!/usr/bin/env bash
# Your curated Wisdom Share apps only — beautiful, light home (Couchy + wallpapers + cleanup).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="${SCRIPT_DIR}/platform-tools"
APK_DIR="${SCRIPT_DIR}/apks"
WALL_DIR="${SCRIPT_DIR}/wallpapers/curated"
ADB_PORT="${ADB_PORT:-5555}"

COUCHY_URL="https://github.com/conreo/couchy-launcher/releases/download/v1.0.6/Couchy-Launcher-v1.0.6.apk"
COUCHY_PKG="com.conreo.couchytv"
COUCHY_HOME="${COUCHY_PKG}/com.conreo.couchytv.MainActivity"

MATERIAL_FILES_URL="https://github.com/zhanghai/MaterialFiles/releases/download/v1.7.5/app-release-universal.apk"

TV_IP="${1:?Usage: $0 TV_IP}"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${CYAN}→${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
fail() { echo -e "${RED:-\033[0;31m}✗${NC} $*" >&2; exit 1; }

if [[ -x "${TOOLS_DIR}/adb" ]]; then ADB=("${TOOLS_DIR}/adb")
else ADB=(adb); fi
adb_shell() { "${ADB[@]}" shell "$@"; }

"${ADB[@]}" disconnect "${TV_IP}:${ADB_PORT}" >/dev/null 2>&1 || true
"${ADB[@]}" connect "${TV_IP}:${ADB_PORT}" >/dev/null
state="$("${ADB[@]}" devices | awk -v ip="${TV_IP}:${ADB_PORT}" '$1==ip {print $2}')"
[[ "$state" == "device" ]] || fail "TV not connected."

ok "Connected"

# --- Wallpapers (dark / dev / cinematic, static for 1GB RAM) ---
mkdir -p "$WALL_DIR"
declare -A WALLS=(
  ["01-mountain-night.jpg"]="https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=1920&q=85"
  ["02-code-desk.jpg"]="https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1920&q=85"
  ["03-aurora.jpg"]="https://images.unsplash.com/photo-1483347756197-71ef80e95f73?auto=format&fit=crop&w=1920&q=85"
  ["04-dark-gradient.jpg"]="https://images.unsplash.com/photo-1557683316-973673baf926?auto=format&fit=crop&w=1920&q=85"
  ["05-city-night.jpg"]="https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=1920&q=85"
  ["06-matrix.jpg"]="https://images.unsplash.com/photo-1555949963-aa79dcee981c?auto=format&fit=crop&w=1920&q=85"
  ["07-space.jpg"]="https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=1920&q=85"
  ["08-minimal-dark.jpg"]="https://images.unsplash.com/photo-1557682250-33bd709cbe85?auto=format&fit=crop&w=1920&q=85"
)

REMOTE_WALL="/sdcard/Download/DevTV/walls"
adb_shell mkdir -p "$REMOTE_WALL" 2>/dev/null || true
info "Uploading wallpaper pack ..."
for name in "${!WALLS[@]}"; do
  dest="${WALL_DIR}/${name}"
  [[ -f "$dest" ]] || curl -fsSL -o "$dest" "${WALLS[$name]}" || continue
  "${ADB[@]}" push "$dest" "${REMOTE_WALL}/${name}" >/dev/null && ok "Wall: $name"
done

# --- Couchy (light, glass, one screen — “your own” feel) ---
info "Installing Couchy Launcher ..."
curl -fsSL -o "${APK_DIR}/couchy.apk" "$COUCHY_URL"
"${ADB[@]}" install -r "${APK_DIR}/couchy.apk" | tail -1

info "Installing Material Files (Media tile replacement) ..."
curl -fsSL -o "${APK_DIR}/MaterialFiles.apk" "$MATERIAL_FILES_URL"
"${ADB[@]}" install -r "${APK_DIR}/MaterialFiles.apk" | tail -1

info "Setting Couchy as Home ..."
adb_shell cmd package set-home-activity --user 0 "$COUCHY_HOME" 2>/dev/null || true
adb_shell appops set "$COUCHY_PKG" APP_AUTO_START allow 2>/dev/null || true

# Remove sideloaded clutter launchers (NOT cvte stock)
for pkg in me.efesser.flauncher com.spocky.projengmenu com.maydings.vibelauncher com.omeda.arc; do
  adb_shell pm uninstall -k --user 0 "$pkg" 2>/dev/null && ok "Removed old launcher: $pkg" || true
done

adb_shell pm grant "$COUCHY_PKG" android.permission.QUERY_ALL_PACKAGES 2>/dev/null || true
adb_shell am start -n "$COUCHY_HOME" 2>/dev/null || true

cat <<EOF

${BOLD}${GREEN}Make it yours — only your tiles (5 min on remote)${NC}

${BOLD}1. Layout${NC} (Couchy Settings):
   • Layout → ${BOLD}Dock${NC} or ${BOLD}Grid${NC} (pick one look)
   • Wallpaper → ${BOLD}Photo${NC} → ${REMOTE_WALL}/01-mountain-night.jpg
   • Try 02–08 in that folder anytime
   • Icon size → ${BOLD}Large${NC}  |  Dim background → ${BOLD}On${NC} (readable + light GPU)

${BOLD}2. Keep ONLY these apps${NC} (hide everything else):
   YouTube · Netflix · Prime Video · Disney+ · VLC
   AirScreen · Browser · Material Files (instead of Media)
   App Store · Tamasha · Dunya News · VPN · Kindlink (if you use it)
   Long-press → hide apps you do not want.

${BOLD}3. Drop the Wisdom clutter${NC}
   • No weather giant tiles — Couchy has a small clock only
   • HDMI: add inputs in Couchy if needed, or ignore if you use laptop HDMI

${BOLD}4. Default Home${NC}
   Press Home → pick ${BOLD}Couchy${NC}. If old screen returns:
   Couchy Settings → set as default / run:
   ${BOLD}./wisdom-share-fix.sh ${TV_IP}${NC} then enable Projectivy-style override in Couchy if offered.

${BOLD}5. Package names${NC} (if an app missing from list):
   ${BOLD}./discover-curated-apps.sh ${TV_IP}${NC}

Stock ${BOLD}WISDOM SHARE${NC} launcher stays installed (required for boot) but you never need to open it.

EOF

ok "Curated beautiful home ready — tune Couchy wallpaper + dock now."
