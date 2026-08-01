# SP-B: Paywall Web Fix, Web Premium Activation, Premium Limits/Offers Framework — Design Spec

> **Predecessor:** SP-A (`2026-08-01-narrator-coach-tutorials-premium-limits-design.md`) delivered the CoachAskQuota (3/day), `PremiumLimitType` + `showPremiumLimitDialog`, and the node-guide system. SP-C (`2026-08-01-sp-c-theme-lock-design.md`) delivers the theme lock ("coming soon" on 5 of 6 world themes) and is **committed but not yet implemented** as of this spec.
>
> **Scope:** Documentation/design only. No code changes in this file.

---

## 1. Goals

1. **Kill the web "RevenueCat not configured" SnackBar.** On web, `PaywallScreen.initState` unconditionally calls `fetchOfferings()`; the RevenueCat repository is never configured on web (`initialize()` early-returns, `getRevenueCatApiKey('web')` always returns `''`), so `getOfferings()` returns `Left('RevenueCat not configured')` which the screen surfaces as a red SnackBar. Web must not fetch offerings at all, and must never surface the RevenueCat error.
2. **Activate premium on web.** The Paystack webhook already writes `users/{uid}.isPremium = true` to Firestore, but no Dart code reads it — web premium never activates. Make Firestore `users/{uid}.isPremium` the web source of truth streamed into `isPremiumProvider`, so habit caps, club gates, coach-ask quota, and ads all unlock after a web purchase.
3. **Turn the SP-A quota framework into a limits framework.** Add a pure `LimitsCatalog` — the single source of truth for every enforced free-tier limit (habits=5, clubs=1, coach asks=3/day, themes=1) — driving paywall offer copy and kept in sync with `docs/FREEMIUM_MODEL.md`.
4. **Make paywall/offers copy honest and real.** Replace "UNLIMITED — Habits, clubs, themes" with catalog-driven rows listing the real limits; fix `docs/FREEMIUM_MODEL.md` (currently claims "Max 3 Active Habits" while the code enforces 5).

---

## 2. Recorded decisions

### D1 — Web SnackBar fix: guard the fetch + suppress the error (both)

- **(a) Primary:** skip `fetchOfferings()` on web in `PaywallScreen.initState` (paywall_screen.dart:33-35 currently calls it unconditionally via a post-frame callback).
- **(b) Defense-in-depth:** suppress the error SnackBar on web in the `ref.listen` (paywall_screen.dart:50-58) so that even if some future path sets `state.error` on web, the user never sees a RevenueCat-branded error.
- Both decisions are routed through a **pure, testable guard** (see D6) because `kIsWeb` is a compile-time constant that cannot be faked in widget tests.
- **Accepted behavior:** the paywall's auto-pop on `isSuccess` (paywall_screen.dart:50-53) never fires on web — the Paystack page is opened as an external application, so the Flutter app receives no callback. Web users close the paywall manually. This is already the de-facto behavior and is acceptable; do not attempt deep-link recovery in SP-B. Note: on web, `_buildPurchaseSection` returns `_buildPaystackPurchase()` before any loading/error inspection, so skipping the fetch does not strand the screen in a spinner.

### D2 — Web premium source of truth: `users/{uid}.isPremium` via Firestore stream

- Extend `IsPremium.build()` (subscription_provider.dart:16-127): on `kIsWeb`, **branch before** the RevenueCat retry loop and instead:
  - subscribe to `users/{uid}` document snapshots (stream helper, see D8) and push `isPremium == true` into `state` on every emission;
  - return the current doc value as the initial result;
  - on Firestore read failure, fall back to the existing 7-day shared_prefs cache (`_readCachedPremiumStatus()`, subscription_provider.dart:105-121), else `false`. No cache *write* on web — the live stream makes caching unnecessary.
- Existing Firestore rules already allow it: `firestore.rules:283-290` — `match /users/{userId} { allow read: if isOwner(userId); ... }`. **Verified — no rules change needed.**
- Native path (Android/iOS) is **unchanged**: RevenueCat with 3 retries + realtime stream + custom-claims fallback + 7-day cache.
- Ensure `isPremiumProvider` is invalidated after a Paystack checkout returns (see D10). The stream normally self-updates within seconds of the webhook landing; invalidation is defense-in-depth.
- **Noted alternative (deferred to SP-H):** server-side sync of the Paystack webhook into Firebase custom claims (`activeEntitlements`) — would make the existing claims fallback path (subscription_provider.dart:66-80) work on web too. Out of scope here; the Firestore read is cheaper, needs no function change, and works under existing rules.

### D3 — Limits framework: `LimitsCatalog`, do NOT over-abstract `CoachAskQuota`

- Keep `CoachAskQuota` exactly as SP-A delivered it (pure 3/day quota with premium bypass + rollover). No generalization, no interface extraction.
- Add a **pure** `LimitsCatalog` (see D7) listing every enforced limit:
  | featureKey | freeValue | unit | premiumBypasses | dialogCopyKey | enforcedBy |
  |---|---|---|---|---|---|
  | `habits` | 5 | active habits | true | `habit` | `remote_config` (default 5; runtime can override) |
  | `clubs` | 1 | club | true | `club` | `code` (tribes_provider.dart:363-396) |
  | `coachAsk` | 3 | coach asks/day | true | `coachAsk` | `code` (CoachAskQuota) |
  | `themes` | 1 | world theme | false | *(null — no dialog)* | SP-C ("coming soon" lock; nebula is the free theme) |
- `PremiumLimitType` **stays the dialog enum** in `lib/features/monetization/presentation/widgets/premium_limit_dialog.dart:19` — do **not** add a `theme` value (SP-C deliberately shows a "coming soon" snackbar, **not** a paywall dialog — verified in `2026-08-01-sp-c-theme-lock-design.md` D1/§7). The catalog references dialog copy by **key string** (`dialogCopyKey`), keeping the domain model free of presentation-layer imports.
- The catalog is the single source for: paywall offer copy (D4), `FREEMIUM_MODEL.md` sync, and future gates (SP-C themes, SP-G clubs).

### D4 — Offers copy: real limits, honest themes

- Replace the paywall's first benefit block — `'UNLIMITED' / 'Habits, clubs, themes'` (paywall_screen.dart:107-112) — with **four catalog-driven rows** (one per limit):
  - `UNLIMITED HABITS` — "Free: 5 active habits · Premium: no cap"
  - `UNLIMITED CLUBS` — "Free: 1 club · Premium: no cap"
  - `UNLIMITED COACH ASKS` — "Free: 3 asks/day · Premium: unlimited"
  - `MORE WORLD THEMES` — "Free: 1 theme · 5 more coming soon"
- The `PREMIUM INSIGHTS` and `EXCLUSIVE STYLE` blocks stay unchanged (paywall_screen.dart:113-127). Headline "Go Beyond the 5" (line 86) already matches the real habit limit — keep it.
- The themes row is honest about SP-C: themes are "coming soon", not a purchasable premium perk yet. **Coordinate with SP-C** (its lock ships `nebula` free + 5 locked); if SP-C's unlocked set ever changes, the catalog's `themes` entry and this copy change in lockstep.
- Sync `docs/FREEMIUM_MODEL.md`: matrix "Max 3 Active Habits" → 5 (line 15), add the club/coach-ask/theme rows that are actually enforced, correct the entitlement id (`pro_access` → `premium`, matching revenue_cat_repository.dart:18-19), and replace the paywall-triggers list (lines 48-50) with the real gates (habit-create/persist gate, club join, coach-ask quota; themes → "coming soon" not paywall).

### D5 — Out of scope for SP-B

Theme lock UI (SP-C), tribe/club join limit changes (SP-G), invite codes (SP-E), all `functions/` + `firestore.rules` changes (SP-H — including the optional custom-claims sync from D2, and fixing the broken `generateAiRecap` gate in `functions/src/ai_recap.ts:29-34` which reads `user_stats.isPremium` that nothing writes). Also out: consumables API cleanup (zero callers), wiring/deleting the unused `PremiumThemePreview` widget, deleting the unused `PaystackCheckoutScreen`/`PaystackPaymentRepository` path, ad-manager changes (web-acts-premium for ads is intentional).

---

## 3. Architecture

```
                         ┌───────────────────────────────┐
  PaywallScreen (web)    │  PaywallWebGuard (pure)       │
  initState ───────────► │  shouldFetchOfferings(isWeb)  │──► skip fetch on web
  ref.listen(error) ───► │  shouldShowPaywallErrorSnack… │──► suppress on web
                         └───────────────────────────────┘

  IsPremium.build() (keepAlive AsyncNotifier)
    ├─ kIsWeb ──► streamWebPremium(firestore, uid)  ──► users/{uid}.isPremium  (web source of truth)
    │                 (data layer, fake_cloud_firestore-testable)
    └─ native ──► RevenueCat retry + stream + claims + 7-day cache  (UNCHANGED)

  LimitsCatalog (pure, const) ──► paywall benefit rows ──► docs/FREEMIUM_MODEL.md
      habits=5 / clubs=1 / coachAsk=3 / themes=1
```

Layering rules: `LimitsCatalog` and `PaywallWebGuard` are pure (no Flutter imports except `foundation` for the guard's `bool` signature — no, the guard takes plain `bool`s, so it needs **no** Flutter import at all). `streamWebPremium` is the only Firestore-touching piece and lives in the data layer so it can be unit-tested with `fake_cloud_firestore` (already a dev dependency, pubspec.yaml:99). The `kIsWeb` branching stays in the provider/screen where it cannot be faked — that is exactly why the testable surface is extracted into pure functions.

---

## 4. Component specs

### 4.1 `PaywallWebGuard` (new, pure)

`lib/features/monetization/domain/services/paywall_web_guard.dart`

```dart
/// Whether the RevenueCat offering fetch should run on this platform.
/// Web uses Paystack pages and RevenueCat is never configured there
/// (revenue_cat_repository.dart:29-34), so fetching would only produce
/// the 'RevenueCat not configured' error.
bool shouldFetchOfferings({required bool isWeb}) => !isWeb;

/// Whether a paywall state error should surface as a SnackBar.
/// Errors on web are always RevenueCat leftovers; the Paystack path
/// reports failures inside the Paystack page itself.
bool shouldShowPaywallErrorSnackBar({required bool isWeb, String? error}) =>
    !isWeb && error != null;
```

- Consumed by `PaywallScreen`:
  - `initState` post-frame callback (paywall_screen.dart:33-35): `if (shouldFetchOfferings(isWeb: kIsWeb)) { ...fetchOfferings(); }`
  - `ref.listen` (paywall_screen.dart:54-58): gate the SnackBar with `shouldShowPaywallErrorSnackBar(isWeb: kIsWeb, error: next.error)`.
- On native both guards pass → zero behavior change.

### 4.2 `streamWebPremium` (new, data layer)

`lib/features/monetization/data/services/web_premium_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Streams web premium status from the `users/{uid}` Firestore document.
///
/// The Paystack webhook (`functions/src/payments/paystack.ts:129-136`)
/// writes `users/{uid}.isPremium = true` (+ `premium_since`,
/// `identity_type`) on charge.success. Existing rules
/// (`firestore.rules:283-290`, owner-read of `users/{userId}`) permit this
/// read — no rules change needed. Emits `false` while the document is
/// missing or `isPremium` is not exactly `true`.
Stream<bool> streamWebPremium(FirebaseFirestore firestore, String uid) {
  return firestore
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => snap.data()?['isPremium'] == true);
}
```

### 4.3 `IsPremium` web branch (modified)

`lib/features/monetization/presentation/providers/subscription_provider.dart`

In `build()` (line 22), immediately after the `user == null → false` check and **before** `repo.initialize(...)`:

```dart
if (kIsWeb) {
  return _buildFromFirestore(user.id);
}
```

`_buildFromFirestore(String uid)`:
1. `final firestore = ref.watch(firestoreProvider);` (`auth_providers.dart:63-65`, keepAlive).
2. `streamWebPremium(firestore, uid).listen((isPremium) { state = AsyncValue.data(isPremium); })` + `ref.onDispose(sub.cancel)` — mirrors the existing `premiumStatusStream` pattern (subscription_provider.dart:52-58).
3. `await firestore.collection('users').doc(uid).get()` → return `snap.data()?['isPremium'] == true`.
4. On exception: `AppLogger.w(...)` then `return cached ?? false` via the existing `_readCachedPremiumStatus()` (105-121).

Notes:
- The keepAlive provider holds the stream for the app session; one doc stream is cheap.
- The initial `get()` and the first stream emission may race — both resolve to the same value; the later webhook update arrives via the stream, flipping `state` without a rebuild of the provider.
- No cache *writes* on web; the 7-day cache is read-only fallback there.

### 4.4 `LimitsCatalog` (new, pure)

`lib/features/monetization/domain/models/premium_limit.dart`

```dart
/// One enforced free-tier limit, as listed on the paywall and in
/// docs/FREEMIUM_MODEL.md. Kept deliberately UI-free.
class FreeTierLimit {
  final String featureKey;      // 'habits' | 'clubs' | 'coachAsk' | 'themes'
  final int freeValue;          // 5 | 1 | 3 | 1
  final String unit;            // 'active habits' | 'club' | 'coach asks/day' | 'world theme'
  final bool premiumBypasses;   // true except themes (SP-C "coming soon" lock)
  final String? dialogCopyKey;  // 'habit' | 'club' | 'coachAsk' | null (no dialog for themes)
  final String paywallTitle;    // e.g. 'UNLIMITED HABITS'
  final String paywallSubtitle; // e.g. 'Free: 5 active habits · Premium: no cap'
  final String enforcedBy;      // 'remote_config' | 'code' | 'SP-C'
  const FreeTierLimit({...});
}

class LimitsCatalog {
  static const FreeTierLimit habits = ...;   // 5, dialogCopyKey 'habit'
  static const FreeTierLimit clubs = ...;    // 1, dialogCopyKey 'club'
  static const FreeTierLimit coachAsk = ...; // 3, dialogCopyKey 'coachAsk'
  static const FreeTierLimit themes = ...;   // 1, dialogCopyKey null, premiumBypasses false, enforcedBy 'SP-C'
  static const List<FreeTierLimit> all = [habits, clubs, coachAsk, themes];
  static FreeTierLimit? forFeature(String featureKey) { ... }
}
```

- Individual `static const` fields keep the paywall rows **const-constructible** (no runtime lookup needed in the widget).
- `dialogCopyKey` is a string key (not the enum) so the domain model does not import the presentation-layer `PremiumLimitType`. The dialog enum and its copy remain untouched (D3).
- The catalog's `habits.freeValue` is the *declared* product limit; runtime enforcement continues to read Remote Config `free_habit_limit` (default 5, remote_config_service.dart:22,59-62). A guardrail test pins `LimitsCatalog.habits.freeValue == kDefaultFreeHabitLimit` (habit_providers.dart:42) so the two cannot silently diverge.

### 4.5 Paywall benefits layout (modified)

`lib/features/monetization/presentation/screens/paywall_screen.dart:107-127`

Replace the single `_BenefitBlock('UNLIMITED', 'Habits, clubs, themes')` with four blocks fed by the catalog constants (icon/color resolved locally by `featureKey` — presentation concern):

| row | icon | color | source |
|---|---|---|---|
| habits | `Icons.lock_open` | cyanAccent | `LimitsCatalog.habits` |
| clubs | `Icons.groups` | cyanAccent | `LimitsCatalog.clubs` |
| coachAsk | `Icons.auto_awesome` | cyanAccent | `LimitsCatalog.coachAsk` |
| themes | `Icons.public` | cyanAccent | `LimitsCatalog.themes` |

`PREMIUM INSIGHTS` and `EXCLUSIVE STYLE` blocks unchanged. The `_BenefitBlock` widget itself is unchanged (it already takes `title`/`subtitle`).

### 4.6 Post-checkout invalidation (modified, small)

In `_openPaystackPage` (paywall_screen.dart:295-300), after `launchUrl` completes (including cancellation — i.e., in a `finally`), call `ref.invalidate(isPremiumProvider)`. This re-runs `IsPremium.build()` → re-attaches the doc stream → immediate re-read. Normally the webhook updates the already-attached stream within seconds; the invalidate covers edge cases (e.g., stream attach raced the webhook write).

---

## 5. Data & storage changes

| Store | Change |
|---|---|
| Firestore `users/{uid}` | **None.** Webhook already writes `isPremium` (paystack.ts:129-136); owner-read rule already exists (firestore.rules:283-290). Read-only client access. |
| Firestore rules | None (verified owner-read). |
| shared_preferences | None new. Web does not write the premium cache; native cache untouched. |
| Remote Config | None. `free_habit_limit` (default 5) remains the runtime authority for the habit gate. |
| `docs/FREEMIUM_MODEL.md` | Rewritten matrix numbers + paywall triggers + entitlement id (see 4.4/D4). |
| Cloud Functions | None (SP-H). |

---

## 6. File inventory

### New files

| Path | Responsibility |
|---|---|
| `lib/features/monetization/domain/services/paywall_web_guard.dart` | Pure web-fetch/web-error guard functions (D6) |
| `lib/features/monetization/domain/models/premium_limit.dart` | `FreeTierLimit` + `LimitsCatalog` (D7) |
| `lib/features/monetization/data/services/web_premium_service.dart` | `streamWebPremium` Firestore stream (D8) |
| `test/features/monetization/domain/paywall_web_guard_test.dart` | Guard unit tests |
| `test/features/monetization/domain/premium_limit_test.dart` | Catalog unit tests incl. `kDefaultFreeHabitLimit` consistency |
| `test/features/monetization/data/web_premium_service_test.dart` | `fake_cloud_firestore` stream tests |

### Modified files

| Path | Change |
|---|---|
| `lib/features/monetization/presentation/screens/paywall_screen.dart` | Web guard in initState + ref.listen; catalog-driven benefit rows; post-checkout invalidate |
| `lib/features/monetization/presentation/providers/subscription_provider.dart` | `IsPremium.build()` web branch (`_buildFromFirestore`) |
| `test/features/monetization/presentation/screens/paywall_screen_test.dart` | Copy assertions updated for catalog rows |
| `docs/FREEMIUM_MODEL.md` | Real limits sync |

### Deleted files

None.

---

## 7. Error handling & edge cases

| Case | Behavior |
|---|---|
| Web user opens paywall | No offering fetch; no SnackBar ever; Paystack buttons render immediately |
| Web user pays via Paystack, returns to app | Closes paywall manually; Firestore stream flips `isPremium` when webhook lands (typically < 1–2 s); gates (habit cap, club join, coach asks, ads) unlock automatically; explicit invalidate re-reads immediately as belt-and-braces |
| `users/{uid}` doc missing (never paid) | Stream emits `false`; initial `get()` returns a non-existent snapshot → `false`; no error |
| Firestore read throws (offline/permission) | Web branch falls back to 7-day cache → else `false`; never blocks UI; error logged via `AppLogger.w` |
| Webhook latency / race with stream attach | Covered by stream re-emission + post-checkout invalidate (D10) |
| Duplicate webhook | Already idempotent server-side (`processed_webhooks`, paystack.ts:113-120) |
| `PaywallController` initial `isLoading: true` on web | Harmless — web build path returns `_buildPaystackPurchase()` before inspecting loading (paywall_screen.dart:186-189) |
| Native behavior | Bit-identical: guards pass, catalog rows are pure copy, provider web branch is `kIsWeb`-gated |
| `kIsWeb` in widget tests | Always `false` in the VM — that is why the guard is a pure function tested directly |
| Remote Config overrides `free_habit_limit` > 5 | Runtime gate follows RC (by design); paywall/docs show the declared default 5; guardrail test pins catalog == `kDefaultFreeHabitLimit` |

---

## 8. Testing strategy (TDD)

- **Task 1 — `PaywallWebGuard` unit tests (pure):** `shouldFetchOfferings(isWeb: true)` false / `false` → true; `shouldShowPaywallErrorSnackBar(isWeb: true, error: 'x')` false / native+error → true / native+null → false. This is the testable surface for the web SnackBar fix — `kIsWeb` cannot be faked in widget tests, so the decision logic is extracted and tested; the screen wiring is thin.
- **Task 3 — `LimitsCatalog` unit tests (pure):** every entry has non-empty key/unit/title/subtitle; values are exactly `5/1/3/1`; `themes` has `dialogCopyKey == null` and `premiumBypasses == false` (guards D3's "no theme dialog"); `forFeature` finds known keys and misses unknown; `habits.freeValue == kDefaultFreeHabitLimit` (cross-file guardrail, import from `habit_providers.dart`).
- **Task 6 — `streamWebPremium` tests with `fake_cloud_firestore`:** emits `false` for missing doc; emits `[false, true]` when the doc is created with `isPremium: true`; emits `false` again on `update({'isPremium': false})`; ignores a doc whose `isPremium` is a non-bool value (e.g. string) by emitting `false`.
- **Task 2/4/7 — widget-level:** update `paywall_screen_test.dart` copy assertions (currently expects `'UNLIMITED'`, paywall_screen_test.dart:42) to the catalog rows; assert the error-SnackBar path is untouched on native via the existing mock controller (a controller that sets `error` still shows the SnackBar in tests, since `kIsWeb == false` there).
- **No test-suite runs, no code changes, in this documentation task.** The plan (sibling file) carries the red→green→commit sequence for the implementing agent.

---

## 9. Out of scope (explicitly)

Theme lock UI + `ThemeLock` (SP-C, already spec'd and planned), tribe join/leave limit changes (SP-G), invite codes (SP-E), `functions/` + rules changes including the custom-claims sync alternative and the `generateAiRecap` gate fix (SP-H), consumables API cleanup, `PremiumThemePreview` wiring/deletion, `PaystackCheckoutScreen`/`PaystackPaymentRepository` reuse or deletion, ad-manager behavior changes, Remote Config key additions.

---

## 10. Risks

| Risk | Mitigation |
|---|---|
| `kIsWeb` untestable in widget tests | Pure guard extraction; manual web smoke test in the plan's final task |
| Web premium activation lag (webhook latency) | Live stream self-updates; explicit invalidate after checkout; copy the "few seconds" expectation into the plan's smoke checklist |
| Paywall copy claims drifting from enforcement | `LimitsCatalog` is the single source; guardrail test pins catalog vs `kDefaultFreeHabitLimit`; docs sync task in plan |
| SP-C ships after SP-B and changes the unlocked-theme set | `themes` catalog entry + paywall row are the only touchpoints; SP-C spec already fixed on `nebula` free + 5 locked |
| Dirty working tree (pre-existing uncommitted changes across ~30 files, verified 2026-08-01) | Plan pre-flight: commit only task-named files, never `git add -A` |
| Pre-existing failing test `test/features/social/domain/services/tribe_membership_service_test.dart` (SP-G, documented in SP-A handoff) | Not SP-B's responsibility; do not attempt to fix |
| `generateAiRecap` gate remains broken (`user_stats.isPremium` never written) | Out of scope; flagged for SP-H in this spec's D5 |
