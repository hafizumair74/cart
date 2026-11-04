#!/usr/bin/env bash
# List / install alternative launchers and remove old sideloaded ones (safe on CVTE TVs).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="${SCRIPT_DIR}/platform-tools"
APK_DIR="${SCRIPT_DIR}/apks"
ADB_PORT="${ADB_PORT:-5555}"

# KEEP: vibe | couchy | arc | projectivy | none
KEEP="${KEEP:-vibe}"
# INSTALL: vibe | couchy | arc | none
INSTALL="${INSTALL:-none}"
REMOVE_OLD="${REMOVE_OLD:-0}"

declare -A LAUNCHER_HOME=(
  [vibe]="com.maydings.vibelauncher/com.maydings.vibelauncher.MainActivity"
  [couchy]="com.conreo.couchytv/com.conreo.couchytv.MainActivity"
  [arc]="com.omeda.arc/com.omeda.arc.MainActivity"
  [projectivy]="com.spocky.projengmenu/com.spocky.projengmenu.ui.home.MainActivity"
  [flauncher]="me.efesser.flauncher/me.efesser.flauncher.MainActivity"
)

declare -A LAUNCHER_URL=(
  [vibe]="https://github.com/maydings/vibe-launcher/releases/latest/download/vibe-launcher.apk"
  [couchy]="https://github.com/conreo/couchy-launcher/releases/download/v1.0.6/Couchy-Launcher-v1.0.6.apk"
  [arc]="https://github.com/meddouribadis/arclauncher/releases/download/1.2.1/arclauncher-1.2.1-armeabi-v7a.apk"
)

# Sideloaded launchers we may uninstall (never CVTE stock)
REMOVABLE_PKGS=(
  me.efesser.flauncher
  com.spocky.projengmenu
  com.maydings.vibelauncher
  com.conreo.couchytv
  com.omeda.arc
)

PROTECTED_REGEX='^(com\.cvte\.|com\.android\.launcher|android$)'

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${CYAN}→${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $0 <TV_IP> [list]

Env:
  INSTALL=vibe|couchy|arc     Install and set as Home (optional)
  KEEP=vibe|couchy|arc|...    Launcher to keep when REMOVE_OLD=1 (default: vibe)
  REMOVE_OLD=1                Uninstall other sideloaded launchers

Examples:
  $0 192.168.0.103 list
  KEEP=vibe REMOVE_OLD=1 $0 192.168.0.103
  INSTALL=couchy REMOVE_OLD=1 KEEP=couchy $0 192.168.0.103
EOF
}

[[ $# -ge 1 ]] || { usage; exit 1; }
TV_IP="$1"
MODE="${2:-apply}"

if [[ -x "${TOOLS_DIR}/adb" ]]; then ADB=("${TOOLS_DIR}/adb")
elif command -v adb >/dev/null 2>&1; then ADB=(adb)
else fail "ADB not found."; fi

adb_shell() { "${ADB[@]}" shell "$@"; }

connect() {
  "${ADB[@]}" disconnect "${TV_IP}:${ADB_PORT}" >/dev/null 2>&1 || true
  "${ADB[@]}" connect "${TV_IP}:${ADB_PORT}" >/dev/null
  state="$("${ADB[@]}" devices | awk -v ip="${TV_IP}:${ADB_PORT}" '$1==ip {print $2}')"
  [[ "$state" == "device" ]] || fail "TV not connected."
}

list_launchers() {
  echo -e "${BOLD}Home activities:${NC}"
  adb_shell cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME 2>/dev/null | tr -d '\r' | grep -E '^com\.' || warn "Could not query HOME"
  echo ""
  echo -e "${BOLD}Installed launcher-like packages:${NC}"
  adb_shell pm list packages 2>/dev/null | tr -d '\r' | grep -iE 'launcher|vibe|couchy|arc|projeng|flauncher|cvte.*launcher' || true
  echo ""
  echo -e "${BOLD}Default Home:${NC}"
  adb_shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME 2>/dev/null | tr -d '\r' || true
  echo ""
  warn "Stock Wisdom Share launcher (com.cvte.tv.launcher.*) must stay installed."
}

install_launcher() {
  local key="$1"
  [[ -n "${LAUNCHER_URL[$key]:-}" ]] || fail "Unknown launcher: $key"
  mkdir -p "$APK_DIR"
  local apk="${APK_DIR}/${key}-launcher.apk"
  info "Installing ${key} ..."
  curl -fsSL -o "$apk" "${LAUNCHER_URL[$key]}"
  "${ADB[@]}" install -r "$apk" | tail -1
  local home="${LAUNCHER_HOME[$key]}"
  info "Setting ${key} as default Home ..."
  adb_shell cmd package set-home-activity --user 0 "$home" 2>/dev/null \
    || adb_shell cmd package set-home-activity "$home" 2>/dev/null || true
  local pkg="${home%%/*}"
  adb_shell appops set "$pkg" APP_AUTO_START allow 2>/dev/null || true
  adb_shell am start -a android.intent.action.MAIN -c android.intent.category.HOME 2>/dev/null || true
  ok "${key} installed and set as Home"
}

remove_old_launchers() {
  local keep_pkg="${LAUNCHER_HOME[$KEEP]%%/*}"
  info "Removing sideloaded launchers except: ${keep_pkg} ..."
  for pkg in "${REMOVABLE_PKGS[@]}"; do
    [[ "$pkg" == "$keep_pkg" ]] && continue
    if adb_shell pm list packages "$pkg" 2>/dev/null | grep -q "$pkg"; then
      if [[ "$pkg" =~ $PROTECTED_REGEX ]]; then
        warn "Skip protected: $pkg"
        continue
      fi
      info "Uninstalling $pkg ..."
      adb_shell pm uninstall -k --user 0 "$pkg" 2>/dev/null && ok "Removed $pkg" \
        || warn "Could not remove $pkg (may already be gone)"
    fi
  done
  ok "Cleanup done — stock CVTE launcher was NOT touched"
}

connect
if [[ "$MODE" == "list" ]]; then
  list_launchers
  echo ""
  cat <<EOF
${BOLD}Try another UI:${NC}
  INSTALL=couchy REMOVE_OLD=1 KEEP=couchy $0 ${TV_IP}
  INSTALL=arc REMOVE_OLD=1 KEEP=arc $0 ${TV_IP}

See LAUNCHER-OPTIONS.md for comparison.
EOF
  exit 0
fi

if [[ "$INSTALL" != "none" && -n "$INSTALL" ]]; then
  install_launcher "$INSTALL"
  KEEP="$INSTALL"
fi

if [[ "$REMOVE_OLD" == "1" ]]; then
  remove_old_launchers
  if [[ -n "${LAUNCHER_HOME[$KEEP]:-}" ]]; then
    adb_shell cmd package set-home-activity --user 0 "${LAUNCHER_HOME[$KEEP]}" 2>/dev/null || true
    adb_shell am start -a android.intent.action.MAIN -c android.intent.category.HOME 2>/dev/null || true
  fi
fi

list_launchers
echo ""
ok "Finished. Press Home on the remote to test."
