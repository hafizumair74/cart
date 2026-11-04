#!/usr/bin/env bash
# Best UI + speed for Wisdom Share / CVTE Android 12 (1GB): debloat + CleanYourTV launcher.
# Requires: ~/cleanyourtv cloned, TV at TV_HOST with USB debugging on.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEAN="${CLEANYOURTV_DIR:-$HOME/cleanyourtv}"
TV_HOST="${TV_HOST:-192.168.0.103}"
ADB_PORT="${ADB_PORT:-5555}"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${CYAN}→${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
die() { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

# --- ADB (your tv-beautify install, or system) ---
ensure_adb() {
  if [[ -x "${SCRIPT_DIR}/platform-tools/adb" ]]; then
    export PATH="${SCRIPT_DIR}/platform-tools:$PATH"
  fi
  command -v adb >/dev/null 2>&1 || die "ADB missing. Run ~/tv-beautify/install-devdock.sh once (installs platform-tools) or: sudo apt install adb"
  adb connect "${TV_HOST}:${ADB_PORT}" >/dev/null 2>&1 || true
  state="$(adb devices | awk -v ip="${TV_HOST}:${ADB_PORT}" '$1==ip {print $2}')"
  [[ "$state" == "device" ]] || die "TV not connected at ${TV_HOST}:${ADB_PORT} — enable USB debugging and Allow on TV"
  ok "ADB connected to ${TV_HOST}"
}

# --- CleanYourTV Python tools ---
ensure_cleanyourtv() {
  [[ -d "$CLEAN/tools" ]] || die "Clone CleanYourTV first: git clone --depth 1 https://github.com/Gathin23/cleanyourtv.git $CLEAN"
  local PY="$CLEAN/tools/venv/bin/python"
  if [[ ! -x "$PY" ]]; then
    info "CleanYourTV Python venv (one-time) ..."
    python3 -m venv "$CLEAN/tools/venv"
    "$CLEAN/tools/venv/bin/pip" install -q -r "$CLEAN/tools/requirements.txt"
  fi
  ok "CleanYourTV tools ready"
}

# --- JDK + ANDROID_HOME for launcher build ---
ensure_java_sdk() {
  if ! command -v java >/dev/null 2>&1; then
    warn "Install JDK 17: sudo apt install -y openjdk-17-jdk"
    die "Java required to build CleanYourTV launcher"
  fi
  export JAVA_HOME="${JAVA_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")}"
  export ANDROID_HOME="${ANDROID_HOME:-${SCRIPT_DIR}/.android-sdk}"
  if [[ ! -d "$ANDROID_HOME/platforms" ]]; then
    info "Android SDK for launcher build (reuses tv-beautify SDK if present) ..."
    "${SCRIPT_DIR}/build-devdock.sh" >/dev/null 2>&1 || true
  fi
  export PATH="${JAVA_HOME}/bin:$PATH"
}

run_debloat() {
  local list="$CLEAN/examples/sankey-smart-tv-hi3751v350/debloat.txt"
  [[ -f "$list" ]] || die "Missing $list"
  info "Debloat (ads, cleaner, pictorial — stock launcher NOT disabled) ..."
  ( cd "$CLEAN" && TV_HOST="$TV_HOST" tools/disable.sh "$list" )
  ok "Debloat applied (undo: TV_HOST=$TV_HOST $CLEAN/tools/restore.sh $list)"
}

install_cleanyourtv_launcher() {
  info "Building & installing CleanYourTV launcher (Apple TV style) ..."
  # CVTE Wisdom Share: NEVER disable com.cvte.tv.launcher.space (boot brick risk)
  (
    cd "$CLEAN/launcher"
    export TV_HOST
    export ANDROID_HOME
    export JAVA_HOME
    export STOCK_LAUNCHER=none
    export INPUT_KEY_SERVICE=1
    ./build-and-install.sh
  )
  ok "CleanYourTV launcher installed — press Home on remote"
}

main() {
  echo ""
  info "Best UI + faster TV (CleanYourTV + CVTE-safe)"
  echo ""
  ensure_adb
  ensure_cleanyourtv
  ensure_java_sdk
  run_debloat
  install_cleanyourtv_launcher
  echo ""
  warn "In launcher: pick theme, dock apps (YouTube, Netflix, VLC…), wallpaper."
  warn "Boot WISDOM video: unchanged (factory menu 1147 if your set has boot logo off)."
  echo ""
}

main "$@"
