# Android Release Runbook

How to publish an Emerge update to Google Play from the terminal.

## The pipeline (normal release)

```bash
# 1. Bump the version (see below) BEFORE building
# 2. Build the release bundle (arm64-only — see "Why arm64-only")
flutter build appbundle --release --target-platform android-arm64

# 3. Strip optional deobfuscation metadata + re-sign (see "Why strip")
python scripts/strip_aab.py

# 4. Publish
node scripts/play_deploy.mjs --track internal --notes "What's new"
```

| Flag | Meaning |
|---|---|
| `--track` | `internal` (default, no review) · `alpha` · `beta` · `production` |
| `--status` | `completed` (default) · `draft` · `inProgress` |
| `--notes` | Release notes shown in Play; defaults to the pubspec version |
| `--countries` | e.g. `US,NG,GB` to restrict availability; defaults to all countries |
| `--key` | service account JSON; defaults to `scripts/service-account-key.json` |
| `--aab` | bundle path; defaults to `build/app/outputs/bundle/release/app-release.aab` |

`internal`/`alpha`/`beta` go live immediately. `production` goes to review (see "First production release" — the very first one must be done in the console).

## Version bump — update ALL of these

The version lives in 4 places; they must stay in sync:

| File | Field |
|---|---|
| `pubspec.yaml` | `version: 1.0.6+11` (user version + build number/versionCode) |
| `lib/core/services/web_update_service.dart` | `kAppVersion` constant |
| `lib/features/settings/presentation/screens/settings_screen.dart` | settings "Version ..." label |
| `web/version.json` | `"version": "..."` (web update check manifest) |

**versionCode rules (Play enforces hard):**
- versionCode = the number after `+`; must be **higher than every versionCode ever uploaded**, across all tracks.
- If the API rejects with *"Version code N has already been used"*, bump the build number (e.g. `1.0.6+11` → `1.0.6+12`) and rebuild.
- iOS/`CFBundleVersion` derives from the same pubspec values (`$(FLUTTER_BUILD_NUMBER)`), no manual edit.

## Prerequisites (done once — how it was set up)

- **Play Developer account** with production access (console.play.google.com)
- **App entry** `com.emerge.emerge_app` created in the console (the API cannot create apps)
- **Upload key registered** — Play App Signing uses `android/app/emerge-release.jks` (alias `emerge`); registered via PEPK in *Setup → App signing*
- **API access**: Android Publisher API enabled on the GCP project (`tradeflash-l2966`), service account `play-publisher@tradeflash-l2966.iam.gserviceaccount.com` granted **Release manager** in *Settings → API access* (the avatar menu, not a gear), JSON key at `scripts/service-account-key.json` (gitignored)
- **gcloud** (if re-creating the service account):
  ```bash
  gcloud services enable androidpublisher.googleapis.com --project=tradeflash-l2966
  gcloud iam service-accounts create play-publisher --display-name="Play Publisher" --project=tradeflash-l2966
  gcloud iam service-accounts keys create scripts/service-account-key.json \
    --iam-account=play-publisher@tradeflash-l2966.iam.gserviceaccount.com
  ```
  The Play Console access grant cannot be done via gcloud — it's a 2-minute browser step.

## Why arm64-only

Release bundles ship only `arm64-v8a`:
- `--target-platform android-arm64` tells the Flutter Gradle plugin to restrict its own libs.
- `android/app/build.gradle.kts` (release buildType) excludes stray `armeabi-v7a`/`x86_64` libs from third-party AARs (`packaging.jniLibs.excludes`) — without this, Play advertises ABIs the app can't run on (missing `libflutter.so` → crash at launch).
- Debug/profile builds keep all ABIs, so `flutter run` on emulators still works.
- Trade-off: release AABs won't install on 32-bit devices or x86_64 emulators — test on a physical device.

## Why strip_aab.py

The release AAB embeds ~97MB of native/Dart debug symbols plus a ~70MB R8 map under `BUNDLE-METADATA/`. They're console-side deobfuscation aids, not app payload, but they count against Play's **200MB upload cap** and inflate the upload.

`scripts/strip_aab.py` removes them, re-zips (deflate), **re-signs with apksigner** (`--min-sdk-version 26` — AAB manifests are proto XML, apksigner can't parse them), and validates with `bundletool validate` (`build/bundletool.jar`, downloaded from google/bundletool releases).

- Idempotent; original preserved as `<aab>.orig` on failure.
- `apksigner verify` **cannot** verify AABs (fails on any Gradle-signed bundle too) — bundletool is the gate.
- **Don't** strip ABIs from the zip post-build — bundletool rejects it ("Targeted directory ... is empty"); ABI control belongs in the build.

## Asset size optimization (when assets change)

`python scripts/optimize_assets.py` (Pillow) recompresses bundled images by usage evidence (dark overlays mask artifacts; small display sizes tolerate downscaling) and deletes zero-reference assets. `--dry-run` previews. NOTE: `generate_assets.js` (Pollinations) regenerates `assets/worlds` at full size — re-running it undoes compression. `app_icon.png`/`splash_logo_flame.png` are lossless-only (launcher/splash sources).

## First production release (API limitation — one-time console step)

The API **cannot** create the first production release. Its constraints are mutually exclusive:
- first release on a track cannot be staged (`inProgress`)
- a `completed` release must declare availability, but `countryTargeting` is only accepted on staged releases

So: console → **Release → Production → Create release** → drag `app-release.aab` → availability defaults to all countries/full rollout → notes → **Send for review**. Once the track has a release, the script's `--track production` path works (and staged rollouts become legal).

## Known Play API errors

| Error | Meaning / fix |
|---|---|
| `Version code N has already been used` | versionCode taken by another track — bump build number, rebuild |
| `Release in track targeting no countries` | first production release — use the console |
| `The first release on a track cannot be staged` | same as above |
| `Country targeting is only supported for staged releases` | don't put countryTargeting on completed releases |
| `IN_PROGRESS release must have fraction` | staged releases need `userFraction` (not exposed by this script) |
| 403 permission | service account lacks Release manager / API not enabled on the linked project |

## Troubleshooting

- **Upload hangs / "remote end hung up"**: transient transport issues on large pushes — retry; `git config http.postBuffer 524288000` fixed it once for the image-heavy push.
- **bundletool validate fails**: check the error — usually ABI/targeting mismatch (build-level fix, not zip surgery) or missing signature after manual zip edits (re-run `strip_aab.py`).
- **Play review blockers**: privacy policy URL, data safety form, content rating, target audience — complete the dashboard checklist before "Send for review".
- **Testing**: internal track = no review; share the internal test link; test on a physical device (arm64-only).
