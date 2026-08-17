#!/usr/bin/env bash
#
# Prepare the Flutter web build (build/web/) so the STATIC LANDING PAGE is
# served at the site root. Runs AFTER `flutter build web --release` (which
# wipes build/web) and BEFORE `firebase deploy`.
#
# Why this rename: Firebase Hosting serves static files over rewrites, and
# Flutter always emits index.html — so `/` can only show the landing if the
# landing IS index.html. The app entry moves to app.html and firebase.json
# catches every other path with a rewrite to /app.html (the app's own
# router + decideRedirect handle auth from there, unchanged).
#
# Usage: bash scripts/build_landing.sh [dest_dir]   (default: build/web)
set -euo pipefail

DEST="${1:-build/web}"

if [[ ! -f "$DEST/index.html" ]]; then
  echo "!! $DEST/index.html not found — run `flutter build web` first." >&2
  exit 1
fi
if [[ ! -f web-landing/landing.html ]]; then
  echo "!! web-landing/landing.html not found — run from the repo root." >&2
  exit 1
fi

mv -f "$DEST/index.html" "$DEST/app.html"
cp web-landing/landing.html "$DEST/index.html"
cp web-landing/styles.css "$DEST/styles.css"
cp web-landing/script.js "$DEST/script.js"

echo "Landing page staged at $DEST/index.html; Flutter entry moved to $DEST/app.html:"
ls -la "$DEST"/index.html "$DEST"/app.html "$DEST"/styles.css "$DEST"/script.js