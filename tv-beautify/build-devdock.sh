#!/usr/bin/env bash
# Build DevDock custom launcher APK (requires Java + Android SDK once).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${SCRIPT_DIR}/devdock-launcher"
SDK_ROOT="${ANDROID_HOME:-${SCRIPT_DIR}/.android-sdk}"
APK_OUT="${SCRIPT_DIR}/apks/DevDock-launcher.apk"

export ANDROID_HOME="$SDK_ROOT"
export PATH="$SDK_ROOT/cmdline-tools/latest/bin:$SDK_ROOT/platform-tools:$PATH"

if [[ ! -f "${PROJECT}/app/build.gradle.kts" ]]; then
  echo "→ devdock-launcher/ missing — fetching source ..."
  "${SCRIPT_DIR}/fetch-devdock-source.sh"
fi

ensure_sdk() {
  if [[ -x "$SDK_ROOT/platform-tools/adb" ]] && [[ -d "$SDK_ROOT/platforms/android-35" ]]; then
    return 0
  fi
  echo "→ Installing Android SDK (one-time, ~400MB) ..."
  mkdir -p "$SDK_ROOT/cmdline-tools"
  local zip="/tmp/cmdline-tools.zip"
  curl -fsSL -o "$zip" "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
  rm -rf "$SDK_ROOT/cmdline-tools/latest"
  unzip -qo "$zip" -d "$SDK_ROOT/cmdline-tools"
  mv "$SDK_ROOT/cmdline-tools/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest"
  sdkmanager --sdk_root="$SDK_ROOT" \
    "platform-tools" "platforms;android-35" "build-tools;35.0.0" <<< "y" >/dev/null
}

cd "$PROJECT"
if [[ ! -x ./gradlew ]]; then
  echo "✗ gradlew missing — re-run fetch-devdock-source.sh" >&2
  exit 1
fi

ensure_sdk
./gradlew assembleRelease -q
mkdir -p "$(dirname "$APK_OUT")"
cp -f app/build/outputs/apk/release/app-release-unsigned.apk "$APK_OUT" 2>/dev/null \
  || cp -f app/build/outputs/apk/release/app-release.apk "$APK_OUT"
echo "✓ Built $APK_OUT"
