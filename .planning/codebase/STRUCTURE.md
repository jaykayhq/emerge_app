# Directory Structure

**Analysis Date:** 2026-03-30 (Updated)

## Overview

```text
emerge_app/
├── android/            # Android-specific configuration and native code
├── assets/             # Images, fonts, Rive files, and sounds
├── functions/          # Firebase Cloud Functions (TypeScript)
├── ios/                # iOS-specific configuration and native code
├── lib/               # Primary application source code
│   ├── core/           # Shared logic, themes, and global services
│   ├── features/       # Modular feature-based logic
│   ├── scripts/        # Utility scripts (e.g., seeding, deployment)
│   ├── firebase_options.dart
│   └── main.dart       # App entry point
├── test/               # Unit, widget, and integration tests
├── web/                # Web-specific configuration
├── .firebaserc         # Firebase project configuration
├── firebase.json       # Firebase suite configuration
└── pubspec.yaml        # Flutter project dependencies and assets
```

## Detailed `lib/` Breakdown

### `lib/core/`
The shared kernel of the application:
- `config/`: App-wide configuration (env, flags).
- `init/`: App bootstrap logic (`init_app.dart`).
- `router/`: GoRouter navigation setup.
- `theme/`: Design system, archetype themes, and light/dark mode logic.
- `presentation/`: Shared widgets, global layouts (Scaffolds), and base UI components.
- `services/`: Global services (Notifications, Sound, Connectivity).
- `utils/`: Common helpers, extensions, and pure Dart utilities.

### `lib/features/`
Each feature is encapsulated and follows a sub-layer pattern:
- `ai/`: Vertex AI integration and reflecting logic.
- `auth/`: Login, Signup, and Identity management.
- `avatar/`: Visual character representation.
- `gamification/`: Levels, Exp, archetypes, and progression.
- `habits/`: Core habit engine (creation, tracking, history).
- `monetization/`: RevenueCat integration, paywalls, and contracts.
- `world_map/`: The evolved environment (Flame/Tiled integration).
- ... (social, settings, timeline, etc.)

Typical Feature Sub-Dir:
```text
feature_name/
├── data/               # Repositories (impl), DTOs, Sources
├── domain/             # Entities, Repository Interfaces, UseCases
└── presentation/       # Screens, Widgets, Providers (Controllers)
```

## Assets Organization

- `assets/icons/`: App and feature icons.
- `assets/images/levels/`: World map assets categorized by archetype (Athlete, Scholar, etc.).
- `assets/rive/`: Interactive vector animations.
- `assets/sounds/`: UI sound effects and haptics.
