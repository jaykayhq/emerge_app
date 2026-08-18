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
# The script first SHOWS the current key NAMES and restrictions. Firebase-
# generated keys are often already restricted by the console — if so, stop
# and just dismiss the GitHub alerts.
#
# NOTE: this script never prints API-key VALUES (they would defeat the whole
# purpose by putting live secrets into CI logs). Keys are matched by their
# display name, not by value.
#
# If you want to set API-target restrictions too (hardening), uncomment the
# API_TARGETS section below. Application restrictions alone already fix the
# secret-scanning exposure.
set -euo pipefail

PROJECT="${PROJECT:-tradeflash-l2966}"
DEBUG_SHA1_UNCOLONED="286b40b7ef8526f3737034bb151d56b739252ad2"

ANDROID_PACKAGE="com.emerge.emerge_app"
IOS_BUNDLE_ID="com.emerge.emergeApp"

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

echo "==> Current keys and restrictions (values intentionally not printed):"
gcloud services api-keys list --project "$PROJECT"

echo
echo "If the two keys already show Android/iOS/web restrictions above,"
echo "you are done — dismiss the alerts in GitHub and exit."
read -r -p "Apply restrictions now? (y/N) " ans
[[ "${ans:-n}" =~ ^[yY] ]] || { echo "Aborted — nothing changed."; exit 0; }

if [[ -z "${RELEASE_SHA1:-}" ]]; then
  echo
  echo "RELEASE_SHA1 is not set. The Android restriction needs BOTH the debug"
  echo "and the release signing SHA-1 (restricting to debug only would break"
  echo "production builds' auth). Get the release SHA-1 from:"
  echo "  Play Console -> your app -> Release -> App signing"
  echo "  (or: keytool -list -v -keystore <release.jks> | grep 'SHA1:')"
  read -r -p "Release SHA-1 (format AA:BB:...): " RELEASE_SHA1
fi

# ---------- Android key ----------
# NOTE: web previously shared this key; a dedicated browser key was created
# (key ID b3783a74-…, value redacted here — see lib/firebase_options.dart web.apiKey)
# and lib/firebase_options.dart web.apiKey updated. Android-only here.
ANDROID_KEY=$(gcloud services api-keys list --project "$PROJECT" --format="value(name)" --filter="displayName='Android key (auto created by Firebase)'" 2>/dev/null | head -1)
if [[ -n "$ANDROID_KEY" ]]; then
  echo "==> Restricting Android key: $ANDROID_KEY"
  gcloud services api-keys update "$ANDROID_KEY" \
    --allowed-application="sha1_fingerprint=31ff52c2d39b492fe80c339e5c9c55e0625f59e7,package_name=$ANDROID_PACKAGE" \
    --allowed-application="sha1_fingerprint=06485267caa879f060ab52aa9303bc978f23d795,package_name=$ANDROID_PACKAGE" \
    --allowed-application="sha1_fingerprint=d7f5bc2e7c67114c76e7e05273d828e6d7abca61,package_name=$ANDROID_PACKAGE" \
    --allowed-application="sha1_fingerprint=41050fb3f292e1d83a64aaab84cb6b5e16b1d38e,package_name=$ANDROID_PACKAGE" \
    --allowed-application="sha1_fingerprint=386eb7a9d5a07b82921ecc480de03943206fe9ba,package_name=$ANDROID_PACKAGE" \
    --allowed-application="sha1_fingerprint=bc224b6631d2c1126936c0663bca407b9244813e,package_name=$ANDROID_PACKAGE" \
    --allowed-application="sha1_fingerprint=$DEBUG_SHA1_UNCOLONED,package_name=$ANDROID_PACKAGE" \
    --allowed-application="sha1_fingerprint=${RELEASE_SHA1//:/},package_name=$ANDROID_PACKAGE"
else
  echo "!! Android key not found."
fi

# ---------- iOS key ----------
# Looked up by display name (see the "Auto created by Firebase" keys listed
# above) — key values are never matched against or printed. Read the
# gcloud listing line-by-line: `--format="value(name, displayName)"` is
# tab-separated, and the display name contains spaces, so a plain `for
# entry in $(...)` would word-split each row and break the match.
KEY_IOS=""
while IFS=$'\t' read -r name displayname; do
  if [[ "$displayname" == *"iOS key"* ]]; then
    KEY_IOS="$name"
    break
  fi
done < <(gcloud services api-keys list --project "$PROJECT" \
  --format="value(name, displayName)" 2>/dev/null)
if [[ -n "$KEY_IOS" ]]; then
  echo "==> Restricting iOS key: $KEY_IOS"
  gcloud services api-keys update "$KEY_IOS" --allowed-bundle-ids="$IOS_BUNDLE_ID"
else
  echo "!! iOS key not found."
  exit 1
fi

# ---------- Optional: API-target restrictions (uncomment to enable) ----------
# for KEY in "$ANDROID_KEY" "$KEY_IOS"; do
#   [[ -n "$KEY" ]] || continue
#   args=()
#   for svc in "${API_TARGETS[@]}"; do
#     args+=(--api-target="service=$svc")
#   done
#   gcloud services api-keys update "$KEY" "${args[@]}"
# done

echo
echo "==> Final state (values intentionally not printed):"
gcloud services api-keys list --project "$PROJECT"

echo
echo "Next: verify the app still works (Google sign-in / App Check on all"
echo "platforms), then dismiss the 3 alerts:"
echo "  GitHub -> Security -> Secret scanning -> resolve each alert."
