# Technology Stack

**Analysis Date:** 2026-03-30 (Updated)

## Languages

**Primary:**
- Dart ^3.10.0 - All application code and feature logic.

**Secondary:**
- TypeScript (Node.js 22) - Firebase Cloud Functions logic.

## Runtime

**Environment:**
- Flutter SDK (Impeller enabled) - UI and core application logic.
- Firebase Gen 2 (Node.js 22 runtime for Functions).
- Native Android (minSdk 21) & iOS (standard Flutter support).

**Package Manager:**
- pub (Dart/Flutter packages) - `pubspec.yaml`
- npm (Firebase Functions) - `functions/package.json`

## Frameworks

**Core:**
- Flutter - Cross-platform UI framework.
- Firebase - Full backend suite (Auth, Firestore, Hosting, etc.).
- Flame - 2D Game Engine for world/avatar visualizations.

**Testing:**
- flutter_test - Unit and widget testing.
- mocktail - Null-safe mocking library.
- integration_test - Device-based end-to-end testing.

**Build/Dev:**
- build_runner - Code generation for Riverpod, Freezed, and JSON Serialization.
- flutter_launcher_icons - App icon generation.
- flutter_native_splash - Native splash screen generation.

## Key Dependencies

**Critical:**
- flutter_riverpod ^3.2.1 - State management via code generation.
- go_router ^17.1.0 - Declarative routing and deep linking.
- cloud_firestore ^6.1.2 - Primary NoSQL database.
- firebase_auth ^6.1.4 - Identity and authentication.

**Infrastructure:**
- firebase_functions_v2 - Server-side business logic and AI processing.
- purchases_flutter ^9.12.3 - RevenueCat for subscription management.
- google_mobile_ads ^7.0.0 - AdMob monetization.

## Configuration

**Environment:**
- `.env` files (via `flutter_dotenv`) for local environment variables.
- Firebase Remote Config for dynamic app behavior.
- `firebase_options.dart` for Firebase project identification.

**Build:**
- `pubspec.yaml` - Dependencies and asset management.
- `analysis_options.yaml` - Static analysis and linting rules.
- `firebase.json` - Firebase deployment configurations.

## Platform Requirements

**Development:**
- Flutter SDK 3.x+
- Firebase CLI
- Node.js (for Functions development)

**Production:**
- Android 5.0 (API 21) or higher.
- iOS (standard Flutter iOS requirements).
- Firebase Hosting (Web).
