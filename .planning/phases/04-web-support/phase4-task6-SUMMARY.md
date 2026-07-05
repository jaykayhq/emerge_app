---
phase: 4
plan: 6
name: fix-web-build-errors
subsystem: build
tags: [web, drift, conditional-imports, platform-guard]
requires: [phase4-task5]
provides: [web-compilation]
affects: [lib/core/drift, lib/core/drift_repositories, lib/core/sync]
tech-stack:
  added: [conditional-imports]
  patterns: [platform-barrier-files, stub-classes-for-web]
key-files:
  created:
    - lib/core/drift/app_database.dart
    - lib/core/drift/drift_native.dart
    - lib/core/drift/drift_stubs.dart
    - lib/core/drift_repositories/repositories_barrel.dart
    - lib/core/drift_repositories/repositories_stub.dart
    - lib/core/sync/sync_engine_barrel.dart
    - lib/core/sync/sync_engine_stub.dart
  modified:
    - lib/core/drift/database.dart
    - lib/core/drift/daos/*.dart (9 files)
    - lib/core/drift_repositories/drift_tribe_repository.dart
    - lib/core/sync/sync_engine.dart
    - lib/core/sync/sync_providers.dart
    - lib/core/sync/sync_trigger_service.dart
    - lib/features/**/*.dart (provider files)
metrics:
  duration: 45min
  completed: 2026-05-14
---

# Phase 4 Task 6: Fix remaining native-only compilation errors for web build

## One-liner
Used Dart conditional imports (`if (dart.library.io)`) to prevent `sqlite3`/`drift` packages from being compiled on web, enabling `flutter build web` to succeed.

## What was built

### Problem
The `sqlite3` package uses `dart:ffi` which doesn't exist on web. Any file that transitively imports `drift` or `sqlite3` would fail web compilation. The app had many files importing drift packages directly or transitively through `database.dart`.

### Solution: Platform-specific barrier files
Created conditional import barriers at three levels:

1. **Drift module** (`lib/core/drift/`):
   - Extracted `AppDatabase` class from `database.dart` into `app_database.dart`
   - Created `drift_native.dart` (re-exports drift + app_database + DAOs)
   - Created `drift_stubs.dart` (stub types for web: Value, AppDatabase, DAOs, table data)
   - `database.dart` now uses `export` + `import` with conditional: `export 'drift_stubs.dart' if (dart.library.io) 'drift_native.dart'`

2. **Drift repositories** (`lib/core/drift_repositories/`):
   - `repositories_stub.dart` — web-safe stubs with matching constructors/interfaces
   - `repositories_native.dart` — re-exports real implementations
   - `repositories_barrel.dart` — conditional export between the two
   - All provider files updated to import the barrel

3. **Sync engine** (`lib/core/sync/`):
   - `sync_engine_stub.dart` — web-safe stub
   - `sync_engine_barrel.dart` — conditional import barrier
   - All consumers updated to import the barrel

### Additional fixes
- Changed DAO file imports from `../database.dart` to `../app_database.dart` (generator needs direct type resolution)
- Fixed `UserProfile?` nullability issues in `user_stats_providers.dart`, `world_health_provider.dart`, `world_health_service.dart` that dart2js caught
- Regenerated `.g.dart` files with `build_runner`

### Deviations from Plan

**Rule 2 - Auto-add missing critical functionality:**
- Added null safety checks in 3 files (`user_stats_providers.dart`, `world_health_provider.dart`, `world_health_service.dart`) where `UserProfile?` was accessed without null checking — these were pre-existing bugs exposed by dart2js's stricter type checking
- Added `insertActivity` method to `TribeActivityDao` stub and `updateWorldHealth`/`getWeeklyActivity` methods to `DriftUserStatsRepository` stub to match real implementations

**Rule 1 - Bug fix: DAO file imports**
- DAO files imported `../database.dart` but needed `../app_database.dart` for the drift generator to properly resolve `AppDatabase` type parameter bound

### Key design decisions
- Used conditional imports (`if (dart.library.io)`) at the module boundary instead of stubbing every drift type
- Repository stubs match the exact interface signatures and constructors but are never instantiated on web
- Kept all existing provider logic intact — only import paths changed

## Verification

### Web build
```
$ flutter build web
✓ Built build\web
```
No compilation errors. Only `purchases_flutter` Wasm warning (pre-existing, lint only).

### Native tests
```
$ flutter test
00:53 +227: All tests passed!
```
All 227 tests pass with no regressions.

## Known Stubs
- Stub classes in `lib/core/drift/drift_stubs.dart`, `lib/core/drift_repositories/repositories_stub.dart`, and `lib/core/sync/sync_engine_stub.dart` are never instantiated on web — all providers return Firestore-based implementations when `kIsWeb` is true.

## Self-Check: PASSED
- `flutter build web` succeeds (verified)
- `flutter test` passes (227/227)
