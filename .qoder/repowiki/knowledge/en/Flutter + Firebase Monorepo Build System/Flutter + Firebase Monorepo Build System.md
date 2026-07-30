---
kind: build_system
name: Flutter + Firebase Monorepo Build System
category: build_system
scope:
    - '**'
source_files:
    - pubspec.yaml
    - firebase.json
    - android/build.gradle.kts
    - android/app/build.gradle.kts
    - functions/package.json
    - ios/Runner/Info.plist
    - README.md
---

The Emerge Habit Engine uses a Flutter-based monorepo build system centered on the Flutter SDK with Firebase Gen 2 Cloud Functions as the backend. The build pipeline spans multiple platforms (Android, iOS, Web) and is orchestrated through platform-specific Gradle/Xcode configurations, Flutter's pubspec.yaml, and Firebase CLI tooling.

**Build Tools and Frameworks:**
- Flutter SDK (Dart ^3.10.0) as the primary build system for cross-platform mobile/web apps
- Android: Gradle Kotlin DSL (build.gradle.kts) with Kotlin 2.3.21, NDK 28.2.13676358, Java 17 compatibility
- iOS: Xcode project with Flutter integration via Generated.xcconfig files
- Web: Flutter web build targeting Firebase Hosting with service worker support
- Firebase Gen 2 Cloud Functions: TypeScript/Node.js 22 runtime with TSC compilation
- Code generation: Riverpod generators, Drift (SQLite), flutter_launcher_icons, flutter_native_splash

**Key Build Configuration Files:**
- `pubspec.yaml`: Central Flutter dependency management, version control (1.0.6+10), asset declarations, shader configuration, and launcher icon setup
- `firebase.json`: Firebase project configuration including Firestore rules, Storage rules, Remote Config templates, hosting settings with security headers, and emulator configuration
- `android/build.gradle.kts` and `android/app/build.gradle.kts`: Android build configuration with signing, minification, ProGuard rules, Crashlytics integration, and memory optimization for low-RAM systems
- `functions/package.json`: Node.js 22 environment with TypeScript compilation, ESLint, Jest testing, and Firebase Functions deployment scripts

**Build Pipeline Architecture:**
The build system follows a multi-stage approach:
1. **Development**: `flutter pub get` → `dart run build_runner build --delete-conflicting-outputs` → `flutter run`
2. **Testing**: `flutter test` with coverage, `flutter analyze --fatal-infos` for static analysis
3. **Android Release**: Gradle builds with R8 minification, resource shrinking, and release signing via keystore properties
4. **iOS Release**: Xcode build using Flutter's generated iOS project with bundle versioning
5. **Web Deployment**: `flutter build web` → Firebase Hosting with optimized caching headers for static assets
6. **Cloud Functions**: `tsc` compilation → `firebase deploy --only functions`

**Versioning Strategy:**
- Semantic versioning with Dart-style format (version+buildNumber)
- Android: versionName/versionCode mapped from Flutter's version
- iOS: CFBundleShortVersionString/CFBundleVersion from Flutter variables
- Web: manifest.json and version.json for cache busting

**Asset and Code Generation:**
- Static assets organized under `assets/` with structured subdirectories for icons, images, worlds, and shaders
- Automated icon generation via flutter_launcher_icons for all platforms
- Native splash screen generation via flutter_native_splash
- Drift database schema generation and code generation for Riverpod state management
- Shader compilation for GLSL fragment shaders (cracked_orb.frag)

**Environment and Configuration Management:**
- Firebase configuration generated via flutterfire_cli into `lib/firebase_options.dart`
- Environment variables managed through `.env.example` and platform-specific key stores
- Remote Config template for feature flags and runtime configuration
- Separate debug/profile/release build types with appropriate optimizations and debugging flags

**CI/CD Integration:**
- GitHub Actions mentioned in README for CI pipeline
- Firebase emulators configured for local development with single-project mode
- Pre-deploy hooks for TypeScript compilation in Cloud Functions
- Coverage reporting and linting integrated into development workflow