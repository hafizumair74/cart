#!/usr/bin/env bash
# Premium "developer desk" TV look: Projectivy + dark wallpapers + trim stock launcher.
# Run on laptop (same Wi‑Fi). TV should already have USB debugging enabled.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APK_DIR="${SCRIPT_DIR}/apks"
TOOLS_DIR="${SCRIPT_DIR}/platform-tools"
BACKUP_DIR="${SCRIPT_DIR}/.backup"
WALL_DIR="${SCRIPT_DIR}/wallpapers"

PROJECTIVY_VERSION="4.73"
PROJECTIVY_URL="https://github.com/spocky/miproja1/releases/download/${PROJECTIVY_VERSION}/ProjectivyLauncher-${PROJECTIVY_VERSION}-c98-xda-release.apk"
PROJECTIVY_SHA256="74e33af1e5e13831a69a0669d2b68b02150bf9df1ae1df437dc67e3f8d52c790"
PROJECTIVY_PKG="com.spocky.projengmenu"
PROJECTIVY_HOME="${PROJECTIVY_PKG}/com.spocky.projengmenu.ui.home.MainActivity"

ADB_PORT="${ADB_PORT:-5555}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${CYAN}→${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

usage() {
  echo "Usage: $(basename "$0") <TV_IP>"
  echo "Example: $(basename "$0") 192.168.0.103"
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

ensure_adb() {
  if [[ -x "${TOOLS_DIR}/adb" ]]; then
    ADB=("${TOOLS_DIR}/adb")
  elif command -v adb >/dev/null 2>&1; then
    ADB=(adb)
  else
    fail "ADB not found. Run beautify-tv.sh once first, or install android-tools-adb."
  fi
}

adb_shell() { "${ADB[@]}" shell "$@"; }

connect_tv() {
  local ip="$1"
  "${ADB[@]}" disconnect "${ip}:${ADB_PORT}" >/dev/null 2>&1 || true
  "${ADB[@]}" connect "${ip}:${ADB_PORT}" >/dev/null
  local state
  state="$("${ADB[@]}" devices | awk -v ip="${ip}:${ADB_PORT}" '$1==ip {print $2}')"
  [[ "$state" == "device" ]] || fail "TV not ready (state: ${state:-offline}). Check USB debugging."
  ok "Connected to ${ip}"
}

install_projectivy() {
  mkdir -p "$APK_DIR"
  local apk="${APK_DIR}/ProjectivyLauncher.apk"
  if [[ ! -f "$apk" ]] || [[ "$(sha256_file "$apk")" != "$PROJECTIVY_SHA256" ]]; then
    info "Downloading Projectivy Launcher (premium TV UI) ..."
    curl -fsSL -o "$apk" "$PROJECTIVY_URL"
    [[ "$(sha256_file "$apk")" == "$PROJECTIVY_SHA256" ]] || fail "Projectivy checksum mismatch"
  else
    ok "Using cached Projectivy APK"
  fi
  info "Installing Projectivy ..."
  "${ADB[@]}" install -r "$apk" | tail -1
  ok "Projectivy installed"
}

set_projectivy_home() {
  info "Setting Projectivy as default Home ..."
  adb_shell cmd package set-home-activity --user 0 "$PROJECTIVY_HOME" \
    || adb_shell cmd package set-home-activity "$PROJECTIVY_HOME" \
    || fail "Could not set Projectivy as Home (TV may block it)"
  adb_shell appops set "$PROJECTIVY_PKG" APP_AUTO_START allow 2>/dev/null || true
  adb_shell appops set "$PROJECTIVY_PKG" AUTO_START allow 2>/dev/null || true
  adb_shell dumpsys deviceidle whitelist "+${PROJECTIVY_PKG}" 2>/dev/null || true
  ok "Projectivy is now default Home"
}

disable_other_home_apps() {
  mkdir -p "$BACKUP_DIR"
  info "Finding stock launchers to disable (keeps Projectivy only) ..."
  local list
  list="$(adb_shell cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME 2>/dev/null | tr -d '\r' || true)"
  if [[ -z "$list" ]]; then
    list="$(adb_shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME 2>/dev/null | tr -d '\r' || true)"
  fi

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ "$line" == *"No activity found"* ]] && continue
    local pkg="${line%%/*}"
    [[ "$pkg" == "$PROJECTIVY_PKG" ]] && continue
    case "$pkg" in
      com.android.settings|com.android.systemui|com.google.android.gms) continue ;;
    esac
    info "Disabling launcher package: ${pkg}"
    if adb_shell pm disable-user --user 0 "$pkg" 2>/dev/null; then
      echo "$pkg" >>"${BACKUP_DIR}/disabled-packages.txt"
      ok "Disabled ${pkg}"
    else
      warn "Could not disable ${pkg}"
    fi
  done <<< "$list"
}

push_dev_wallpapers() {
  mkdir -p "$WALL_DIR"
  local remote="/sdcard/Download/DevTV"
  adb_shell mkdir -p "$remote" 2>/dev/null || true

  # Dark, dev-aesthetic stills (1920-wide, static = best on 1GB RAM)
  declare -A WALLS=(
    ["wall-code-dark.jpg"]="https://images.unsplash.com/photo-1517694712202-14dd9538aa7f?auto=format&w=1920&q=80"
    ["wall-terminal.jpg"]="https://images.unsplash.com/photo-1555068935-fa187a1d4f0e?auto=format&w=1920&q=80"
    ["wall-matrix-green.jpg"]="https://images.unsplash.com/photo-1555949963-aa79dcee981c?auto=format&w=1920&q=80"
  )

  info "Copying developer wallpapers to TV (${remote}) ..."
  for name in "${!WALLS[@]}"; do
    local path="${WALL_DIR}/${name}"
    if [[ ! -f "$path" ]]; then
      curl -fsSL -o "$path" "${WALLS[$name]}" || warn "Skip download $name"
    fi
    [[ -f "$path" ]] && "${ADB[@]}" push "$path" "${remote}/${name}" >/dev/null && ok "Pushed ${name}"
  done
}

tune_system_ui() {
  info "Small system tweaks (developer-friendly, safe) ..."
  adb_shell settings put global device_provisioned 1 2>/dev/null || true
  adb_shell settings put secure screensaver_enabled 0 2>/dev/null || true
  adb_shell settings put system screen_off_timeout 3600000 2>/dev/null || true
  ok "System tweaks applied"
}

open_projectivy_home() {
  adb_shell am start -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null 2>&1 || true
}

print_finish() {
  echo ""
  echo -e "${BOLD}${GREEN}Developer TV — finish on the remote (5 min)${NC}"
  echo ""
  echo -e "  1. Press ${CYAN}Home${NC} → ${BOLD}Projectivy${NC} should open (not the old store UI)."
  echo -e "  2. Projectivy ${CYAN}Settings${NC} (gear):"
  echo "       • Wallpaper → Local file → /sdcard/Download/DevTV/wall-code-dark.jpg"
  echo "       • Card style → smaller / transparent cards (cleaner)"
  echo "       • Categories → Dev · Media · System — hide App Store junk"
  echo "       • Turn OFF animated/video wallpaper (1GB RAM stays fast)"
  echo -e "  3. If Home still flashes the old UI:"
  echo "       • Projectivy Settings → enable Accessibility override if offered"
  echo "       • Unplug TV power 30 sec, boot again"
  echo -e "  4. Optional: uninstall ${CYAN}FLauncher${NC} in Settings → Apps if you don't need it."
  echo ""
}

main() {
  [[ $# -ge 1 ]] || { usage; exit 1; }
  local ip="$1"
  echo ""
  info "Developer TV upgrade (Projectivy + wallpapers)"
  echo ""
  ensure_adb
  connect_tv "$ip"
  install_projectivy
  set_projectivy_home
  disable_other_home_apps
  push_dev_wallpapers
  tune_system_ui
  open_projectivy_home
  print_finish
  ok "Done — configure Projectivy wallpaper on the TV for the final look."
}

main "$@"
