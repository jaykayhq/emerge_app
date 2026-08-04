#!/usr/bin/env python3
"""Strip optional deobfuscation metadata from a release AAB and re-sign it.

Removes from the signed AAB:
  - BUNDLE-METADATA/com.android.tools.build.debugsymbols/** (native/Dart
    debug symbols; Play Console deobfuscation only, counts against the upload cap)
  - BUNDLE-METADATA/com.android.tools.build.obfuscation/** (R8 proguard.map)

ABI control is the build's job (see build.gradle.kts release packaging
excludes + `--target-platform android-arm64`): post-hoc ABI removal breaks
bundletool's ABI-targeting validation.

Rewriting the zip invalidates the APK v2/v3 signature, so the bundle is
re-signed with apksigner using the release keystore from android/key.properties.

Usage:
  python scripts/strip_aab.py [path/to/app-release.aab]

Idempotent: an already-stripped bundle is a no-op. The original is preserved
as <aab>.orig.
"""

import os
import shutil
import subprocess
import sys
import zipfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_PROPERTIES = os.path.join(REPO, "android", "key.properties")
DEFAULT_AAB = os.path.join(
    REPO, "build", "app", "outputs", "bundle", "release", "app-release.aab"
)
STRIP_PREFIXES = (
    "BUNDLE-METADATA/com.android.tools.build.debugsymbols/",
    "BUNDLE-METADATA/com.android.tools.build.obfuscation/",
)


def _android_sdk():
    sdk = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if sdk:
        return sdk
    props = os.path.join(REPO, "android", "local.properties")
    if os.path.exists(props):
        for line in open(props, encoding="utf-8"):
            if line.startswith("sdk.dir="):
                return line.split("=", 1)[1].strip().replace("\\", "/")
    raise SystemExit("Android SDK not found: set ANDROID_HOME or android/local.properties")


def _apksigner():
    build_tools = os.path.join(_android_sdk(), "build-tools")
    versions = sorted(v for v in os.listdir(build_tools) if v[0].isdigit())
    for version in reversed(versions):
        exe = "apksigner.bat" if os.name == "nt" else "apksigner"
        candidate = os.path.join(build_tools, version, exe)
        if os.path.exists(candidate):
            return candidate
    raise SystemExit(f"apksigner not found under {build_tools}")


def _key_properties():
    props = {}
    with open(KEY_PROPERTIES, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if "=" in line:
                k, v = line.split("=", 1)
                props[k.strip()] = v.strip()
    for required in ("storeFile", "storePassword", "keyAlias", "keyPassword"):
        if required not in props:
            raise SystemExit(f"android/key.properties missing '{required}'")
    # Gradle resolves storeFile relative to the app module (android/app).
    store = os.path.normpath(os.path.join(REPO, "android", "app", props["storeFile"]))
    if not os.path.exists(store):
        raise SystemExit(f"Keystore not found: {store}")
    return store, props


def strip(aab_path):
    original_size = os.path.getsize(aab_path)
    stripped = []
    out_path = aab_path + ".stripped"
    with zipfile.ZipFile(aab_path) as zin, \
         zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zout:
        for item in zin.infolist():
            if any(item.filename.startswith(p) for p in STRIP_PREFIXES):
                stripped.append(item)
                continue
            zout.writestr(item, zin.read(item.filename))

    if not stripped:
        os.remove(out_path)
        print("No BUNDLE-METADATA deobfuscation entries to strip (already clean).")
        return False

    total = sum(i.file_size for i in stripped)
    print(f"Removed {len(stripped)} metadata entries ({total/1e6:.1f}MB uncompressed):")
    for item in stripped:
        print(f"  - {item.filename}")
    print(f"Rezip: {original_size/1e6:.1f}MB -> {os.path.getsize(out_path)/1e6:.1f}MB")
    return out_path


def resign(apksigner, unsigned, destination):
    store, props = _key_properties()
    cmd = [
        apksigner, "sign",
        "--min-sdk-version", "26",  # AAB manifests are proto XML; apksigner can't parse them
        "--ks", store,
        "--ks-key-alias", props["keyAlias"],
        "--ks-pass", f"pass:{props['storePassword']}",
        "--key-pass", f"pass:{props['keyPassword']}",
        "--out", destination,
        unsigned,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise SystemExit(f"apksigner failed:\n{result.stdout}\n{result.stderr}")


def _bundletool():
    """Locate bundletool: env BUNDLETOOL, PATH, or build/bundletool.jar."""
    env = os.environ.get("BUNDLETOOL")
    if env and os.path.exists(env):
        return env
    in_path = shutil.which("bundletool")
    if in_path:
        return in_path
    local = os.path.join(REPO, "build", "bundletool.jar")
    return local if os.path.exists(local) else None


def validate(destination):
    """Canonical AAB check. apksigner cannot verify AABs (proto manifest)."""
    bt = _bundletool()
    if bt is None:
        print("WARNING: bundletool not found — skipped structural validation. "
              "Install it (build/bundletool.jar) for full AAB validation.")
        return
    result = subprocess.run(
        ["java", "-jar", bt, "validate", "--bundle", destination],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise SystemExit(f"bundletool validate failed:\n{result.stdout}\n{result.stderr}")
    print("bundletool validate: OK")


def main():
    if "--help" in sys.argv:
        print(__doc__)
        return 0
    aab = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_AAB
    if not os.path.exists(aab):
        raise SystemExit(f"AAB not found: {aab}")

    original_size = os.path.getsize(aab)
    out_path = strip(aab)
    if not out_path:
        return 0

    backup = aab + ".orig"
    os.replace(aab, backup)
    try:
        resign(_apksigner(), out_path, aab)
        os.remove(out_path)
        validate(aab)
    except SystemExit:
        os.replace(backup, aab)  # restore on failure
        raise
    new_size = os.path.getsize(aab)
    os.remove(backup)
    print(f"Stripped + re-signed: {aab}")
    print(f"Size: {original_size/1e6:.1f}MB -> {new_size/1e6:.1f}MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
