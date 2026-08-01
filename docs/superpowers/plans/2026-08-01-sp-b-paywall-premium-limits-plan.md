# SP-B: Paywall Web Fix, Web Premium Activation, Premium Limits/Offers Framework — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop the web paywall from showing the "RevenueCat not configured" SnackBar (skip the offering fetch on web + suppress web error SnackBars via a pure guard), make web premium actually activate by streaming `users/{uid}.isPremium` from Firestore into `isPremiumProvider`, and add a pure `LimitsCatalog` (habits=5, clubs=1, coach asks=3/day, themes=1) that drives honest, real-limit paywall offer copy and stays in sync with `docs/FREEMIUM_MODEL.md`.

**Architecture:** Two pure decision functions in `PaywallWebGuard` gate the fetch + error SnackBar in `PaywallScreen` (web skips RevenueCat entirely; the Paystack path is external-page based). `IsPremium.build()` branches on `kIsWeb` before the RevenueCat retry loop and streams the `users/{uid}` Firestore doc via a data-layer `streamWebPremium` helper (testable with `fake_cloud_firestore`; existing owner-read rules already permit it). A const `LimitsCatalog` (pure domain model, no presentation imports) becomes the single source for the paywall benefit rows. Native behavior is bit-identical. No functions, rules, schema, or prefs changes.

**Tech Stack:** Flutter 3.x, Dart 3.10+, Riverpod 3.x (annotation + codegen), cloud_firestore, fake_cloud_firestore (dev), shared_preferences (existing cache fallback only).

**Spec:** `docs/superpowers/specs/2026-08-01-sp-b-paywall-premium-limits-design.md`

---

## ⚠️ Pre-flight (read first)

1. **The working tree is dirty** (pre-existing uncommitted changes across ~30 files, e.g. `firestore.rules`, `lib/core/drift/*`, `lib/core/router/router.g.dart`). **Commit only the files each task names** — never `git add -A` or `git add lib` wholesale.
2. **Run `dart analyze lib` before starting** to establish the baseline error count. Only SP-B-introduced errors are this plan's responsibility.
3. **`kIsWeb` is a compile-time constant** — in the VM test environment it is always `false`. That is why the web decision logic lives in pure functions (`PaywallWebGuard`, `streamWebPremium`) that are tested directly, while the `kIsWeb` branches in `paywall_screen.dart` / `subscription_provider.dart` are thin glue verified by `dart analyze` + the existing widget tests (which run native).
4. **No codegen is needed** — SP-B adds no `@riverpod` providers; `dart run build_runner` is not required by any task.
5. `PaywallScreen` currently renders `'UNLIMITED'` and the widget test asserts it (`test/features/monetization/presentation/screens/paywall_screen_test.dart:42`) — Task 4 updates both in one commit.
6. Firestore owner-read of `users/{userId}` already exists (`firestore.rules:283-290`) — do **not** touch rules.
7. Do not fix the pre-existing failing test `test/features/social/domain/services/tribe_membership_service_test.dart` (SP-G territory; fails identically at HEAD per SP-A handoff).
8. Reference facts (verified 2026-08-01): `paywall_screen.dart:33-35` (unconditional fetch), `:50-58` (error SnackBar), `:107-112` ("UNLIMITED / Habits, clubs, themes"), `:295-300` (`_openPaystackPage`); `revenue_cat_repository.dart:29-34` (web early-return), `:177-181` (`Left('RevenueCat not configured')`); `subscription_provider.dart:22-27` (auth gate), `:52-58` (stream pattern), `:105-121` (cache read); `paystack.ts:129-136` (webhook writes `users/{uid}.isPremium`); `auth_providers.dart:63-65` (`firestoreProvider`).

## File structure

### New files

| Path | Responsibility |
|---|---|
| `lib/features/monetization/domain/services/paywall_web_guard.dart` | Pure `shouldFetchOfferings` / `shouldShowPaywallErrorSnackBar` |
| `lib/features/monetization/domain/models/premium_limit.dart` | `FreeTierLimit` + `LimitsCatalog` (const) |
| `lib/features/monetization/data/services/web_premium_service.dart` | `streamWebPremium` Firestore stream |
| `test/features/monetization/domain/paywall_web_guard_test.dart` | Guard unit tests |
| `test/features/monetization/domain/premium_limit_test.dart` | Catalog unit tests |
| `test/features/monetization/data/web_premium_service_test.dart` | `fake_cloud_firestore` stream tests |

### Modified files

| Path | Change |
|---|---|
| `lib/features/monetization/presentation/screens/paywall_screen.dart` | Web guard in `initState` + `ref.listen`; catalog-driven benefit rows; invalidate `isPremiumProvider` after Paystack launch |
| `lib/features/monetization/presentation/providers/subscription_provider.dart` | `IsPremium.build()` web branch → `_buildFromFirestore` |
| `test/features/monetization/presentation/screens/paywall_screen_test.dart` | Copy assertions for catalog rows |
| `docs/FREEMIUM_MODEL.md` | Real limits sync |

---

# Phase 1 — Pure foundations (TDD)

## Task 1: `PaywallWebGuard` pure functions + tests

**Files:**
- Create: `lib/features/monetization/domain/services/paywall_web_guard.dart`
- Test: `test/features/monetization/domain/paywall_web_guard_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/monetization/domain/services/paywall_web_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldFetchOfferings', () {
    test('web never fetches RevenueCat offerings', () {
      expect(shouldFetchOfferings(isWeb: true), isFalse);
    });

    test('native fetches offerings', () {
      expect(shouldFetchOfferings(isWeb: false), isTrue);
    });
  });

  group('shouldShowPaywallErrorSnackBar', () {
    test('web suppresses error snackbars regardless of error', () {
      expect(
        shouldShowPaywallErrorSnackBar(isWeb: true, error: 'RevenueCat not configured'),
        isFalse,
      );
    });

    test('native surfaces a non-null error', () {
      expect(
        shouldShowPaywallErrorSnackBar(isWeb: false, error: 'Purchase failed'),
        isTrue,
      );
    });

    test('native stays quiet when there is no error', () {
      expect(shouldShowPaywallErrorSnackBar(isWeb: false, error: null), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/monetization/domain/paywall_web_guard_test.dart`
Expected: FAIL with "Target of URI doesn't exist: '...paywall_web_guard.dart'"

- [ ] **Step 3: Implement the guard**

```dart
/// Pure web-vs-native paywall decisions.
///
/// RevenueCat is never configured on web (`revenue_cat_repository.dart:29-34`
/// early-returns; `AppConfig.getRevenueCatApiKey('web')` always returns ''),
/// so `getOfferings()` would only produce the 'RevenueCat not configured'
/// error. Web purchases go through external Paystack pages instead.
/// Extracted as pure functions because `kIsWeb` is compile-time and cannot
/// be faked in widget tests.
library;

/// Whether the RevenueCat offering fetch should run on this platform.
bool shouldFetchOfferings({required bool isWeb}) => !isWeb;

/// Whether a paywall state error should surface as a SnackBar.
/// Errors on web are RevenueCat leftovers; the Paystack page reports its
/// own failures.
bool shouldShowPaywallErrorSnackBar({required bool isWeb, String? error}) =>
    !isWeb && error != null;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/monetization/domain/paywall_web_guard_test.dart`
Expected: PASS — 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/monetization/domain/services/paywall_web_guard.dart test/features/monetization/domain/paywall_web_guard_test.dart
git commit -m "feat(monetization): add PaywallWebGuard pure functions (no RC fetch / no error snackbar on web)"
```

---

## Task 2: Wire the web guard into `PaywallScreen`

**Files:**
- Modify: `lib/features/monetization/presentation/screens/paywall_screen.dart`

- [ ] **Step 1: Gate the offering fetch in `initState`**

`paywall_screen.dart:33-35` — replace:

```dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paywallControllerProvider.notifier).fetchOfferings();
    });
```

with:

```dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Web uses Paystack pages; RevenueCat is never configured there, so
      // fetching would only surface a 'RevenueCat not configured' error.
      if (shouldFetchOfferings(isWeb: kIsWeb)) {
        ref.read(paywallControllerProvider.notifier).fetchOfferings();
      }
    });
```

- [ ] **Step 2: Suppress the error SnackBar on web**

`paywall_screen.dart:54-58` — replace:

```dart
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
```

with:

```dart
      if (shouldShowPaywallErrorSnackBar(isWeb: kIsWeb, error: next.error) &&
          next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
```

- [ ] **Step 3: Add the import**

Add with the other imports at the top of `paywall_screen.dart`:

```dart
import 'package:emerge_app/features/monetization/domain/services/paywall_web_guard.dart';
```

(`kIsWeb` already comes from the existing `package:flutter/foundation.dart` import, line 3.)

- [ ] **Step 4: Verify**

Run: `dart analyze lib/features/monetization/presentation/screens/paywall_screen.dart lib/features/monetization/domain/services/paywall_web_guard.dart`
Expected: 0 issues.

Run: `flutter test test/features/monetization/presentation/screens/paywall_screen_test.dart`
Expected: PASS — 2 tests (native path unchanged; the mocked controller never sets `error`, and tests run with `kIsWeb == false`).

- [ ] **Step 5: Commit**

```bash
git add lib/features/monetization/presentation/screens/paywall_screen.dart
git commit -m "fix(monetization): web paywall skips offering fetch and suppresses RC error snackbar"
```

---

## Task 3: `LimitsCatalog` pure model + tests

**Files:**
- Create: `lib/features/monetization/domain/models/premium_limit.dart`
- Test: `test/features/monetization/domain/premium_limit_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/domain/models/premium_limit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LimitsCatalog', () {
    test('lists exactly the four enforced limits', () {
      expect(
        LimitsCatalog.all.map((l) => l.featureKey).toList(),
        ['habits', 'clubs', 'coachAsk', 'themes'],
      );
    });

    test('every entry is fully copy-able', () {
      for (final limit in LimitsCatalog.all) {
        expect(limit.featureKey, isNotEmpty);
        expect(limit.unit, isNotEmpty);
        expect(limit.paywallTitle, isNotEmpty);
        expect(limit.paywallSubtitle, isNotEmpty);
        expect(limit.enforcedBy, isNotEmpty);
        expect(limit.freeValue, greaterThan(0));
      }
    });

    test('enforced values are 5 habits / 1 club / 3 coach asks / 1 theme', () {
      expect(LimitsCatalog.habits.freeValue, 5);
      expect(LimitsCatalog.clubs.freeValue, 1);
      expect(LimitsCatalog.coachAsk.freeValue, 3);
      expect(LimitsCatalog.themes.freeValue, 1);
    });

    test('habits matches the code default free habit limit', () {
      // Guardrail: Remote Config default and the catalog must not diverge.
      expect(LimitsCatalog.habits.freeValue, kDefaultFreeHabitLimit);
    });

    test('themes has no premium dialog and is not premium-bypassed', () {
      expect(LimitsCatalog.themes.dialogCopyKey, isNull);
      expect(LimitsCatalog.themes.premiumBypasses, isFalse);
    });

    test('dialog keys exist for the dialog-backed limits only', () {
      expect(LimitsCatalog.habits.dialogCopyKey, 'habit');
      expect(LimitsCatalog.clubs.dialogCopyKey, 'club');
      expect(LimitsCatalog.coachAsk.dialogCopyKey, 'coachAsk');
    });

    test('forFeature finds known keys and misses unknown ones', () {
      expect(LimitsCatalog.forFeature('habits'), same(LimitsCatalog.habits));
      expect(LimitsCatalog.forFeature('themes'), same(LimitsCatalog.themes));
      expect(LimitsCatalog.forFeature('does_not_exist'), isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/monetization/domain/premium_limit_test.dart`
Expected: FAIL with "Target of URI doesn't exist: '...premium_limit.dart'"

- [ ] **Step 3: Implement the model**

```dart
/// One enforced free-tier limit, as listed on the paywall and in
/// docs/FREEMIUM_MODEL.md. Deliberately UI-free: the presentation layer
/// resolves icons/colors/dialog enums from [featureKey] / [dialogCopyKey].
class FreeTierLimit {
  /// Stable key: 'habits' | 'clubs' | 'coachAsk' | 'themes'.
  final String featureKey;

  /// Free-tier cap value (habits=5, clubs=1, coachAsk=3/day, themes=1).
  final int freeValue;

  /// Human unit for the free value, e.g. 'active habits'.
  final String unit;

  /// Whether premium removes this cap. False for themes: SP-C locks them
  /// as 'coming soon' for everyone — not a premium bypass.
  final bool premiumBypasses;

  /// Key into `PremiumLimitType` (premium_limit_dialog.dart) or null when
  /// the limit has no premium dialog (themes). The dialog enum lives in the
  /// presentation layer; the catalog only carries the key string.
  final String? dialogCopyKey;

  /// Paywall offer headline, e.g. 'UNLIMITED HABITS'.
  final String paywallTitle;

  /// Honest paywall offer subtitle, e.g. 'Free: 5 active habits · Premium: no cap'.
  final String paywallSubtitle;

  /// Who enforces this: 'remote_config' | 'code' | 'SP-C'.
  final String enforcedBy;

  const FreeTierLimit({
    required this.featureKey,
    required this.freeValue,
    required this.unit,
    required this.premiumBypasses,
    required this.dialogCopyKey,
    required this.paywallTitle,
    required this.paywallSubtitle,
    required this.enforcedBy,
  });
}

/// Single source of truth for every enforced free-tier limit.
///
/// Drives the paywall offer copy and must stay in sync with
/// docs/FREEMIUM_MODEL.md. Runtime enforcement keeps its own
/// configuration (Remote Config `free_habit_limit`, CoachAskQuota, club
/// join gate); the catalog is the declared product surface.
class LimitsCatalog {
  static const FreeTierLimit habits = FreeTierLimit(
    featureKey: 'habits',
    freeValue: 5,
    unit: 'active habits',
    premiumBypasses: true,
    dialogCopyKey: 'habit',
    paywallTitle: 'UNLIMITED HABITS',
    paywallSubtitle: 'Free: 5 active habits · Premium: no cap',
    enforcedBy: 'remote_config',
  );

  static const FreeTierLimit clubs = FreeTierLimit(
    featureKey: 'clubs',
    freeValue: 1,
    unit: 'club',
    premiumBypasses: true,
    dialogCopyKey: 'club',
    paywallTitle: 'UNLIMITED CLUBS',
    paywallSubtitle: 'Free: 1 club · Premium: no cap',
    enforcedBy: 'code',
  );

  static const FreeTierLimit coachAsk = FreeTierLimit(
    featureKey: 'coachAsk',
    freeValue: 3,
    unit: 'coach asks/day',
    premiumBypasses: true,
    dialogCopyKey: 'coachAsk',
    paywallTitle: 'UNLIMITED COACH ASKS',
    paywallSubtitle: 'Free: 3 asks/day · Premium: unlimited',
    enforcedBy: 'code',
  );

  /// SP-C locks 5 of 6 themes as 'coming soon'; nebula is the free theme.
  static const FreeTierLimit themes = FreeTierLimit(
    featureKey: 'themes',
    freeValue: 1,
    unit: 'world theme',
    premiumBypasses: false,
    dialogCopyKey: null,
    paywallTitle: 'MORE WORLD THEMES',
    paywallSubtitle: 'Free: 1 theme · 5 more coming soon',
    enforcedBy: 'SP-C',
  );

  static const List<FreeTierLimit> all = [habits, clubs, coachAsk, themes];

  static FreeTierLimit? forFeature(String featureKey) {
    for (final limit in all) {
      if (limit.featureKey == featureKey) return limit;
    }
    return null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/monetization/domain/premium_limit_test.dart`
Expected: PASS — 7 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/monetization/domain/models/premium_limit.dart test/features/monetization/domain/premium_limit_test.dart
git commit -m "feat(monetization): add LimitsCatalog (habits 5, clubs 1, coach asks 3/day, themes 1)"
```

---

## Task 4: Paywall offer copy from `LimitsCatalog`

**Files:**
- Modify: `lib/features/monetization/presentation/screens/paywall_screen.dart`
- Modify: `test/features/monetization/presentation/screens/paywall_screen_test.dart`

- [ ] **Step 1: Write the failing widget test**

Replace the contents of `test/features/monetization/presentation/screens/paywall_screen_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/monetization/presentation/providers/paywall_provider.dart';
import 'package:emerge_app/features/monetization/presentation/screens/paywall_screen.dart';

final loadingState = const PaywallState(isLoading: true);
final loadedState = const PaywallState(isLoading: false, offerings: null);

class _MockPaywallController extends PaywallController {
  final PaywallState _state;
  _MockPaywallController(this._state);

  @override
  PaywallState build() => _state;

  @override
  Future<void> fetchOfferings() async {}
}

Widget createTest(PaywallState state) {
  return ProviderScope(
    overrides: [
      paywallControllerProvider.overrideWith(
        () => _MockPaywallController(state),
      ),
    ],
    child: const MaterialApp(
      home: PaywallScreen(),
    ),
  );
}

void main() {
  testWidgets('shows Go Beyond the 5 headline and premium benefits',
      (tester) async {
    await tester.pumpWidget(createTest(loadingState));
    await tester.pump();

    expect(find.text('Go Beyond the 5'), findsOneWidget);
    expect(find.text('UNLIMITED HABITS'), findsOneWidget);
    expect(find.text('UNLIMITED CLUBS'), findsOneWidget);
    expect(find.text('UNLIMITED COACH ASKS'), findsOneWidget);
    expect(find.text('MORE WORLD THEMES'), findsOneWidget);
    expect(find.text('Free: 5 active habits · Premium: no cap'), findsOneWidget);
    expect(find.text('PREMIUM INSIGHTS'), findsOneWidget);
    expect(find.text('EXCLUSIVE STYLE'), findsOneWidget);
    expect(find.text('Restore'), findsOneWidget);
  });

  testWidgets('shows no packages available when offerings null',
      (tester) async {
    await tester.pumpWidget(createTest(loadedState));
    await tester.pump();

    expect(
      find.text('No subscription packages available currently.'),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/monetization/presentation/screens/paywall_screen_test.dart`
Expected: FAIL — `'UNLIMITED HABITS'` not found (screen still renders the old `'UNLIMITED'` block).

- [ ] **Step 3: Replace the first benefit block with catalog-driven rows**

`paywall_screen.dart:107-113` — replace the block **and** the `const Gap(12),` that follows it (line 113, which currently separates the old block from `PREMIUM INSIGHTS`):

```dart
                        const _BenefitBlock(
                          icon: Icons.lock_open,
                          title: 'UNLIMITED',
                          subtitle: 'Habits, clubs, themes',
                          color: Colors.cyanAccent,
                        ),
                        const Gap(12),
```

with:

```dart
                        const _BenefitBlock(
                          icon: Icons.lock_open,
                          title: LimitsCatalog.habits.paywallTitle,
                          subtitle: LimitsCatalog.habits.paywallSubtitle,
                          color: Colors.cyanAccent,
                        ),
                        const Gap(12),
                        const _BenefitBlock(
                          icon: Icons.groups,
                          title: LimitsCatalog.clubs.paywallTitle,
                          subtitle: LimitsCatalog.clubs.paywallSubtitle,
                          color: Colors.cyanAccent,
                        ),
                        const Gap(12),
                        const _BenefitBlock(
                          icon: Icons.auto_awesome,
                          title: LimitsCatalog.coachAsk.paywallTitle,
                          subtitle: LimitsCatalog.coachAsk.paywallSubtitle,
                          color: Colors.cyanAccent,
                        ),
                        const Gap(12),
                        const _BenefitBlock(
                          icon: Icons.public,
                          title: LimitsCatalog.themes.paywallTitle,
                          subtitle: LimitsCatalog.themes.paywallSubtitle,
                          color: Colors.cyanAccent,
                        ),
```

(exactly four blocks separated by single `const Gap(12)` spacers; no trailing gap — the next sibling `_BenefitBlock(PREMIUM INSIGHTS)` keeps its own existing `Gap(12)`.)

- [ ] **Step 4: Add the import**

```dart
import 'package:emerge_app/features/monetization/domain/models/premium_limit.dart';
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/monetization/presentation/screens/paywall_screen_test.dart`
Expected: PASS — 2 tests.

Run: `dart analyze lib/features/monetization/presentation/screens/paywall_screen.dart`
Expected: 0 issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/monetization/presentation/screens/paywall_screen.dart test/features/monetization/presentation/screens/paywall_screen_test.dart
git commit -m "feat(monetization): paywall benefits list real limits from LimitsCatalog"
```

---

## Task 5: Sync `docs/FREEMIUM_MODEL.md` with the real limits

**Files:**
- Modify: `docs/FREEMIUM_MODEL.md`

- [ ] **Step 1: Fix the feature matrix (numbers + entitlement id)**

In the Feature Comparison Matrix (`docs/FREEMIUM_MODEL.md:13-23`):
1. Row **Habit Capacity**: change `Max 3 Active Habits` → `Max 5 Active Habits` and the rationale's "3 is enough to start" → "5 is enough to start".
2. Row **Social**: change `Join Public Tribes` → `Join 1 Tribe` (free) vs `Unlimited Tribes` (premium) — matches the enforced club gate.
3. Add rows after **Social**:
   - **AI Coach** (replace the existing vague "Basic Chat (Limited Context)" row): `3 Coach Asks / Day` vs `Unlimited Coach Asks` — "Grounded in the user's own habit data".
   - **World Themes**: `1 Theme (Cosmic Nebula)` vs `All 6 Themes` (premium) — "5 more themes coming soon (SP-C)".
4. In the Technical Implementation / RevenueCat section (`:27-32`): change **Entitlement ID** `pro_access` → `premium` (matches `revenue_cat_repository.dart:18-19`).

- [ ] **Step 2: Replace the Paywall Triggers list with the real gates**

`docs/FREEMIUM_MODEL.md:47-50` — replace the three trigger bullets with:

```
### Paywall Locations (implemented gates)
*   **Trigger 1:** Creating a 6th active habit (free limit = 5; Remote Config `free_habit_limit`, default 5; onboarding/anchor habits bypass).
*   **Trigger 2:** Joining a 2nd club (free limit = 1; `clubJoinBlockedByFreeTier` in `tribes_provider.dart`).
*   **Trigger 3:** 4th coach ask in a day (free limit = 3/day; `CoachAskQuota`).
*   **Not a paywall trigger:** World themes — locked as "coming soon" (SP-C), 1 theme free.
*   **Web:** Paywall uses external Paystack Payment Pages (₦15,000/yr, ₦2,500/mo); premium activates via the `paystackWebhook` → `users/{uid}.isPremium` Firestore flag streamed by `isPremiumProvider`.
```

- [ ] **Step 3: Verify no stale "3 Active Habits" or "4th Habit" references remain**

Run: `grep -n "3 Active Habits\|4th Habit\|pro_access" docs/FREEMIUM_MODEL.md`
Expected: nothing.

- [ ] **Step 4: Commit**

```bash
git add docs/FREEMIUM_MODEL.md
git commit -m "docs: FREEMIUM_MODEL sync — 5-habit limit, real gates, premium entitlement id"
```

---

# Phase 2 — Web premium activation (TDD)

## Task 6: `streamWebPremium` + `IsPremium` web branch

**Files:**
- Create: `lib/features/monetization/data/services/web_premium_service.dart`
- Create: `test/features/monetization/data/web_premium_service_test.dart`
- Modify: `lib/features/monetization/presentation/providers/subscription_provider.dart`

- [ ] **Step 1: Write the failing stream test**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/monetization/data/services/web_premium_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emits false while the doc is missing, true after the webhook write',
      () async {
    final fdb = FakeFirebaseFirestore();
    final values = <bool>[];
    final sub = streamWebPremium(fdb, 'uid-1').listen(values.add);

    await fdb
        .collection('users')
        .doc('uid-1')
        .set({'isPremium': true, 'premium_since': Timestamp.now()});
    await pumpEventQueue();

    expect(values, [false, true]);
    await sub.cancel();
  });

  test('emits false again when the doc flips back to non-premium', () async {
    final fdb = FakeFirebaseFirestore();
    await fdb.collection('users').doc('uid-1').set({'isPremium': true});
    final values = <bool>[];
    final sub = streamWebPremium(fdb, 'uid-1').listen(values.add);

    await fdb.collection('users').doc('uid-1').update({'isPremium': false});
    await pumpEventQueue();

    expect(values.first, isTrue);
    expect(values.last, isFalse);
    await sub.cancel();
  });

  test('non-boolean isPremium values are treated as not premium', () async {
    final fdb = FakeFirebaseFirestore();
    await fdb.collection('users').doc('uid-1').set({'isPremium': 'yes'});
    final values = <bool>[];
    final sub = streamWebPremium(fdb, 'uid-1').listen(values.add);
    await pumpEventQueue();

    expect(values.last, isFalse);
    await sub.cancel();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/monetization/data/web_premium_service_test.dart`
Expected: FAIL with "Target of URI doesn't exist: '...web_premium_service.dart'"

- [ ] **Step 3: Implement the stream helper**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Streams web premium status from the `users/{uid}` Firestore document.
///
/// The Paystack webhook (`functions/src/payments/paystack.ts:129-136`)
/// writes `users/{uid}.isPremium = true` (+ `premium_since`,
/// `identity_type`) on charge.success. Existing rules
/// (`firestore.rules:283-290`, owner-read of `users/{userId}`) already
/// permit this read — no rules change needed. Emits `false` while the
/// document is missing or `isPremium` is not exactly `true`.
Stream<bool> streamWebPremium(FirebaseFirestore firestore, String uid) {
  return firestore
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => snap.data()?['isPremium'] == true);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/monetization/data/web_premium_service_test.dart`
Expected: PASS — 3 tests.

- [ ] **Step 5: Add the web branch to `IsPremium.build()`**

`lib/features/monetization/presentation/providers/subscription_provider.dart`:

1. Add imports (top of file):

```dart
import 'package:emerge_app/features/monetization/data/services/web_premium_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
```

2. In `build()` (line 22), after the `if (user == null) return false;` guard (line 27) and **before** the `if (user.id.isNotEmpty) { await repo.initialize(uid: user.id); }` block (lines 29-31), insert:

```dart
    // Web: RevenueCat is never configured (revenue_cat_repository.dart:29-34).
    // Premium is read from the Paystack-written `users/{uid}.isPremium` flag
    // instead (functions/src/payments/paystack.ts:129-136).
    if (kIsWeb) {
      return _buildFromFirestore(user.id);
    }
```

3. Add the private method after `build()` (before `_cachePremiumStatus`):

```dart
  /// Web premium status from the `users/{uid}` Firestore doc.
  ///
  /// Keeps a live snapshot subscription (the keepAlive provider holds it for
  /// the app session) so the Paystack webhook update lands without a rebuild,
  /// and returns the current doc value as the initial result. On read
  /// failure, falls back to the existing 7-day prefs cache (which is only
  /// ever written on native) and otherwise reports false — never block.
  Future<bool> _buildFromFirestore(String uid) async {
    final firestore = ref.watch(firestoreProvider);
    final sub = streamWebPremium(firestore, uid).listen((isPremium) {
      state = AsyncValue.data(isPremium);
    });
    ref.onDispose(sub.cancel);
    try {
      final snap = await firestore.collection('users').doc(uid).get();
      return snap.data()?['isPremium'] == true;
    } catch (e) {
      AppLogger.w('Web premium Firestore check failed', error: e);
      final cached = await _readCachedPremiumStatus();
      return cached ?? false;
    }
  }
```

(`firestoreProvider` is already importable via the existing `auth_providers.dart` import, line 3.)

- [ ] **Step 6: Verify**

Run: `dart analyze lib/features/monetization/presentation/providers/subscription_provider.dart lib/features/monetization/data/services/web_premium_service.dart`
Expected: 0 issues.

Run: `flutter test test/features/monetization/data/web_premium_service_test.dart test/features/monetization/presentation/providers/daily_login_bonus_test.dart`
Expected: PASS — 3 + existing daily-login-bonus tests (native path unchanged; `daily_login_bonus_test.dart` overrides `isPremiumProvider` with a fake).

- [ ] **Step 7: Commit**

```bash
git add lib/features/monetization/data/services/web_premium_service.dart lib/features/monetization/presentation/providers/subscription_provider.dart test/features/monetization/data/web_premium_service_test.dart
git commit -m "feat(monetization): web premium activates via users/{uid}.isPremium Firestore stream"
```

---

## Task 7: Invalidate `isPremiumProvider` after Paystack checkout + final verification

**Files:**
- Modify: `lib/features/monetization/presentation/screens/paywall_screen.dart`

- [ ] **Step 1: Invalidate on return from the Paystack page**

`paywall_screen.dart:295-300` — replace:

```dart
  Future<void> _openPaystackPage(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
```

with:

```dart
  Future<void> _openPaystackPage(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } finally {
      // The webhook (`users/{uid}.isPremium`) normally flips the live
      // Firestore stream within seconds; re-running the provider also
      // covers races where the doc was written between stream attach and
      // this return.
      ref.invalidate(isPremiumProvider);
    }
  }
```

(Add `import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';` to `paywall_screen.dart` — it currently imports only `paywall_provider.dart`.)

- [ ] **Step 2: Verify**

Run: `dart analyze lib/features/monetization/presentation/screens/paywall_screen.dart`
Expected: 0 issues.

Run: `flutter test test/features/monetization/presentation/screens/paywall_screen_test.dart`
Expected: PASS — 2 tests (mock controller; `isPremiumProvider` invalidation is inert in this harness).

- [ ] **Step 3: Whole-change verification**

Run: `dart analyze lib`
Expected: 0 issues **beyond the pre-flight baseline** (baseline recorded in Pre-flight note 2).

Run: `flutter test test/features/monetization`
Expected: PASS (SP-A's suite already covers `coach_ask_quota_test`, `coach_ask_quota_provider_test`, `daily_login_bonus_test`, `paywall_provider_test`, `premium_limit_dialog_test` — none should be touched by SP-B).

- [ ] **Step 4: Commit**

```bash
git add lib/features/monetization/presentation/screens/paywall_screen.dart
git commit -m "feat(monetization): invalidate isPremiumProvider after Paystack checkout returns"
```

- [ ] **Step 5: Manual web smoke checklist (human, device/browser)**

1. Open the paywall on web → **no** "RevenueCat not configured" SnackBar; both Paystack buttons render; Restore button absent.
2. Tap the yearly Paystack page, complete a test payment, return to the app, close the paywall.
3. Within a few seconds, create a 6th habit → succeeds (premium active); join a 2nd club → succeeds; coach asks show "Unlimited coach asks".
4. Repeat step 1 on a fresh session to confirm the SnackBar never appears.
5. Native (Android emulator): paywall still fetches offerings, Restore button present, error SnackBar behavior unchanged.

---

## Commits (expected, in order)

| Task | Summary |
|---|---|
| T1 | `feat(monetization): add PaywallWebGuard pure functions (no RC fetch / no error snackbar on web)` |
| T2 | `fix(monetization): web paywall skips offering fetch and suppresses RC error snackbar` |
| T3 | `feat(monetization): add LimitsCatalog (habits 5, clubs 1, coach asks 3/day, themes 1)` |
| T4 | `feat(monetization): paywall benefits list real limits from LimitsCatalog` |
| T5 | `docs: FREEMIUM_MODEL sync — 5-habit limit, real gates, premium entitlement id` |
| T6 | `feat(monetization): web premium activates via users/{uid}.isPremium Firestore stream` |
| T7 | `feat(monetization): invalidate isPremiumProvider after Paystack checkout returns` |

## Deferred (explicitly out of scope)

Custom-claims sync from the Paystack webhook (SP-H), `generateAiRecap` gate fix reading `user_stats.isPremium` (SP-H), theme lock UI (SP-C), club join limit changes (SP-G), invite codes (SP-E), consumables API cleanup, `PremiumThemePreview` wiring/deletion, `PaystackCheckoutScreen`/`PaystackPaymentRepository` reuse or deletion.
