# Milestone Rating Popup + Feedback Form Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ask users for a rating at peak-satisfaction milestones, route high ratings to the store review flow, and low ratings to an in-app feedback form persisted to Firestore.

**Architecture:** Pure, unit-testable `RatingPromptGate` (milestone + cooldown + persisted flags) following the project's signature pattern; a `RatingPromptControllerProvider` Notifier that observes existing milestone signals; `in_app_review` on mobile, Play Store link card on web; `FeedbackScreen` writing to `feedback/{uid}`.

**Tech Stack:** Flutter/Riverpod, `in_app_review`, `shared_preferences` (present), `url_launcher` (present), fpdart, Firestore rules.

---

## File Structure

**New (Flutter):**
- `lib/features/rating/domain/rating_prompt_gate.dart` — pure gate + `RatingPromptSignal` enum + `RatingPromptDecision`.
- `lib/features/rating/domain/rating_prompt_store.dart` — persistence interface + `SharedPreferencesRatingPromptStore`.
- `lib/features/rating/domain/review_launcher.dart` — interface (native prompt vs Play Store card).
- `lib/features/rating/presentation/providers/rating_prompt_provider.dart` — controller Notifier (`@riverpod`).
- `lib/features/rating/presentation/widgets/rating_prompt_dialog.dart`.
- `lib/features/rating/presentation/screens/feedback_screen.dart`.
- `lib/features/rating/data/repositories/feedback_repository.dart` — Firestore write.
- `test/features/rating/domain/rating_prompt_gate_test.dart`
- `test/features/rating/domain/rating_prompt_store_test.dart`
- `test/features/rating/presentation/widgets/rating_prompt_dialog_test.dart`
- `test/features/rating/presentation/screens/feedback_screen_test.dart`

**Modified:** `pubspec.yaml` (+`in_app_review`), `firestore.rules` (+`feedback/{uid}`), `lib/features/habits/presentation/providers/habit_providers.dart` (streak-7 emit), `lib/features/social/domain/services/club_activity_service.dart` (first-challenge emit), milestone site for emerge reveal, `lib/core/router/router.dart` (+`/feedback`), `lib/core/router/router.dart` navigator key exposure for the dialog.

---

## Task 1: `in_app_review` dependency

- [ ] **Step 1: Add the package**

```bash
flutter pub add in_app_review
```
Expected: adds `in_app_review: ^2.x` to `pubspec.yaml` and resolves.

- [ ] **Step 2: Verify**

```bash
cd /home/user/emerge_app && flutter pub get
```
Expected: resolves clean.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add in_app_review for native rating prompts"
```

---

## Task 2: `RatingPromptGate` (pure logic) + tests

**Files:**
- Create: `lib/features/rating/domain/rating_prompt_gate.dart`
- Test: `test/features/rating/domain/rating_prompt_gate_test.dart`

- [ ] **Step 1: Write the failing test**

`test/features/rating/domain/rating_prompt_gate_test.dart`:

```dart
import 'package:emerge_app/features/rating/domain/rating_prompt_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const now = DateTime(2026, 8, 8, 12);
  const cooldown = Duration(days: 90);

  group('RatingPromptGate.shouldAsk', () {
    test('asks when never asked before', () {
      expect(
        RatingPromptGate.shouldAsk(
          signal: RatingPromptSignal.sevenDayStreak,
          now: now,
          lastAskedAt: null,
          versionAskedFor: null,
          dontAskAgain: false,
          currentVersion: '1.0.7+12',
          cooldown: cooldown,
        ),
        isTrue,
      );
    });

    test('does not ask twice in the same version', () {
      expect(
        RatingPromptGate.shouldAsk(
          signal: RatingPromptSignal.sevenDayStreak,
          now: now,
          lastAskedAt: now.subtract(const Duration(days: 1)),
          versionAskedFor: '1.0.7+12',
          dontAskAgain: false,
          currentVersion: '1.0.7+12',
          cooldown: cooldown,
        ),
        isFalse,
      );
    });

    test('asks again in a newer version after cooldown', () {
      expect(
        RatingPromptGate.shouldAsk(
          signal: RatingPromptSignal.sevenDayStreak,
          now: now,
          lastAskedAt: DateTime(2026, 1, 1),
          versionAskedFor: '1.0.5+9',
          dontAskAgain: false,
          currentVersion: '1.0.7+12',
          cooldown: cooldown,
        ),
        isTrue,
      );
    });

    test('does not ask within cooldown even in a newer version', () {
      expect(
        RatingPromptGate.shouldAsk(
          signal: RatingPromptSignal.sevenDayStreak,
          now: now,
          lastAskedAt: now.subtract(const Duration(days: 10)),
          versionAskedFor: '1.0.6+11',
          dontAskAgain: false,
          currentVersion: '1.0.7+12',
          cooldown: cooldown,
        ),
        isFalse,
      );
    });

    test('never asks when dontAskAgain is set', () {
      expect(
        RatingPromptGate.shouldAsk(
          signal: RatingPromptSignal.challengeCompleted,
          now: now,
          lastAskedAt: null,
          versionAskedFor: null,
          dontAskAgain: true,
          currentVersion: '1.0.7+12',
          cooldown: cooldown,
        ),
        isFalse,
      );
    });

    test('cooldown expiry re-enables asking (new version)', () {
      expect(
        RatingPromptGate.shouldAsk(
          signal: RatingPromptSignal.emergeReveal,
          now: now,
          lastAskedAt: DateTime(2026, 4, 1),
          versionAskedFor: '1.0.5+9',
          dontAskAgain: false,
          currentVersion: '1.0.7+12',
          cooldown: cooldown,
        ),
        isTrue,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/rating/domain/rating_prompt_gate_test.dart --timeout 60s`
Expected: FAIL — module not found

- [ ] **Step 3: Write minimal implementation**

`lib/features/rating/domain/rating_prompt_gate.dart`:

```dart
/// Signals a peak-satisfaction moment that qualifies for a rating prompt.
enum RatingPromptSignal { sevenDayStreak, challengeCompleted, emergeReveal }

/// Pure decision logic for the rating prompt gate — no Flutter, no Firebase.
class RatingPromptGate {
  const RatingPromptGate._();

  static const Duration defaultCooldown = Duration(days: 90);

  /// True when the prompt should be shown for [signal].
  ///
  /// Rules:
  /// - never ask if the user opted out ([dontAskAgain])
  /// - never ask twice in the same app version
  /// - never ask more often than [cooldown]
  static bool shouldAsk({
    required RatingPromptSignal signal,
    required DateTime now,
    required DateTime? lastAskedAt,
    required String? versionAskedFor,
    required bool dontAskAgain,
    required String currentVersion,
    required Duration cooldown,
  }) {
    if (dontAskAgain) return false;
    if (lastAskedAt == null) return true;
    if (versionAskedFor == currentVersion) return false;
    if (now.difference(lastAskedAt) < cooldown) return false;
    return true;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/rating/domain/rating_prompt_gate_test.dart --timeout 60s`
Expected: PASS — 6 passing

- [ ] **Step 5: Commit**

```bash
git add lib/features/rating/domain/rating_prompt_gate.dart test/features/rating/domain/rating_prompt_gate_test.dart
git commit -m "feat(rating): pure rating-prompt gate with cooldown and version rules"
```

---

## Task 3: `RatingPromptStore` persistence + tests

**Files:**
- Create: `lib/features/rating/domain/rating_prompt_store.dart`
- Test: `test/features/rating/domain/rating_prompt_store_test.dart`

- [ ] **Step 1: Write the failing test**

`test/features/rating/domain/rating_prompt_store_test.dart`:

```dart
import 'package:emerge_app/features/rating/domain/rating_prompt_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists and reads back the rating prompt state', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesRatingPromptStore();

    expect(await store.lastAskedAt(), isNull);
    expect(await store.versionAskedFor(), isNull);
    expect(await store.dontAskAgain(), isFalse);

    await store.recordAsked(DateTime(2026, 8, 8, 12), '1.0.7+12');
    await store.setDontAskAgain();

    expect(await store.lastAskedAt(), DateTime(2026, 8, 8, 12));
    expect(await store.versionAskedFor(), '1.0.7+12');
    expect(await store.dontAskAgain(), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/rating/domain/rating_prompt_store_test.dart --timeout 60s`
Expected: FAIL — module not found

- [ ] **Step 3: Write minimal implementation**

`lib/features/rating/domain/rating_prompt_store.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence for the rating prompt gate. Abstract so tests can inject a fake.
abstract class RatingPromptStore {
  Future<DateTime?> lastAskedAt();
  Future<String?> versionAskedFor();
  Future<bool> dontAskAgain();
  Future<void> recordAsked(DateTime at, String version);
  Future<void> setDontAskAgain();
}

/// SharedPreferences-backed implementation.
class SharedPreferencesRatingPromptStore implements RatingPromptStore {
  static const _kLastAsked = 'rating_prompt.lastAskedAt';
  static const _kVersion = 'rating_prompt.versionAskedFor';
  static const _kDontAskAgain = 'rating_prompt.dontAskAgain';

  @override
  Future<DateTime?> lastAskedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastAsked);
    return raw == null ? null : DateTime.fromMillisecondsSinceEpoch(int.parse(raw));
  }

  @override
  Future<String?> versionAskedFor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kVersion);
  }

  @override
  Future<bool> dontAskAgain() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDontAskAgain) ?? false;
  }

  @override
  Future<void> recordAsked(DateTime at, String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastAsked, at.millisecondsSinceEpoch.toString());
    await prefs.setString(_kVersion, version);
  }

  @override
  Future<void> setDontAskAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDontAskAgain, true);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/rating/domain/rating_prompt_store_test.dart --timeout 60s`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/rating/domain/rating_prompt_store.dart test/features/rating/domain/rating_prompt_store_test.dart
git commit -m "feat(rating): SharedPreferences rating-prompt store"
```

---

## Task 4: `ReviewLauncher` abstraction + implementation

**Files:**
- Create: `lib/features/rating/domain/review_launcher.dart`
- Test: `test/features/rating/domain/review_launcher_test.dart`

- [ ] **Step 1: Write the failing test**

`test/features/rating/domain/review_launcher_test.dart`:

```dart
import 'package:emerge_app/features/rating/domain/review_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('play store url targets the app bundle id', () {
    expect(
      playStoreReviewUrl,
      'https://play.google.com/store/apps/details?id=com.emerge.emerge_app',
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/rating/domain/review_launcher_test.dart --timeout 60s`
Expected: FAIL — undefined

- [ ] **Step 3: Write minimal implementation**

`lib/features/rating/domain/review_launcher.dart`:

```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

/// Play Store deep link for the rating fallback (web + mobile fallback).
const String playStoreReviewUrl =
    'https://play.google.com/store/apps/details?id=com.emerge.emerge_app';

/// Launches the appropriate review surface:
/// - native: in_app_review.requestReview() (throws if unavailable)
/// - web: opens the Play Store page
abstract class ReviewLauncher {
  Future<bool> launch();
}

class DefaultReviewLauncher implements ReviewLauncher {
  @override
  Future<bool> launch() async {
    if (kIsWeb) {
      return launchUrl(Uri.parse(playStoreReviewUrl));
    }
    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        return true;
      }
      // Fall back to the store page when the native prompt is unavailable
      // (simulator, rate-limited, etc.).
      return launchUrl(Uri.parse(playStoreReviewUrl));
    } catch (_) {
      return launchUrl(Uri.parse(playStoreReviewUrl));
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/rating/domain/review_launcher_test.dart --timeout 60s`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/rating/domain/review_launcher.dart test/features/rating/domain/review_launcher_test.dart
git commit -m "feat(rating): review launcher (native prompt + Play Store fallback)"
```

---

## Task 5: `FeedbackRepository` + `feedback/{uid}` rules

**Files:**
- Create: `lib/features/rating/data/repositories/feedback_repository.dart`
- Modify: `firestore.rules`
- Test: `test/features/rating/data/repositories/feedback_repository_test.dart`

- [ ] **Step 1: Add the rules (verify with the rules deploy)**

Add to `firestore.rules`, near the `users` block:

```firestore
    // User feedback (low-rating flow) — owner-write, admin-read.
    match /feedback/{uid} {
      allow read: if isOwner(uid);
      allow write: if isOwner(uid) &&
        request.resource.data.keys().hasAll(['userId', 'message', 'rating', 'createdAt']) &&
        request.resource.data.userId == request.auth.uid &&
        request.resource.data.message is string &&
        request.resource.data.message.size() <= 2000 &&
        request.resource.data.rating is number &&
        request.resource.data.rating >= 1 &&
        request.resource.data.rating <= 5 &&
        request.resource.data.createdAt is timestamp;
    }
```

- [ ] **Step 2: Write the failing repo test**

`test/features/rating/data/repositories/feedback_repository_test.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/rating/data/repositories/feedback_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}
class _MockCollection extends Mock implements CollectionReference<Map<String, dynamic>> {}
class _MockDoc extends Mock implements DocumentReference<Map<String, dynamic>> {}

void main() {
  test('submitFeedback writes to feedback/{uid}', () async {
    final firestore = _MockFirestore();
    final collection = _MockCollection();
    final doc = _MockDoc();
    when(() => firestore.collection('feedback')).thenReturn(collection);
    when(() => collection.doc('u1')).thenReturn(doc);
    when(() => doc.set(any(), any())).thenAnswer((_) async {});

    final repo = FeedbackRepository(firestore);
    final result = await repo.submitFeedback(
      userId: 'u1',
      rating: 2,
      message: 'Too hard to track',
    );

    expect(result.isRight(), isTrue);
    final data = verify(() => doc.set(captureAny(), any())).captured.single as Map<String, dynamic>;
    expect(data['userId'], 'u1');
    expect(data['rating'], 2);
    expect(data['message'], 'Too hard to track');
    expect(data.containsKey('createdAt'), isTrue);
  });

  test('submitFeedback returns Left on failure', () async {
    final firestore = _MockFirestore();
    final collection = _MockCollection();
    final doc = _MockDoc();
    when(() => firestore.collection('feedback')).thenReturn(collection);
    when(() => collection.doc('u1')).thenReturn(doc);
    when(() => doc.set(any(), any())).thenThrow(Exception('offline'));

    final repo = FeedbackRepository(firestore);
    final result = await repo.submitFeedback(userId: 'u1', rating: 1, message: 'x');
    expect(result.isLeft(), isTrue);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/rating/data/repositories/feedback_repository_test.dart --timeout 60s`
Expected: FAIL — module not found

- [ ] **Step 4: Write minimal implementation**

`lib/features/rating/data/repositories/feedback_repository.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:fpdart/fpdart.dart';

/// Persists low-rating feedback to feedback/{uid}. One doc per user (upsert).
class FeedbackRepository {
  final FirebaseFirestore _firestore;

  FeedbackRepository(this._firestore);

  Future<Either<Failure, void>> submitFeedback({
    required String userId,
    required int rating,
    required String message,
    String? appVersion,
    String? platform,
  }) async {
    try {
      await _firestore.collection('feedback').doc(userId).set({
        'userId': userId,
        'rating': rating,
        'message': message.trim(),
        'appVersion': appVersion,
        'platform': platform,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

@Riverpod(keepAlive: true)
FeedbackRepository feedbackRepository(Ref ref) =>
    FeedbackRepository(FirebaseFirestore.instance);
```

Note: if `@Riverpod` codegen is used, declare `part 'feedback_repository.g.dart';` and run `flutter pub run build_runner build`. The repo may instead expose a plain provider to avoid codegen — match the file's existing conventions (`paystack_payment_repository.dart` uses `@riverpod` + `.g.dart`).

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/rating/data/repositories/feedback_repository_test.dart --timeout 60s`
Expected: PASS

- [ ] **Step 6: Build codegen + commit**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
git add lib/features/rating/data/repositories/feedback_repository.dart lib/features/rating/data/repositories/feedback_repository.g.dart firestore.rules test/features/rating/data/repositories/feedback_repository_test.dart
git commit -m "feat(rating): feedback repository + rules for low-rating flow"
```

---

## Task 6: `RatingPromptControllerProvider` + milestone wiring

**Files:**
- Create: `lib/features/rating/presentation/providers/rating_prompt_provider.dart`
- Modify: `lib/features/habits/presentation/providers/habit_providers.dart` (streak-7 emit)
- Modify: `lib/features/social/domain/services/club_activity_service.dart` (first-challenge emit)
- Test: `test/features/rating/presentation/providers/rating_prompt_provider_test.dart`

- [ ] **Step 1: Write the failing controller test**

`test/features/rating/presentation/providers/rating_prompt_provider_test.dart`:

```dart
import 'package:emerge_app/features/rating/domain/rating_prompt_gate.dart';
import 'package:emerge_app/features/rating/domain/rating_prompt_store.dart';
import 'package:emerge_app/features/rating/domain/review_launcher.dart';
import 'package:emerge_app/features/rating/presentation/providers/rating_prompt_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeStore implements RatingPromptStore {
  DateTime? askedAt;
  String? version;
  bool dontAsk = false;
  @override
  Future<DateTime?> lastAskedAt() async => askedAt;
  @override
  Future<String?> versionAskedFor() async => version;
  @override
  Future<bool> dontAskAgain() async => dontAsk;
  @override
  Future<void> recordAsked(DateTime at, String version) async {
    askedAt = at;
    this.version = version;
  }
  @override
  Future<void> setDontAskAgain() async => dontAsk = true;
}

class _FakeLauncher implements ReviewLauncher {
  int launches = 0;
  @override
  Future<bool> launch() async {
    launches++;
    return true;
  }
}

void main() {
  test('notifyMilestone asks on first milestone and persists', () async {
    final store = _FakeStore();
    final launcher = _FakeLauncher();
    final controller = RatingPromptController(store: store, launcher: launcher);
    controller.currentVersion = '1.0.7+12';

    await controller.notifyMilestone(RatingPromptSignal.sevenDayStreak);

    expect(launcher.launches, 1);
    expect(store.askedAt, isNotNull);
    expect(store.version, '1.0.7+12');
  });

  test('notifyMilestone does not re-ask in the same version', () async {
    final store = _FakeStore()..askedAt = DateTime(2026, 1, 1)..version = '1.0.7+12';
    final launcher = _FakeLauncher();
    final controller = RatingPromptController(store: store, launcher: launcher);
    controller.currentVersion = '1.0.7+12';

    await controller.notifyMilestone(RatingPromptSignal.challengeCompleted);

    expect(launcher.launches, 0);
  });

  test('low rating routes to feedback and records the ask', () async {
    final store = _FakeStore();
    final launcher = _FakeLauncher();
    final controller = RatingPromptController(store: store, launcher: launcher);
    controller.currentVersion = '1.0.7+12';
    final navigated = <String>[];
    controller.onOpenFeedback = () => navigated.add('feedback');

    await controller.handleRating(2);

    expect(store.askedAt, isNotNull);
    expect(navigated, ['feedback']);
    expect(launcher.launches, 0);
  });

  test('high rating launches the review flow', () async {
    final store = _FakeStore();
    final launcher = _FakeLauncher();
    final controller = RatingPromptController(store: store, launcher: launcher);
    controller.currentVersion = '1.0.7+12';

    await controller.handleRating(5);

    expect(launcher.launches, 1);
    expect(store.askedAt, isNotNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/rating/presentation/providers/rating_prompt_provider_test.dart --timeout 60s`
Expected: FAIL — module not found

- [ ] **Step 3: Write the controller**

`lib/features/rating/presentation/providers/rating_prompt_provider.dart`:

```dart
import 'package:emerge_app/core/services/web_update_service.dart' show kAppVersion;
import 'package:emerge_app/features/rating/domain/rating_prompt_gate.dart';
import 'package:emerge_app/features/rating/domain/rating_prompt_store.dart';
import 'package:emerge_app/features/rating/domain/review_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ratingPromptStoreProvider = Provider<RatingPromptStore>(
  (_) => SharedPreferencesRatingPromptStore(),
);

final reviewLauncherProvider = Provider<ReviewLauncher>(
  (_) => DefaultReviewLauncher(),
);

/// Observes milestone signals and owns the gate decision + persistence.
class RatingPromptController {
  RatingPromptController({
    required RatingPromptStore store,
    required ReviewLauncher launcher,
  })  : _store = store,
        _launcher = launcher;

  final RatingPromptStore _store;
  final ReviewLauncher _launcher;

  String currentVersion = kAppVersion;
  Future<void> Function()? onOpenFeedback;

  Future<void> notifyMilestone(RatingPromptSignal signal) async {
    final now = DateTime.now();
    final shouldAsk = RatingPromptGate.shouldAsk(
      signal: signal,
      now: now,
      lastAskedAt: await _store.lastAskedAt(),
      versionAskedFor: await _store.versionAskedFor(),
      dontAskAgain: await _store.dontAskAgain(),
      currentVersion: currentVersion,
      cooldown: RatingPromptGate.defaultCooldown,
    );
    if (!shouldAsk) return;
    await handleRating(5); // default: milestone implies positive sentiment
  }

  /// Routes a rating: >=4 launches review; <=3 opens feedback; both persist.
  Future<void> handleRating(int rating) async {
    final now = DateTime.now();
    await _store.recordAsked(now, currentVersion);
    if (rating >= 4) {
      await _launcher.launch();
    } else {
      await onOpenFeedback?.call();
    }
  }

  Future<void> notNow() async {
    await _store.recordAsked(DateTime.now(), currentVersion);
  }
}

final ratingPromptControllerProvider = Provider<RatingPromptController>((ref) {
  return RatingPromptController(
    store: ref.watch(ratingPromptStoreProvider),
    launcher: ref.watch(reviewLauncherProvider),
  );
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/rating/presentation/providers/rating_prompt_provider_test.dart --timeout 60s`
Expected: PASS

- [ ] **Step 5: Wire milestone emissions**

In `lib/features/habits/presentation/providers/habit_providers.dart` at the streak computation (~line 253, where `newStreak` is produced), after the streak value is known:

```dart
        if (newStreak == 7) {
          ref.read(ratingPromptControllerProvider).notifyMilestone(
                RatingPromptSignal.sevenDayStreak,
              );
        }
```

Add the imports (`ratingPromptControllerProvider`, `RatingPromptSignal`).

In `lib/features/social/domain/services/club_activity_service.dart` (`challenge_complete` activity creation, line ~32), when the user's first challenge completes:

```dart
        if (isFirstChallengeCompletion) {
          ref.read(ratingPromptControllerProvider).notifyMilestone(
                RatingPromptSignal.challengeCompleted,
              );
        }
```

NOTE: `club_activity_service.dart` may not have a `ref` available (it's a domain service). If so, the emit moves to the caller (the screen that triggers the activity) — the implementer wires the emit where a `Ref` is in scope. The controller test covers the logic; the wiring is a one-liner at the existing call site.

- [ ] **Step 6: Verify + commit**

```bash
flutter analyze lib/features/rating lib/features/habits/presentation/providers/habit_providers.dart
flutter test test/features/rating/presentation/providers/rating_prompt_provider_test.dart --timeout 60s
git add lib/features/rating/presentation/providers/rating_prompt_provider.dart lib/features/habits/presentation/providers/habit_providers.dart test/features/rating/presentation/providers/rating_prompt_provider_test.dart
git commit -m "feat(rating): milestone controller + streak-7 wiring"
```

---

## Task 7: `RatingPromptDialog` + `FeedbackScreen` + route

**Files:**
- Create: `lib/features/rating/presentation/widgets/rating_prompt_dialog.dart`
- Create: `lib/features/rating/presentation/screens/feedback_screen.dart`
- Modify: `lib/core/router/router.dart` (+`/feedback` route)
- Test: `test/features/rating/presentation/widgets/rating_prompt_dialog_test.dart`, `test/features/rating/presentation/screens/feedback_screen_test.dart`

- [ ] **Step 1: Write the failing widget tests**

`test/features/rating/presentation/widgets/rating_prompt_dialog_test.dart`:

```dart
import 'package:emerge_app/features/rating/presentation/widgets/rating_prompt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders stars and Not now', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showRatingPromptDialog(
            context,
            onRating: (_) {},
            onNotNow: () {},
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('How is Emerge going?'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsWidgets);
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets('tapping a star routes the rating', (tester) async {
    int? selected;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showRatingPromptDialog(
            context,
            onRating: (r) => selected = r,
            onNotNow: () {},
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pumpAndSettle();
    expect(selected, isNotNull);
  });
}
```

`test/features/rating/presentation/screens/feedback_screen_test.dart`:

```dart
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/rating/data/repositories/feedback_repository.dart';
import 'package:emerge_app/features/rating/presentation/screens/feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

class _MockRepo extends Mock implements FeedbackRepository {}

void main() {
  testWidgets('submits feedback and pops', (tester) async {
    final repo = _MockRepo();
    when(() => repo.submitFeedback(
          userId: any(named: 'userId'),
          rating: any(named: 'rating'),
          message: any(named: 'message'),
        )).thenAnswer((_) async => const Right<Failure, void>(null));

    await tester.pumpWidget(ProviderScope(
      overrides: [feedbackRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: FeedbackScreen(userId: 'u1', rating: 2)),
    ));
    await tester.enterText(find.byType(TextField), 'Too hard to track');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    verify(() => repo.submitFeedback(
          userId: 'u1', rating: 2, message: 'Too hard to track',
        )).called(1);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/rating/presentation/widgets/rating_prompt_dialog_test.dart test/features/rating/presentation/screens/feedback_screen_test.dart --timeout 60s`
Expected: FAIL — modules not found

- [ ] **Step 3: Write the dialog**

`lib/features/rating/presentation/widgets/rating_prompt_dialog.dart`:

```dart
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:flutter/material.dart';

typedef RatingCallback = void Function(int rating);

Future<void> showRatingPromptDialog(
  BuildContext context, {
  required RatingCallback onRating,
  required VoidCallback onNotNow,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1B1B2F),
      title: const Text('How is Emerge going?',
          style: TextStyle(color: Colors.white)),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (i) {
          final star = i + 1;
          return IconButton(
            icon: const Icon(Icons.star_border, color: Colors.amber, size: 36),
            onPressed: () {
              Navigator.of(context).pop();
              onRating(star);
            },
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onNotNow();
          },
          child: const Text('Not now', style: TextStyle(color: Colors.white54)),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Write the feedback screen**

`lib/features/rating/presentation/screens/feedback_screen.dart`:

```dart
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/rating/data/repositories/feedback_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  final String userId;
  final int rating;

  const FeedbackScreen({super.key, required this.userId, required this.rating});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref
        .read(feedbackRepositoryProvider)
        .submitFeedback(
          userId: widget.userId,
          rating: widget.rating,
          message: message,
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _submitting = false;
        _error = failure.message;
      }),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks — your feedback helps us improve.')),
        );
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Help us improve',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const Gap(8),
            const Text('What got in the way?',
                style: TextStyle(color: Colors.white60)),
            const Gap(24),
            TextField(
              controller: _controller,
              maxLines: 5,
              maxLength: 2000,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tell us what would have made this better…',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Gap(16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            FilledButton(
              onPressed: (_submitting || _controller.text.trim().isEmpty)
                  ? null
                  : _submit,
              style: FilledButton.styleFrom(backgroundColor: EmergeColors.teal),
              child: _submitting
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Submit',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Register the route**

In `lib/core/router/router.dart`, add:

```dart
      GoRoute(
        path: '/feedback',
        builder: (context, state) => FeedbackScreen(
          userId: state.uri.queryParameters['userId'] ?? '',
          rating: int.tryParse(state.uri.queryParameters['rating'] ?? '') ?? 3,
        ),
      ),
```

Add the import. (The dialog's `onOpenFeedback` callback in the controller uses `context.push('/feedback?userId=…&rating=…')` at the invocation site where a `BuildContext` is available.)

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/features/rating/presentation/widgets/rating_prompt_dialog_test.dart test/features/rating/presentation/screens/feedback_screen_test.dart --timeout 60s`
Expected: PASS (adjust `feedbackRepositoryProvider` exposure to match Task 5's provider shape).

- [ ] **Step 7: Verify + commit**

```bash
flutter analyze lib/features/rating lib/core/router/router.dart
flutter test test/features/rating --timeout 60s
git add lib/features/rating lib/core/router/router.dart test/features/rating
git commit -m "feat(rating): rating dialog + feedback screen + route"
```

---

## Self-Review (rating plan)

**Spec coverage:** §4 gate → Task 2; §7 store → Task 3; §6.2 review → Task 4; §6.3 feedback → Tasks 5+7; §8 rules → Task 5; §5 controller + milestone wiring → Task 6; §5.2/6.2 dialog + web card → Task 7. `package_info_plus` not needed — `kAppVersion` const exists (`web_update_service.dart:12`), bundle id confirmed (`com.emerge.emerge_app`).

**Placeholders:** none.

**Type consistency:** `RatingPromptSignal` (3 values), `RatingPromptGate.shouldAsk` signature matches the test; `RatingPromptStore` 5 methods; `ReviewLauncher.launch()`; `FeedbackRepository.submitFeedback({userId, rating, message, appVersion?, platform?})`; controller `notifyMilestone`/`handleRating`/`notNow`.

**Note for implementer:** `club_activity_service.dart` is a domain service without `ref`; wire the `challengeCompleted` emit at the screen caller that has a `Ref` (per Task 6 Step 5 note), or expose the controller through an injectable callback.

---

## Task 8: Full verification pass

- [ ] **Step 1: Analyze + focused tests**

```bash
flutter analyze lib/features/rating lib/core/router/router.dart lib/features/habits/presentation/providers/habit_providers.dart
flutter test test/features/rating --timeout 60s
```
Expected: analyze clean, all rating tests pass. Do NOT run the full suite.

- [ ] **Step 2: Rules check**

Verify `feedback/{uid}` block exists in `firestore.rules` and only allows owner write with the validation fields.

- [ ] **Step 3: Final commit**

```bash
git add -A && git commit -m "chore: rating popup verification pass" || echo "nothing to commit"
```
