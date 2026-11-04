#!/usr/bin/env bash
# List package names on the TV for apps you care about (for dock setup).
set -euo pipefail

TV_IP="${1:?Usage: $0 TV_IP}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="${SCRIPT_DIR}/platform-tools"
ADB_PORT="${ADB_PORT:-5555}"

if [[ -x "${TOOLS_DIR}/adb" ]]; then ADB=("${TOOLS_DIR}/adb")
else ADB=(adb); fi

"${ADB[@]}" connect "${TV_IP}:${ADB_PORT}" >/dev/null

echo "# Curated apps from your Wisdom Share screen — match labels on TV"
echo "# Use these package names in Vibe/Couchy dock (long-press → hide others)"
echo ""

search_label() {
  local label="$1"
  echo "## $label"
  "${ADB[@]}" shell pm list packages -3 2>/dev/null | cut -d: -f2 | tr -d '\r' | while read -r pkg; do
    local l
    l="$("${ADB[@]}" shell dumpsys package "$pkg" 2>/dev/null | awk -F= '/applicationInfo/{print; exit}' | head -1)" || true
  done
  # Broader grep on all packages
  "${ADB[@]}" shell pm list packages -f 2>/dev/null | tr -d '\r' | grep -iE "$2" | head -8 || echo "(not found — open app once on TV and re-run)"
  echo ""
}

# Keywords per tile on your home screen
search_label "YouTube" 'youtube'
search_label "Netflix" 'netflix'
search_label "Prime Video" 'primevideo|amazon'
search_label "Disney+" 'disney'
search_label "VLC" 'vlc'
search_label "AirScreen" 'airscreen|screen'
search_label "VPN" 'vpn'
search_label "Browser" 'browser'
search_label "App Store" 'vending|store|market'
search_label "Tamasha" 'tamasha'
search_label "Dunya" 'dunya'
search_label "Kindlink" 'kindlink|link'
search_label "Media / Files" 'media|files|higallery'

echo "--- All user-installed apps (-3) ---"
"${ADB[@]}" shell pm list packages -3 2>/dev/null | tr -d '\r'
