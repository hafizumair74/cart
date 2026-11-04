#!/usr/bin/env bash
# Install Projectivy Launcher + Aerial Views on Android TV / Google TV over Wi‑Fi (ADB).
# Run this on your LAPTOP while it is on the same Wi‑Fi as the TV.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APK_DIR="${SCRIPT_DIR}/apks"
TOOLS_DIR="${SCRIPT_DIR}/platform-tools"
BACKUP_DIR="${SCRIPT_DIR}/.backup"

PROJECTIVY_VERSION="4.73"
PROJECTIVY_URL="https://github.com/spocky/miproja1/releases/download/${PROJECTIVY_VERSION}/ProjectivyLauncher-${PROJECTIVY_VERSION}-c98-xda-release.apk"
PROJECTIVY_SHA256="74e33af1e5e13831a69a0669d2b68b02150bf9df1ae1df437dc67e3f8d52c790"
PROJECTIVY_PKG="com.spocky.projengmenu"
PROJECTIVY_HOME="${PROJECTIVY_PKG}/com.spocky.projengmenu.ui.home.MainActivity"

FLauncher_URL="https://github.com/osrosal/flauncher/releases/download/v2025.07.001/flauncher-armeabi-v7a-release.apk"
FLauncher_PKG="me.efesser.flauncher"
FLauncher_HOME="${FLauncher_PKG}/me.efesser.flauncher.MainActivity"

# LOW_RAM=1 → FLauncher + no Aerial Views (better for 1GB TVs like generic SMART_TV)
LOW_RAM="${LOW_RAM:-0}"
LAUNCHER="${LAUNCHER:-projectivy}"

AERIAL_VERSION="1.8.5"
AERIAL_URL="https://github.com/theothernt/AerialViews/releases/download/${AERIAL_VERSION}/aerial-views-${AERIAL_VERSION}.apk"
AERIAL_PKG="com.neilturner.aerialviews"
AERIAL_DREAM="${AERIAL_PKG}/com.neilturner.aerialviews.ui.screensaver.DreamActivity"

ADB_PORT="${ADB_PORT:-5555}"
DISABLE_OLD_LAUNCHER="${DISABLE_OLD_LAUNCHER:-1}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${CYAN}→${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $(basename "$0") <TV_IP_ADDRESS> [--no-disable-old-launcher]

Example:
  $(basename "$0") 192.168.1.42

Before running (on the TV, ~2 minutes):
  1. Settings → About → tap "Build" 7 times → Developer options ON
  2. Developer options → USB debugging ON
  3. Developer options → Network debugging / Wireless debugging ON (if shown)
  4. Settings → Network → note the TV's Wi‑Fi IP address

Optional env:
  ADB_PORT=5555              ADB wireless port (default 5555)
  DISABLE_OLD_LAUNCHER=0     Keep the stock launcher enabled
EOF
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

download_apk() {
  local url="$1" dest="$2" expected_sha="${3:-}"
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$dest" ]]; then
    if [[ -n "$expected_sha" ]]; then
      local got
      got="$(sha256_file "$dest")"
      if [[ "$got" == "$expected_sha" ]]; then
        ok "Using cached $(basename "$dest")"
        return 0
      fi
      warn "Cached $(basename "$dest") checksum mismatch; re-downloading"
    else
      ok "Using cached $(basename "$dest")"
      return 0
    fi
  fi
  info "Downloading $(basename "$dest") ..."
  curl -fsSL -o "$dest" "$url"
  if [[ -n "$expected_sha" ]]; then
    local got
    got="$(sha256_file "$dest")"
    [[ "$got" == "$expected_sha" ]] || fail "Checksum failed for $(basename "$dest")"
  fi
  ok "Downloaded $(basename "$dest")"
}

ensure_adb() {
  if command -v adb >/dev/null 2>&1; then
    ADB=(adb)
    return 0
  fi
  if [[ -x "${TOOLS_DIR}/adb" ]]; then
    ADB=("${TOOLS_DIR}/adb")
    return 0
  fi

  info "Installing Android platform-tools locally (one-time) ..."
  mkdir -p "$TOOLS_DIR"
  local zip="/tmp/platform-tools.zip"
  local url="https://dl.google.com/android/repository/platform-tools-latest-linux.zip"
  case "$(uname -s)" in
    Darwin) url="https://dl.google.com/android/repository/platform-tools-latest-darwin.zip" ;;
    MINGW*|MSYS*|CYGWIN*) url="https://dl.google.com/android/repository/platform-tools-latest-windows.zip" ;;
  esac
  curl -fsSL -o "$zip" "$url"
  unzip -qo "$zip" -d /tmp
  rm -rf "$TOOLS_DIR"
  mv /tmp/platform-tools "$TOOLS_DIR"
  rm -f "$zip"
  ADB=("${TOOLS_DIR}/adb")
  ok "platform-tools ready at ${TOOLS_DIR}"
}

adb_shell() {
  "${ADB[@]}" shell "$@"
}

connect_tv() {
  local ip="$1"
  info "Connecting to ${ip}:${ADB_PORT} ..."
  "${ADB[@]}" disconnect "${ip}:${ADB_PORT}" >/dev/null 2>&1 || true
  if ! "${ADB[@]}" connect "${ip}:${ADB_PORT}"; then
    fail "Could not connect. Enable Network debugging on the TV and confirm the IP."
  fi
  sleep 1
  local state
  state="$("${ADB[@]}" devices | awk -v ip="${ip}:${ADB_PORT}" '$1==ip {print $2}')"
  [[ "$state" == "device" ]] || fail "ADB state is '${state:-offline}'. Accept the debugging prompt on the TV if one appears."
  ok "Connected to TV"
}

save_backup() {
  mkdir -p "$BACKUP_DIR"
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  local out="${BACKUP_DIR}/tv-${stamp}.txt"
  {
    echo "# TV backup ${stamp}"
    adb_shell getprop ro.product.manufacturer
    adb_shell getprop ro.product.model
    adb_shell getprop ro.build.version.release
    echo "--- default launcher ---"
    adb_shell cmd package resolve-activity --brief android.intent.category.HOME android.intent.action.MAIN 2>/dev/null || true
    echo "--- packages (truncated) ---"
    adb_shell pm list packages -3 2>/dev/null || true
  } >"$out" 2>&1 || true
  ok "Saved backup info to ${out}"
}

pick_launcher() {
  if [[ "$LOW_RAM" == "1" ]]; then
    LAUNCHER="flauncher"
    warn "LOW_RAM=1: using FLauncher (recommended for 1GB SMART_TV boxes)"
  fi
  case "$LAUNCHER" in
    projectivy)
      LAUNCHER_PKG="$PROJECTIVY_PKG"
      LAUNCHER_HOME="$PROJECTIVY_HOME"
      LAUNCHER_LABEL="Projectivy"
      ;;
    flauncher)
      LAUNCHER_PKG="$FLauncher_PKG"
      LAUNCHER_HOME="$FLauncher_HOME"
      LAUNCHER_LABEL="FLauncher"
      ;;
    *) fail "Unknown LAUNCHER=$LAUNCHER (use projectivy or flauncher)" ;;
  esac
}

install_apks() {
  pick_launcher
  if [[ "$LAUNCHER" == "projectivy" ]]; then
    local projectivy_apk="${APK_DIR}/ProjectivyLauncher.apk"
    download_apk "$PROJECTIVY_URL" "$projectivy_apk" "$PROJECTIVY_SHA256"
    info "Installing Projectivy Launcher ..."
    "${ADB[@]}" install -r "$projectivy_apk" | tail -1
    ok "Projectivy installed"
  else
    local fl_apk="${APK_DIR}/flauncher.apk"
    download_apk "$FLauncher_URL" "$fl_apk"
    info "Installing FLauncher (lightweight home screen) ..."
    "${ADB[@]}" install -r "$fl_apk" | tail -1
    ok "FLauncher installed"
  fi

  if [[ "$LOW_RAM" != "1" ]]; then
    local aerial_apk="${APK_DIR}/aerial-views.apk"
    download_apk "$AERIAL_URL" "$aerial_apk"
    info "Installing Aerial Views (screensaver) ..."
    "${ADB[@]}" install -r "$aerial_apk" | tail -1
    ok "Aerial Views installed"
  else
    warn "Skipping Aerial Views on LOW_RAM=1 (saves RAM on 1GB TVs)"
  fi
}

set_launcher_default() {
  info "Setting ${LAUNCHER_LABEL} as default Home ..."
  adb_shell cmd package set-home-activity --user 0 "$LAUNCHER_HOME" \
    || adb_shell cmd package set-home-activity "$LAUNCHER_HOME" \
    || fail "Could not set default launcher (TV may block custom Home apps)"

  adb_shell appops set "$LAUNCHER_PKG" APP_AUTO_START allow 2>/dev/null || true
  adb_shell appops set "$LAUNCHER_PKG" AUTO_START allow 2>/dev/null || true
  adb_shell dumpsys deviceidle whitelist "+${LAUNCHER_PKG}" 2>/dev/null || true

  ok "${LAUNCHER_LABEL} set as default Home (reboot TV if Home still opens the old UI)"
}

disable_stock_launcher() {
  [[ "$DISABLE_OLD_LAUNCHER" == "1" ]] || return 0

  local resolved
  resolved="$(adb_shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME 2>/dev/null | tail -1 | tr -d '\r')"
  local old_pkg="${resolved%%/*}"

  if [[ -z "$old_pkg" || "$old_pkg" == "$LAUNCHER_PKG" || "$old_pkg" == *"No activity"* ]]; then
    info "Stock launcher already replaced or not detected"
    return 0
  fi

  # Never disable core Android / Google TV system packages blindly
  case "$old_pkg" in
    com.android.settings|com.android.systemui|com.google.android.gms)
      warn "Skipping disable for protected package: $old_pkg"
      return 0
      ;;
  esac

  info "Disabling previous home app: ${old_pkg} (reversible with pm enable) ..."
  if adb_shell pm disable-user --user 0 "$old_pkg" 2>/dev/null; then
    ok "Disabled ${old_pkg}"
    echo "$old_pkg" >>"${BACKUP_DIR}/disabled-packages.txt"
  else
    warn "Could not disable ${old_pkg} — use Projectivy accessibility override in its settings"
  fi
}

configure_screensaver() {
  [[ "$LOW_RAM" != "1" ]] || return 0
  info "Setting Aerial Views as screensaver ..."
  adb_shell settings put secure screensaver_enabled 1 2>/dev/null || true
  adb_shell settings put secure screensaver_components "$AERIAL_DREAM" 2>/dev/null || true
  adb_shell settings put secure screensaver_timeout 600000 2>/dev/null || true
  ok "Screensaver configured (10 min idle; adjust in Aerial Views settings on TV)"
}

launch_projectivy() {
  adb_shell am start -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null 2>&1 || true
}

print_tv_finish_steps() {
  cat <<EOF

${GREEN}════════════════════════════════════════════════════════════${NC}
${GREEN}  On the TV remote — finish these for the best look:${NC}
${GREEN}════════════════════════════════════════════════════════════${NC}

  1. Press ${CYAN}Home${NC} → ${LAUNCHER_LABEL} should open.
  2. Launcher settings:
     • Hide / reorder apps you do not use
     • Set a wallpaper (FLauncher: pick image from USB or file app)
  3. If Home still shows the old UI → reboot once; on Projectivy enable ${CYAN}Accessibility${NC} if offered
  4. If you installed Aerial Views → open it once and pick video sources

${YELLOW}Undo old launcher disable:${NC}
  adb shell pm enable com.example.oldlauncher

EOF
}

main() {
  local tv_ip=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      --no-disable-old-launcher) DISABLE_OLD_LAUNCHER=0; shift ;;
      *) tv_ip="$1"; shift ;;
    esac
  done

  [[ -n "$tv_ip" ]] || { usage; exit 1; }

  echo ""
  info "TV beautify installer (Projectivy + Aerial Views)"
  echo ""

  ensure_adb
  connect_tv "$tv_ip"
  save_backup
  install_apks
  set_launcher_default
  disable_stock_launcher
  configure_screensaver
  launch_projectivy
  print_tv_finish_steps
  ok "Done."
}

main "$@"
