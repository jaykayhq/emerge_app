#!/usr/bin/env bash
#
# Copy the static landing page (web-landing/) into the Flutter web build
# (build/web/). Runs AFTER `flutter build web --release` (which wipes
# build/web) and BEFORE `firebase deploy`, so the landing is never clobbered.
#
# Usage: bash scripts/build_landing.sh [dest_dir]   (default: build/web)
set -euo pipefail

DEST="${1:-build/web}"

if [[ ! -f web-landing/landing.html ]]; then
  echo "!! web-landing/landing.html not found — run from the repo root." >&2
  exit 1
fi

mkdir -p "$DEST"
cp web-landing/landing.html "$DEST/landing.html"
cp web-landing/styles.css "$DEST/styles.css"
cp web-landing/script.js "$DEST/script.js"

echo "Landing page copied to $DEST:"
ls -la "$DEST"/landing.html "$DEST"/styles.css "$DEST"/script.js