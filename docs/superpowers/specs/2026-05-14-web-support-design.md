# Web Support Design — Hybrid Firestore Approach

> **Status:** Approved design doc
> **Date:** 2026-05-14
> **Goal:** Enable `flutter build web` by replacing native-only Drift/SQLite with direct Firestore access on web.

## Architecture Decision

**Hybrid approach:** Mobile (Android/iOS) keeps Drift + SQLite + sync engine. Web reads/writes Firestore directly, skipping the local SQLite cache entirely.

### Why Not Drift WASM?
- Requires `package:drift/wasm.dart` + `sqlite3_web` + WebAssembly SQLite bundle
- Requires rewriting `AppDatabase` to use platform-conditional query executor
- All DAOs need conditional imports
- Higher complexity for marginal benefit (web already has Firestore access)

### Why Not Shared Repositories?
- Drift repositories mix local DB writes with Firestore sync engine enqueuing
- Web has no local DB — forcing a unified repository interface would require stubs everywhere
- Conditionally routing at the provider level is cleaner and keeps mobile code untouched

## Architecture

```
                    ┌──────────────────────────┐
                    │    Provider Layer         │
                    │  (kIsWeb ? web : drift)   │
                    └──────┬───────────────────┘
                           │
             ┌─────────────┴─────────────┐
             │                           │
    ┌────────▼────────┐       ┌──────────▼──────────┐
    │ DriftRepository  │       │ FirestoreRepository  │
    │ (mobile)         │       │ (web)                │
    │ Drift → Firestore│       │ Firestore direct     │
    │ sync engine      │       │ no local cache       │
    └────────┬─────────┘       └──────────┬──────────┘
             │                           │
    ┌────────▼────────┐       ┌──────────▼──────────┐
    │  SQLite (drift) │       │  Firestore SDK       │
    └─────────────────┘       └─────────────────────┘
```

## File Inventory

### New Files — Firestore Repositories (web)

Each mirrors the existing `Drift*Repository` interface but writes directly to Firestore without local caching.

| File | Purpose | Interfaces Implemented |
|------|---------|----------------------|
| `lib/core/firestore_repositories/firestore_habit_repository.dart` | Habit CRUD via Firestore | `HabitRepository` |
| `lib/core/firestore_repositories/firestore_user_stats_repository.dart` | User stats via Firestore | `DriftUserStatsRepository` (subset) |
| `lib/core/firestore_repositories/firestore_challenge_repository.dart` | Challenges via Firestore | `ChallengeRepository` |
| `lib/core/firestore_repositories/firestore_tribe_repository.dart` | Tribes via Firestore | `TribeRepository` |
| `lib/core/firestore_repositories/firestore_leaderboard_repository.dart` | Leaderboard via Firestore | `LeaderboardRepository` |
| `lib/core/firestore_repositories/firestore_friend_repository.dart` | Friends via Firestore | `FriendRepository` |

### Modified Files — Provider Routing

| File | Change |
|------|--------|
| `lib/features/habits/presentation/providers/habit_providers.dart` | `habitRepositoryProvider` checks `kIsWeb` |
| `lib/features/gamification/presentation/providers/gamification_providers.dart` | `userProfileRepositoryProvider` checks `kIsWeb` |
| `lib/features/gamification/presentation/providers/user_stats_providers.dart` | `userStatsRepositoryProvider` checks `kIsWeb` |
| `lib/features/social/presentation/providers/tribes_provider.dart` | Tribe repo checks `kIsWeb` |
| `lib/features/social/presentation/providers/challenge_provider.dart` | Challenge repo checks `kIsWeb` |
| `lib/features/social/presentation/providers/friends_leaderboard_provider.dart` | Friend repo checks `kIsWeb` |
| `lib/core/social/presentation/providers/challenge_bundle_provider.dart` | Challenge bundle repo checks `kIsWeb` |
| `lib/core/drift/database.dart` | Guard `AppDatabase` init with `!kIsWeb` |
| `lib/core/sync/sync_engine.dart` | Guard sync engine with `!kIsWeb` |
| `lib/core/sync/sync_providers.dart` | Guard sync providers with `!kIsWeb` |
| `lib/core/sync/sync_trigger_service.dart` | Guard trigger service with `!kIsWeb` |
| `lib/core/init/init_app.dart` | Already has `kIsWeb` guards |
| `lib/core/drift/database.dart` provider | `appDatabaseProvider` returns null on web |
| `lib/features/onboarding/data/repositories/local_settings_repository.dart` | Guard Hive init with `!kIsWeb` |
| `lib/main.dart` | Guard Drift-specific initializations |

### Files Guarded (no code changes, just kIsWeb checks on usage)

- `lib/features/world_map/presentation/screens/level_immersive_screen.dart` (dart:io)
- `lib/features/timeline/presentation/widgets/timeline_share_preview.dart` (dart:io)
- `lib/features/monetization/presentation/widgets/ad_banner_widget.dart` (dart:io)
- `lib/features/monetization/domain/services/ad_manager_service.dart` (dart:io)
- `lib/core/security/app_security.dart` (dart:io)
- `lib/core/network/secure_http_client.dart` (dart:io)

## Implementation Order

1. **Guard Drift + sync engine** — make `AppDatabase`, `sync_engine`, `sync_providers` web-safe with `kIsWeb` guards
2. **Create Firestore repositories** — one by one mirroring the Drift interfaces
3. **Route providers** — swap repositories at the provider level based on `kIsWeb`
4. **Fix compilation** — address remaining `dart:io` imports, Hive, path_provider
5. **Build web** — `flutter build web` should compile

## Testing Strategy

- Existing unit tests remain unchanged (they mock repositories)
- Web-specific testing is manual via `flutter run -d chrome`
- Each Firestore repository has parallel structure to its Drift counterpart — same interface, different backend
