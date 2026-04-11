# External Integrations

**Analysis Date:** 2026-03-30 (Updated)

## APIs & External Services

**Payment Processing:**
- RevenueCat (purchases_flutter) - Subscription management, paywalls, and cross-platform entitlements.
  - Auth: API keys in RevenueCat dashboard.
  - Endpoints: Subscription verification, offerings, and customer info.

**Authentication & Identity:**
- Firebase Auth - Primary identity provider.
  - Implementation: `firebase_auth`, `google_sign_in`.
  - Methods: Email/Password, Google OAuth.
  - Token storage: Persistent secure storage handled by Firebase.

**Cloud Features:**
- Firebase Cloud Functions (Gen 2) - Server-side logic, AI reflections, and data migrations.
  - Runtime: Node.js 22.
  - Integration: `cloud_functions` SDK.

**AI & Machine Learning:**
- Google Generative AI (Vertex AI) - AI-powered reflections, Goldilocks principle coaching.
  - Integration: `google_generative_ai` and `firebase_ai` (via Cloud Functions).

## Data Storage

**Databases:**
- Cloud Firestore - Primary NoSQL document store.
  - Connection: Native Firebase SDK.
  - Rules: `firestore.rules`.
  - Usage: User profiles, habit data, world state.

**Local Storage:**
- Hive (hive_flutter) - High-performance local storage for offline state.
- Shared Preferences - Simple key-value storage for settings.
- Flutter Secure Storage - Encrypted storage for sensitive tokens.

## Monitoring & Observability

**Error Tracking:**
- Firebase Crashlytics - Real-time crash reporting and non-fatal error tracking.

**Analytics:**
- Firebase Analytics - User behavior tracking and conversion funnels.

## Monetization

**Advertising:**
- Google AdMob (google_mobile_ads) - Rewarded ads and banners.

## CI/CD & Deployment

**Hosting:**
- Firebase Hosting - Web application hosting (`build/web`).

**Messaging:**
- Firebase Cloud Messaging (FCM) - Push notifications and background messaging.

## Environment Configuration

**Development:**
- Required env vars: `.env` file (gitignored, contains API keys not managed by Firebase).
- Local Emulators: Support for Firebase Emulator Suite (Firestore, Functions, Auth).

**Production:**
- Secrets: Managed in Firebase/Google Cloud Secret Manager for Functions.
- App Check: `firebase_app_check` for protecting backend resources.
