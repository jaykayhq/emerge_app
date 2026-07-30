---
kind: dependency_management
name: Multi-Platform Dependency Management with Lockfiles and Centralized Versioning
category: dependency_management
scope:
    - '**'
source_files:
    - pubspec.yaml
    - pubspec.lock
    - functions/package.json
    - functions/package-lock.json
    - android/settings.gradle.kts
    - android/build.gradle.kts
    - android/app/build.gradle.kts
    - android/gradle.properties
    - package.json
---

This monorepo manages dependencies across three distinct ecosystems — Flutter/Dart, Node.js (Firebase Functions), and Android Gradle — each using its native package manager with lockfiles committed to version control for reproducible builds.

**Flutter/Dart (pub.dev)**
- Dependencies declared in `pubspec.yaml` under `dependencies` and `dev_dependencies` sections, using caret (`^`) version ranges for minor/patch updates while pinning major versions.
- `pubspec.lock` is committed to the repository, locking every transitive dependency to exact versions with SHA256 checksums from `https://pub.dev`, ensuring deterministic builds across environments.
- The package is marked `publish_to: 'none'`, indicating it is a private application not intended for publication to pub.dev.
- SDK constraint pinned to `^3.10.0` via the `environment` section.
- No custom pub.dev mirrors or private registries are configured; all packages resolve from the default hosted source.
- No `dependency_overrides` or `dependency_verification` blocks are present.

**Node.js (npm) — Firebase Functions**
- `functions/package.json` declares runtime dependencies (`firebase-admin`, `firebase-functions`, `axios`) and dev dependencies (TypeScript, Jest, ESLint).
- `functions/package-lock.json` is committed, locking the entire dependency tree with integrity hashes from `https://registry.npmjs.org`.
- Node engine explicitly pinned to `22` via the `engines` field.
- Root-level `package.json` contains only a single dependency (`source-map`); no root-level lockfile exists at the repo root.
- Scripts provide standard workflows: `build` (tsc), `test` (jest --coverage), `deploy` (firebase deploy --only functions), `serve` (emulators).

**Android (Gradle + Maven)**
- Build toolchain versions centralized in `android/settings.gradle.kts`: Android Gradle Plugin `8.11.1`, Kotlin `2.3.21`, Google Services `4.4.2`, Crashlytics `2.8.1`.
- Repository sources declared in both `settings.gradle.kts` and `build.gradle.kts` as `google()`, `mavenCentral()`, and `gradlePluginPortal()` — no private Maven repositories configured.
- `android/app/build.gradle.kts` pins compile/target Java/Kotlin to version 17, NDK to `28.2.13676358`, and minSdk to 26.
- Signing configuration loaded from `key.properties` (not committed), used by both debug and release build types.
- ProGuard/R8 rules applied in release builds via `proguard-rules.pro`.
- `android/gradle.properties` configures JVM args, parallelism, and Kotlin compiler settings but does not declare any dependency versions.

**iOS**
- iOS dependencies are managed through CocoaPods/Xcode project files (`.pbxproj`) referenced by the Flutter toolchain; no separate `Podfile` is visible in the tree.
- AdMob identifier and SKAdNetwork items are declared directly in `ios/Runner/Info.plist`.

**Conventions observed**
- Each language ecosystem uses its canonical lockfile (`pubspec.lock`, `package-lock.json`) committed alongside manifests for reproducibility.
- Version ranges use caret notation (`^`) in manifests, allowing automatic minor/patch upgrades while preserving major-version boundaries.
- Private/internal packages are kept unpublished (`publish_to: 'none'`) rather than pushed to a private registry.
- Native platform configurations (Android/iOS) keep version numbers close to the build scripts rather than in separate manifest files.