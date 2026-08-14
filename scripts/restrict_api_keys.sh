#!/usr/bin/env bash
#
# Restrict the Firebase client API keys so the GitHub secret-scanning alerts
# are neutered (keys become useless outside the app).
#
# IMPORTANT: run with YOUR OWN Google account (project owner), NOT the
# service account:
#     gcloud auth login
#     bash scripts/restrict_api_keys.sh
#
# The script first SHOWS the current key restrictions. Firebase-generated
# keys are often already restricted by the console — if so, stop and just
# dismiss the GitHub alerts.
#
# If you want to set API-target restrictions too (hardening), uncomment the
# API_TARGETS section below. Application restrictions alone already fix the
# secret-scanning exposure.
set -euo pipefail

PROJECT="${PROJECT:-tradeflash-l2966}"
DEBUG_SHA1="28:6B:40:B7:EF:85:26:F3:73:70:34:BB:15:1D:56:B7:39:25:2A:D2"
RELEASE_SHA1="${RELEASE_SHA1:-}"

ANDROID_PACKAGE="com.emerge.emerge_app"
IOS_BUNDLE_ID="com.emerge.emergeApp"
WEB_REFERRERS="https://tradeflash-l2966.web.app/*,https://emerge-404.web.app/*"

# Firebase services the app actually calls (for the optional api-targets).
API_TARGETS=(
  "identitytoolkit.googleapis.com"      # Auth
  "firebaseinstallations.googleapis.com" # FID
  "firebaseappcheck.googleapis.com"      # App Check
  "firebaseremoteconfig.googleapis.com"  # Remote Config
  "fcmregistrations.googleapis.com"      # FCM
  "firebasestorage.googleapis.com"       # Storage
)

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
  echo "Not logged in. Run:  gcloud auth login"
  exit 1
fi

echo "==> Enabling the API Keys API..."
gcloud services enable apikeys.googleapis.com --project "$PROJECT" -q

echo "==> Current keys and restrictions:"
gcloud services api-keys list --project "$PROJECT" --show-response

echo
echo "If the two keys already show Android/iOS/web restrictions above,"
echo "you are done — dismiss the alerts in GitHub and exit."
read -r -p "Apply restrictions now? (y/N) " ans
[[ "${ans:-n}" =~ ^[yY] ]] || { echo "Aborted — nothing changed."; exit 0; }

if [[ -z "$RELEASE_SHA1" ]]; then
  echo
  echo "RELEASE_SHA1 is not set. The Android restriction needs BOTH the debug"
  echo "and the release signing SHA-1 (restricting to debug only would break"
  echo "production builds' auth). Get the release SHA-1 from:"
  echo "  Play Console -> your app -> Release -> App signing"
  echo "  (or: keytool -list -v -keystore <release.jks> | grep 'SHA1:')"
  read -r -p "Release SHA-1 (format AA:BB:...): " RELEASE_SHA1
fi

KEY_ANDROID_WEB=""
KEY_IOS=""
while read -r name keyvalue; do
  case "$keyvalue" in
    AIzaSyAWlSsjpgQN4E_Bt3esMa1hIFJ9nESAEmA) KEY_ANDROID_WEB="$name" ;;
    AIzaSyAhbcUe2s1B-K_qd4w3fmyKef0AQhJtNAg) KEY_IOS="$name" ;;
  esac
done < <(gcloud services api-keys list --project "$PROJECT" --show-response \
  --format="value(name, restrictions.apiKeyValue)" 2>/dev/null)

# ---------- Android + Web key (shared) ----------
if [[ -n "$KEY_ANDROID_WEB" ]]; then
  echo "==> Restricting Android+Web key: $KEY_ANDROID_WEB"
  cmd=(gcloud services api-keys update "$KEY_ANDROID_WEB"
    --allowed-referrers="$WEB_REFERRERS")
  if [[ -n "$RELEASE_SHA1" ]]; then
    cmd+=(--allowed-application="sha1_fingerprint=$DEBUG_SHA1,package_name=$ANDROID_PACKAGE"
          --allowed-application="sha1_fingerprint=$RELEASE_SHA1,package_name=$ANDROID_PACKAGE")
  else
    echo "WARNING: skipping Android application restriction (release SHA-1 missing) —"
    echo "         web referrer restriction applied only."
  fi
  "${cmd[@]}"
else
  echo "!! Android+Web key not found — add it from the Firebase console if needed."
fi

# ---------- iOS key ----------
if [[ -n "$KEY_IOS" ]]; then
  echo "==> Restricting iOS key: $KEY_IOS"
  gcloud services api-keys update "$KEY_IOS" --allowed-bundle-ids="$IOS_BUNDLE_ID"
else
  echo "!! iOS key not found."
fi

# ---------- Optional: API-target restrictions (uncomment to enable) ----------
# for KEY in "$KEY_ANDROID_WEB" "$KEY_IOS"; do
#   [[ -n "$KEY" ]] || continue
#   args=()
#   for svc in "${API_TARGETS[@]}"; do
#     args+=(--api-target="service=$svc")
#   done
#   gcloud services api-keys update "$KEY" "${args[@]}"
# done

echo
echo "==> Final state:"
gcloud services api-keys list --project "$PROJECT" --show-response

echo
echo "Next: verify the app still works (Google sign-in / App Check on all"
echo "platforms), then dismiss the 3 alerts:"
echo "  GitHub -> Security -> Secret scanning -> resolve each alert."
