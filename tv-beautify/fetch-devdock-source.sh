#!/usr/bin/env bash
# Download devdock-launcher/ when you only have scripts (no git clone).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${SCRIPT_DIR}/devdock-launcher"
BRANCH="cursor/tv-beautify-launcher-8673"
REPO="hafizumair74/cart"

if [[ -f "${DEST}/app/build.gradle.kts" && -f "${DEST}/gradlew" ]]; then
  echo "✓ devdock-launcher already present at ${DEST}"
  exit 0
fi

echo "→ Downloading DevDock source from GitHub (${BRANCH}) ..."
tmpdir="$(mktemp -d)"
archive="${tmpdir}/repo.tar.gz"
# codeload handles branch names with slashes
curl -fsSL -o "$archive" "https://codeload.github.com/${REPO}/tar.gz/refs/heads/${BRANCH//\//%2F}" \
  || curl -fsSL -o "$archive" "https://github.com/${REPO}/archive/refs/heads/cursor/tv-beautify-launcher-8673.tar.gz"

tar -xzf "$archive" -C "$tmpdir"
extracted="$(find "$tmpdir" -maxdepth 1 -type d -name 'cart-*' | head -1)"
[[ -d "$extracted/tv-beautify/devdock-launcher" ]] || {
  echo "✗ Could not find devdock-launcher in archive" >&2
  exit 1
}

rm -rf "$DEST"
mv "$extracted/tv-beautify/devdock-launcher" "$DEST"
rm -rf "$tmpdir"
echo "✓ Source ready: ${DEST}"
echo "  Run: ./build-devdock.sh && ./install-devdock.sh YOUR_TV_IP"
