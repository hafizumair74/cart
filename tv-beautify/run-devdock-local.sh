#!/usr/bin/env bash
# One-shot: fetch source, build DevDock, install on TV — run on YOUR laptop (same Wi‑Fi as TV).
set -euo pipefail
cd "$(dirname "$0")"
TV_IP="${1:-192.168.0.103}"

chmod +x fetch-devdock-source.sh build-devdock.sh install-devdock.sh 2>/dev/null || true
./fetch-devdock-source.sh
./build-devdock.sh
./install-devdock.sh "$TV_IP"
