#!/usr/bin/env bash
# Bigger Vibe tiles, fix app list permissions, replace ugly CVTE Media + System Setting apps.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="${SCRIPT_DIR}/platform-tools"
APK_DIR="${SCRIPT_DIR}/apks"
ADB_PORT="${ADB_PORT:-5555}"

VIBE_URL="https://github.com/maydings/vibe-launcher/releases/latest/download/vibe-launcher.apk"
VIBE_PKG="com.maydings.vibelauncher"
VIBE_HOME="${VIBE_PKG}/com.maydings.vibelauncher.MainActivity"

MATERIAL_FILES_URL="https://github.com/zhanghai/MaterialFiles/releases/download/v1.7.5/app-release-universal.apk"
MATERIAL_FILES_PKG="me.zhanghai.android.files"
MATERIAL_FILES_ACTIVITY="${MATERIAL_FILES_PKG}/me.zhanghai.android.files.filelist.FileListActivity"

# Set to 1 to hide CVTE Media Center + CVTE System Setting (replacements must be installed first)
DISABLE_CVTE_UI="${DISABLE_CVTE_UI:-0}"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${CYAN}→${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
fail() { echo -e "${RED:-\033[0;31m}✗${NC} $*" >&2; exit 1; }

[[ $# -ge 1 ]] || { echo "Usage: DISABLE_CVTE_UI=1 $0 TV_IP"; exit 1; }
TV_IP="$1"

if [[ -x "${TOOLS_DIR}/adb" ]]; then ADB=("${TOOLS_DIR}/adb")
elif command -v adb >/dev/null 2>&1; then ADB=(adb)
else fail "ADB not found."; fi

adb_shell() { "${ADB[@]}" shell "$@"; }

"${ADB[@]}" disconnect "${TV_IP}:${ADB_PORT}" >/dev/null 2>&1 || true
"${ADB[@]}" connect "${TV_IP}:${ADB_PORT}" >/dev/null
state="$("${ADB[@]}" devices | awk -v ip="${TV_IP}:${ADB_PORT}" '$1==ip {print $2}')"
[[ "$state" == "device" ]] || fail "TV not connected."
ok "Connected"

info "Updating Vibe Launcher ..."
mkdir -p "$APK_DIR"
curl -fsSL -o "${APK_DIR}/vibe-launcher.apk" "$VIBE_URL"
"${ADB[@]}" install -r "${APK_DIR}/vibe-launcher.apk" | tail -1

info "App-list permissions (fixes empty / broken All apps grid) ..."
adb_shell pm grant "$VIBE_PKG" android.permission.QUERY_ALL_PACKAGES 2>/dev/null || true
adb_shell appops set "$VIBE_PKG" QUERY_ALL_PACKAGES allow 2>/dev/null || true
adb_shell appops set "$VIBE_PKG" GET_USAGE_STATS allow 2>/dev/null || true
adb_shell cmd package set-home-activity --user 0 "$VIBE_HOME" 2>/dev/null || true
ok "Vibe permissions + Home"

info "Installing Material Files (replaces Media Center for browsing) ..."
curl -fsSL -o "${APK_DIR}/MaterialFiles.apk" "$MATERIAL_FILES_URL"
"${ADB[@]}" install -r "${APK_DIR}/MaterialFiles.apk" | tail -1
ok "Material Files installed"

info "CVTE packages on this TV:"
adb_shell pm list packages 2>/dev/null | grep -i cvte | tr -d '\r' || true

disable_if_present() {
  local pkg="$1"
  if adb_shell pm list packages "$pkg" 2>/dev/null | grep -q "$pkg"; then
    if [[ "$DISABLE_CVTE_UI" == "1" ]]; then
      info "Disabling $pkg (use Material Files + Vibe Settings instead) ..."
      adb_shell pm disable-user --user 0 "$pkg" 2>/dev/null && ok "Disabled $pkg" || warn "Could not disable $pkg"
    else
      warn "Found $pkg — run DISABLE_CVTE_UI=1 $0 $TV_IP to hide old Media/Settings UI"
    fi
  fi
}

for pkg in com.cvte.tv.media com.cvte.settings com.cvte.tv.setting com.hisilicon.higallery; do
  disable_if_present "$pkg"
done

info "Opening clean Android settings (Wi‑Fi / system) ..."
adb_shell am start -a android.settings.SETTINGS 2>/dev/null || true

adb_shell am start -n "$VIBE_HOME" 2>/dev/null || true

cat <<EOF

${BOLD}${GREEN}Remote — bigger tiles & All apps${NC}

  ${BOLD}Bigger app cards:${NC}
    Vibe → Settings (top) → General → ${BOLD}Tiles per row → 4${NC} (fewer per row = larger tiles)

  ${BOLD}All apps not opening:${NC}
    • From the ${BOLD}dock${NC}, press ${BOLD}Down${NC} on the remote (official way to open the full grid)
    • Do ${BOLD}not${NC} rely on the grey "All apps" tile — long-press OK → ${BOLD}Hide${NC} it if it is broken
    • Put favorites in the ${BOLD}dock${NC} (long-press OK → Move to dock)

  ${BOLD}Instead of Media Center:${NC}
    Add ${BOLD}Material Files${NC} to the dock → open Download / USB / internal storage

  ${BOLD}Instead of blue System Setting grid:${NC}
    Use Vibe top-right ${BOLD}Settings${NC} pill, or we opened standard Android Settings via ADB
    To hide old CVTE settings app: ${BOLD}DISABLE_CVTE_UI=1 ./fix-vibe-and-system-ui.sh ${TV_IP}${NC}

  ${YELLOW}You cannot reskin CVTE apps in place — only replace or hide them.${NC}

EOF

ok "Done."
