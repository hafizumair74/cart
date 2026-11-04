#!/usr/bin/env bash
# Wisdom Share / CVTE SMART_TV: fix Home → Projectivy WITHOUT disabling stock launcher.
# WARNING: Do NOT run pm disable on com.cvte.tv.launcher.space — can soft-brick boot.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="${SCRIPT_DIR}/platform-tools"
BACKUP_DIR="${SCRIPT_DIR}/.backup"
ADB_PORT="${ADB_PORT:-5555}"

PROJECTIVY_PKG="com.spocky.projengmenu"
PROJECTIVY_HOME="${PROJECTIVY_PKG}/com.spocky.projengmenu.ui.home.MainActivity"
PROJECTIVY_A11Y="${PROJECTIVY_PKG}/com.spocky.projengmenu.services.ProjectivyAccessibilityService"

# Never disable these on Wisdom Share TVs (boot / Home depend on them)
PROTECTED_PKGS="com.cvte.tv.launcher.space com.android.systemui com.android.settings"

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

[[ $# -ge 1 ]] || { echo "Usage: $0 TV_IP"; exit 1; }
TV_IP="$1"

if [[ -x "${TOOLS_DIR}/adb" ]]; then
  ADB=("${TOOLS_DIR}/adb")
elif command -v adb >/dev/null 2>&1; then
  ADB=(adb)
else
  fail "ADB not found."
fi

adb_shell() { "${ADB[@]}" shell "$@"; }

"${ADB[@]}" disconnect "${TV_IP}:${ADB_PORT}" >/dev/null 2>&1 || true
"${ADB[@]}" connect "${TV_IP}:${ADB_PORT}" >/dev/null
state="$("${ADB[@]}" devices | awk -v ip="${TV_IP}:${ADB_PORT}" '$1==ip {print $2}')"
[[ "$state" == "device" ]] || fail "TV not connected."

ok "Connected to ${TV_IP}"
mkdir -p "$BACKUP_DIR"

info "TV launcher packages (Wisdom Share / CVTE) ..."
adb_shell pm list packages 2>/dev/null | grep -iE 'cvte|wisdom|launcher|projeng' | tr -d '\r' | tee "${BACKUP_DIR}/launcher-packages.txt" || true

info "Re-enabling any disabled launcher (safe recovery) ..."
if [[ -f "${BACKUP_DIR}/disabled-packages.txt" ]]; then
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    adb_shell pm enable --user 0 "$pkg" 2>/dev/null || true
  done <"${BACKUP_DIR}/disabled-packages.txt"
fi
for pkg in com.cvte.tv.launcher.space com.spocky.projengmenu me.efesser.flauncher; do
  adb_shell pm enable --user 0 "$pkg" 2>/dev/null || true
done
ok "Launchers enabled"

info "Projectivy as default Home activity ..."
adb_shell cmd package set-home-activity --user 0 "$PROJECTIVY_HOME" 2>/dev/null \
  || adb_shell cmd package set-home-activity "$PROJECTIVY_HOME" 2>/dev/null || true

adb_shell appops set "$PROJECTIVY_PKG" APP_AUTO_START allow 2>/dev/null || true
adb_shell appops set "$PROJECTIVY_PKG" AUTO_START allow 2>/dev/null || true
adb_shell dumpsys deviceidle whitelist "+${PROJECTIVY_PKG}" 2>/dev/null || true

info "Enabling Projectivy Accessibility (overrides Wisdom Share Home) ..."
# Merge with any existing accessibility services
existing="$(adb_shell settings get secure enabled_accessibility_services 2>/dev/null | tr -d '\r' || true)"
if [[ "$existing" == "null" || -z "$existing" ]]; then
  adb_shell settings put secure enabled_accessibility_services "$PROJECTIVY_A11Y" 2>/dev/null || true
else
  if [[ "$existing" != *"$PROJECTIVY_PKG"* ]]; then
    adb_shell settings put secure enabled_accessibility_services "${existing}:${PROJECTIVY_A11Y}" 2>/dev/null || true
  fi
fi
adb_shell settings put secure accessibility_enabled 1 2>/dev/null || true
ok "Accessibility request sent (confirm on TV if a popup appears)"

info "Opening Projectivy ..."
adb_shell am start -n "${PROJECTIVY_HOME}" 2>/dev/null || adb_shell am start -a android.intent.action.MAIN -c android.intent.category.HOME 2>/dev/null || true

echo ""
info "Boot animation (WISDOM SHARE video at power-on) ..."
bootpath="$(adb_shell getprop ro.third.bootanimation.path_two 2>/dev/null | tr -d '\r' || true)"
[[ -n "$bootpath" && "$bootpath" != "" ]] && echo "    Boot zip path: $bootpath"
warn "Replacing boot video needs ROOT or a factory hidden menu — ADB alone usually cannot remove it."
echo "    Try on remote: Settings → (About) → Menu key 1147 → look for Boot logo / Boot video OFF"
echo "    Without root: only workaround is faster HDMI input or living with ~5–10s splash."

echo ""
echo -e "${BOLD}${GREEN}On the TV remote — required once:${NC}"
echo "  1. If asked → allow ${BOLD}Projectivy Accessibility${NC}."
echo "  2. Projectivy → Settings → confirm ${BOLD}Override / Accessibility${NC} is ON."
echo "  3. Wallpaper → /sdcard/Download/DevTV/wall-code-dark.jpg (run developer-tv.sh if missing)."
echo "  4. Press ${BOLD}Home${NC} — should open Projectivy, not Wisdom Share grid."
echo ""
warn "Never disable com.cvte.tv.launcher.space — Wisdom TVs can get stuck on the boot logo."
echo ""
