# Firestore Deployment, Tribe Sync & Performance — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy Firestore indexes/rules to fix tribe permission errors, verify tribe sync engine, and profile remaining performance issues.

**Architecture:** The `firestore.indexes.json` already defines composite indexes for tribes (`type` + `archetypeId`) but they haven't been deployed to the Firebase project. Deploy them + the permissive `firestore.rules` via `firebase deploy --only firestore`. Then verify the sync engine handles tribe writes without errors. Finally, profile app startup and navigation for remaining slowness.

**Tech Stack:** Firebase CLI, Firestore, Drift, Flutter DevTools

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `firestore.indexes.json` | Add missing `type` single-field index for tribes collection |
| Deploy | Firebase project (via CLI) | Push rules + indexes |
| Modify | `lib/core/drift_repositories/drift_tribe_repository.dart` | Log Firestore errors instead of silently swallowing |
| Inspect | `lib/core/sync/sync_engine.dart` | Verify tribe data sync path |
| Inspect | `lib/features/social/` | Check for unhandled Firestore query errors in other social features |

---

### Task 1: Deploy Firestore indexes and rules

**Files:**
- Deploy target: Firebase project's Firestore

The `firestore.indexes.json` has the composite index for tribes:
```json
{
  "collectionGroup": "tribes",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "type", "order": "ASCENDING"},
    {"fieldPath": "archetypeId", "order": "ASCENDING"},
    {"fieldPath": "__name__", "order": "ASCENDING"}
  ]
}
```

But there's NO single-field index for just `type` alone (Firebase auto-creates this, but it may not exist yet if the project is new or auto-indexing is disabled).

Additionally, the DriftTribeRepository.watchArchetypeClubs() does `.where('type', isEqualTo: ...)` without `.orderBy()`, which requires either:
- A single-field index on `type` (auto-created by Firebase), or
- A composite index where `type` is the first field

The existing composite index on `type` + `archetypeId` covers this case too (Firestore can use the first field of a composite index for simple equality filters).

- [ ] **Step 1: Verify Firebase CLI is installed and authenticated**

```bash
firebase --version
firebase projects:list
```

Expected: CLI version shown, project listed.

- [ ] **Step 2: Deploy Firestore indexes**

```bash
cd /c/Users/HP/Downloads/emerge_app && firebase deploy --only firestore:indexes
```

Expected: Indexes are created. This may take a few minutes as Firebase builds the indexes.

- [ ] **Step 3: Deploy Firestore rules**

```bash
cd /c/Users/HP/Downloads/emerge_app && firebase deploy --only firestore:rules
```

Expected: Rules deployed. This ensures the permissive tribe rules (`allow read: if true`) are in effect.

- [ ] **Step 4: Verify deployment**

```bash
cd /c/Users/HP/Downloads/emerge_app && firebase firestore:indexes
```

Expected: Shows the list of deployed indexes including the tribes composite index.

- [ ] **Step 5: Commit the deploy config (if any changes)**

If `firebase.json` or `firestore.indexes.json` were modified, commit them.

```bash
git add firebase.json firestore.indexes.json firestore.rules
git commit -m "chore: deploy Firestore indexes and rules for tribes queries"
```

---

### Task 2: Add Firestore error logging to tribe drift repository

**Files:**
- Modify: `lib/core/drift_repositories/drift_tribe_repository.dart`
- Test: `test/core/drift_repositories/drift_tribe_repository_test.dart`

The current `watchArchetypeClubs()` silently swallows Firestore errors:

```dart
remoteSub = _firestore
    .collection('tribes')
    .where('type', isEqualTo: TribeType.official.name)
    .snapshots()
    .listen(
      (snapshot) {
        remoteDocs = {
          for (final doc in snapshot.docs) doc.id: doc.data(),
        };
        emitMerged();
      },
      onError: (Object err) {
        // Remote failure: just log, UI already showing local data
      },
    );
```

The empty `onError` makes it impossible to diagnose if the issue is a missing index vs. a real permission error vs. a network issue.

- [ ] **Step 1: Add AppLogger import and error logging**

Add the import:
```dart
import 'package:emerge_app/core/utils/app_logger.dart';
```

Change the empty onError:
```dart
onError: (Object err) {
  AppLogger.e('Firestore tribe sync failed', err);
},
```

- [ ] **Step 2: Same for worldLeaderboardProvider in tribes_provider.dart**

Add logging to the error handler in `worldLeaderboardProvider`:
```dart
onError: (Object err) {
  AppLogger.e('Firestore leaderboard sync failed', err);
},
```

- [ ] **Step 3: Run tests**

```bash
flutter test test/core/drift_repositories/drift_tribe_repository_test.dart
flutter test test/features/social/presentation/providers/tribe_providers_test.dart
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/core/drift_repositories/drift_tribe_repository.dart lib/features/social/presentation/providers/tribes_provider.dart
git commit -m "fix(tribes): add Firestore error logging for tribe sync diagnostics"
```

---

### Task 3: Verify tribe sync engine path

**Files:**
- Inspect: `lib/core/sync/sync_engine.dart`
- Inspect: `lib/core/drift_repositories/drift_tribe_repository.dart` (joinClub method)

The `DriftTribeRepository.joinClub()` writes to Firestore via the `EnhancedSyncEngine`. Verify that:
1. The sync enqueues the correct Firestore paths
2. The paths match Firestore rules (e.g., `contributors/{userId}` requires `request.auth.uid == memberId`)
3. The sync handles permission errors gracefully

- [ ] **Step 1: Read and review joinClub in drift_tribe_repository.dart**

Read `lib/core/drift_repositories/drift_tribe_repository.dart` around the `joinClub()` method (around line 381-423).

Check:
- The sync engine enqueue calls
- The Firestore paths used
- That `memberId` = `userId` for contributors subcollection (must match `request.auth.uid`)

- [ ] **Step 2: Read and review sync_engine.dart for error handling**

Check how the sync engine handles Firestore write failures. It should:
- Retry on transient errors
- Log permission errors
- Not crash the app

- [ ] **Step 3: Fix any issues found**

If the sync engine uses incorrect Firestore paths or missing auth fields, fix them.

- [ ] **Step 4: Run tests**

```bash
flutter test test/core/drift_repositories/drift_tribe_repository_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add <files>
git commit -m "fix(tribes): verify and fix sync engine tribe write paths"
```

---

### Task 4: Profile app startup and navigation performance

**Files:**
- Inspect: App initialization and splash screen
- Inspect: Navigation transitions

The user reported general slowness. Now that the narrator typewriter is optimized, check for other slow paths.

- [ ] **Step 1: Profile app startup with Flutter DevTools**

Launch the app in profile mode:
```bash
flutter run --profile
```

Then use DevTools to record a performance timeline:
1. App cold start → splash → onboarding
2. Navigation to world map
3. Navigation to tribe lobby
4. Opening the narrator dialog

- [ ] **Step 2: Check for common performance issues**

Look for:
- **Excessive rebuilds** in Riverpod providers (use `ref.watch` only where needed)
- **Large build methods** in widget trees (especially `world_map_screen.dart`, `level_immersive_screen.dart`)
- **Expensive Firestore queries** on the main thread
- **Image loading** without caching
- **Animation jank** (frame drops below 60fps)

- [ ] **Step 3: Fix top performance issues found**

For each issue found:
1. Excessive rebuilds → scope Riverpod watches, use `ref.listen` instead of `ref.watch` where possible
2. Large build methods → extract widgets, use `const` constructors
3. Firestore queries → ensure they're on async streams, not blocking UI
4. Images → add `cached_network_image` or precache
5. Animation jank → reduce work in build methods during animations

- [ ] **Step 4: Create a performance baseline**

Run a simple startup timing test:
```bash
flutter test --performance test/performance/app_startup_test.dart
```

If the test doesn't exist, create one that measures:
- Time from app start to first frame
- Time to tribe lobby rendering
- Narrator dialog open time

- [ ] **Step 5: Commit fixes**

```bash
git add <files>
git commit -m "perf: fix [specific issue found]"
```

---

### Task 5: Check other social features for unhandled Firestore errors

**Files:**
- Inspect: `lib/features/social/presentation/screens/friends_screen.dart`
- Inspect: `lib/features/social/presentation/screens/challenges_screen.dart`
- Inspect: `lib/features/social/presentation/screens/challenge_detail_screen.dart`

The user originally couldn't access tribes. Other social features might have similar issues.

- [ ] **Step 1: Audit each social screen for Firestore query error handling**

For each screen, check:
1. What Firestore queries it makes
2. Are the queries covered by existing indexes in `firestore.indexes.json`?
3. Does it handle errors gracefully (show error state, not crash/infinite loading)?
4. Does it have a local Drift fallback?

- [ ] **Step 2: Add error handling to screens that lack it**

For screens without error handling, wrap async queries in try/catch and show user-friendly error states with retry buttons.

- [ ] **Step 3: Run social feature tests**

```bash
flutter test test/features/social/
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add <files>
git commit -m "fix(social): add Firestore error handling to social screens"
```
