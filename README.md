# Emerge — Identity-First Habit Engine

> Build habits that shape who you become, not just what you do.

## Overview

Emerge is a gamified habit-building app grounded in **identity psychology**. Instead of tracking checkboxes, Emerge reinforces _who you're becoming_ through:

- 🏛️ **Archetype selection** — Athlete, Creator, Scholar, Stoic, Mystic
- 🎮 **World building** — Habits grow your personal world (city, forest, zones)
- 📊 **XP & leveling** — Streaks unlock buildings, seasons evolve, entropy decays
- 🤖 **AI reflections** — Powered by Groq via Firebase Cloud Functions
- 💎 **Premium tier** — Unlimited habits, ad-free, AI features via RevenueCat

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart 3.5+, Impeller) |
| State | Riverpod v2 (code-gen) |
| Navigation | go_router (deep linking, predictive back) |
| Backend | Firebase Gen 2 (Firestore, Auth, Functions, Crashlytics) |
| AI | Firebase AI Logic (Groq via Cloud Functions) |
| Monetization | RevenueCat + Google AdMob |
| CI | GitHub Actions |

## Getting Started

```bash
# Clone and install
git clone https://github.com/your-org/emerge_app.git
cd emerge_app
flutter pub get

# Generate code (Riverpod, Freezed, JSON)
dart run build_runner build --delete-conflicting-outputs

# Run on a connected device
flutter run
```

### Firebase Setup

1. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
2. Run `flutterfire configure` to generate `firebase_options.dart`
3. Deploy Cloud Functions: `cd functions && npm install && firebase deploy --only functions`

### Environment Variables

| Variable | Where | Purpose |
|----------|-------|---------|
| `REVENUECAT_WEBHOOK_SECRET` | Cloud Functions env | Webhook signature verification |
| `INSIGHT_CACHE_DURATION_MS` | Cloud Functions env | AI insight cache TTL (default: 15min) |
| `GROQ_API_KEY` | Cloud Secret Manager | AI service key |

## Project Structure

```
lib/
├── core/               # Shared utilities, router, constants, security
├── features/
│   ├── auth/           # Firebase Auth (login, signup, providers)
│   ├── habits/         # CRUD, completion, streaks, repository
│   ├── gamification/   # XP, leveling, world state, buildings
│   ├── onboarding/     # Archetype & identity attribute selection
│   ├── ai/             # Groq AI reflections & insights
│   ├── monetization/   # RevenueCat, AdMob, paywall
│   ├── profile/        # Future self studio, avatar
│   └── settings/       # Notifications, preferences
functions/              # Firebase Cloud Functions (TypeScript)
docs/                   # Architecture, setup guides, legal
test/                   # Unit & widget tests
```

## Testing

```bash
flutter test                    # Run all tests
flutter test --coverage         # With coverage report
flutter analyze --fatal-infos   # Static analysis
```

## Legal

- [Privacy Policy](docs/legal/PRIVACY_POLICY.md)
- [Terms of Service](docs/legal/TERMS_OF_SERVICE.md)

## License

Proprietary — All rights reserved.
