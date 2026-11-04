#!/usr/bin/env bash
# Restore Home button + set Projectivy safely (do NOT brick launchers).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="${SCRIPT_DIR}/platform-tools"
BACKUP_DIR="${SCRIPT_DIR}/.backup"
ADB_PORT="${ADB_PORT:-5555}"

PROJECTIVY_PKG="com.spocky.projengmenu"
PROJECTIVY_HOME="${PROJECTIVY_PKG}/com.spocky.projengmenu.ui.home.MainActivity"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${CYAN}→${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

[[ $# -ge 1 ]] || { echo "Usage: $0 TV_IP"; exit 1; }
TV_IP="$1"

if [[ -x "${TOOLS_DIR}/adb" ]]; then
  ADB=("${TOOLS_DIR}/adb")
elif command -v adb >/dev/null 2>&1; then
  ADB=(adb)
else
  fail "ADB not found. Run from ~/tv-beautify after beautify-tv.sh."
fi

adb_shell() { "${ADB[@]}" shell "$@"; }

"${ADB[@]}" disconnect "${TV_IP}:${ADB_PORT}" >/dev/null 2>&1 || true
"${ADB[@]}" connect "${TV_IP}:${ADB_PORT}" >/dev/null
state="$("${ADB[@]}" devices | awk -v ip="${TV_IP}:${ADB_PORT}" '$1==ip {print $2}')"
[[ "$state" == "device" ]] || fail "TV not connected (state: ${state:-offline})"
ok "Connected to ${TV_IP}"

info "Re-enabling disabled apps (fixes dead Home button) ..."
if [[ -f "${BACKUP_DIR}/disabled-packages.txt" ]]; then
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    adb_shell pm enable --user 0 "$pkg" 2>/dev/null && ok "Enabled $pkg" || true
  done <"${BACKUP_DIR}/disabled-packages.txt"
fi

disabled="$(adb_shell pm list packages -d 2>/dev/null | cut -d: -f2 | tr -d '\r' || true)"
if [[ -n "$disabled" ]]; then
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    if echo "$pkg" | grep -qiE 'launcher|home|leanback|projeng|flauncher|tvlauncher'; then
      adb_shell pm enable --user 0 "$pkg" 2>/dev/null && ok "Enabled $pkg"
    fi
  done <<< "$disabled"
fi

info "Ensuring Projectivy is enabled ..."
adb_shell pm enable --user 0 "$PROJECTIVY_PKG" 2>/dev/null || true
adb_shell pm clear "$PROJECTIVY_PKG" 2>/dev/null || true

info "Setting Projectivy as default Home (safe mode — stock launcher stays installed) ..."
adb_shell cmd package set-home-activity --user 0 "$PROJECTIVY_HOME" 2>/dev/null \
  || adb_shell cmd package set-home-activity "$PROJECTIVY_HOME" 2>/dev/null \
  || warn "set-home-activity failed — enable stock launcher from TV settings if needed"

adb_shell appops set "$PROJECTIVY_PKG" APP_AUTO_START allow 2>/dev/null || true
adb_shell appops set "$PROJECTIVY_PKG" AUTO_START allow 2>/dev/null || true

info "Launching Home ..."
adb_shell am start -a android.intent.action.MAIN -c android.intent.category.HOME 2>/dev/null || true
adb_shell input keyevent KEYCODE_HOME 2>/dev/null || true

echo ""
ok "Home should work again. Press Home on the remote."
echo ""
warn "Do NOT disable the stock launcher again."
echo "On the TV: Projectivy → Settings → turn ON Accessibility / override if offered."
echo "Then: Wallpaper → /sdcard/Download/DevTV/wall-code-dark.jpg"
echo ""
