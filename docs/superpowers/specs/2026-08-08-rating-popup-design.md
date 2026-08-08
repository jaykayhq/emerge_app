# Milestone Rating Popup + Feedback Form — Design

**Date:** 2026-08-08
**App:** Emerge — Identity-First Habit Formation
**Sub-project:** #4 (of the post-verification sequence: #1 verification ✓ → #3 marketing email ✓ planned → this #4 → #2 web payments)

---

## 1. Problem Statement

Emerge has no rating/review flow. App-store ratings are a primary growth lever for habit apps, and the
developer asked for a feedback/rating popup that (a) appears at a peak-satisfaction moment and (b) links
to the Play Store. Nothing exists today: no `in_app_review`, no `store_redirect`, no feedback collection.

Approved decisions:
- **Trigger:** after a meaningful milestone (7-day streak, first challenge completed, emerge reveal).
- **Fallback:** "not now" silently stops asking this version; **low rating (≤3)** routes to an in-app
  feedback form instead of the store; high rating (≥4) goes to the store review flow.

---

## 2. Goals & Non-Goals

**Goals**
- Ask for a rating exactly once per meaningful milestone, with a per-user cooldown and a
  "don't ask again this version" persistence so it never nags.
- High rating (≥4) → native review prompt on mobile (`in_app_review.requestReview()`), Play Store link
  card on web (and as a mobile fallback if the native prompt is unavailable).
- Low rating (≤3) → in-app feedback form that persists to Firestore (`feedback/{uid}`).
- Pure, unit-testable gate logic (milestone + cooldown + persisted flag) following the project's
  signature testable-design pattern.

**Non-Goals**
- No analytics/event pipeline changes (milestones are detected from existing state, not new tracking).
- No email-based rating request (that belongs to #3 marketing).
- No NPS surveys, no multi-step feedback wizard — one form, one field.
- No App Store (iOS) web link card — iOS uses `in_app_review`; web links to the Play Store (approved:
  "links to Play Store").

---

## 3. Architecture

```
Milestone signal (existing logic: streak ≥ 7, challenge complete, emerge reveal)
  └─> emit RatingPromptSignal (pure)
        └─> RatingPromptGate.evaluate(signal, lastAskedAt, versionAskedFor, dontAskAgain)
              └─> null            → do nothing (cooldown/duplicate)
              └─> AskRating      → show in-app rating dialog
              └─> AskReview      → high rating path
        └─> persist: lastAskedAt + versionAskedFor + dontAskAgain (SharedPreferences)
        └─> ShowRatingDialog:
              └─> user rates:
                    └─> ≥4 → in_app_review.requestReview()  (mobile) | PlayStore card (web)
                    └── └─> persist lastAskedAt (don't re-ask this version)
                    └─> ≤3 → push FeedbackScreen (in-app form)
                    └─> "Not now" → persist lastAskedAt; no re-ask this version
```

---

## 4. Pure logic — `RatingPromptGate` (the signature pattern)

New file `lib/features/rating/domain/rating_prompt_gate.dart` — pure, no Flutter/Firebase imports:

```dart
enum RatingPromptSignal { sevenDayStreak, challengeCompleted, emergeReveal }

enum RatingPromptDecision { askForRating }

class RatingPromptGate {
  /// Returns whether a rating prompt should be shown.
  /// - signal: which milestone fired (any signal is sufficient to qualify)
  /// - lastAskedAt: when we last asked (null = never)
  /// - versionAskedFor: app version string of the last ask (null = never)
  /// - dontAskAgain: persisted "never ask" flag
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
    if (lastAskedAt != null && versionAskedFor == currentVersion) return false;
    if (lastAskedAt != null && now.difference(lastAskedAt) < cooldown) return false;
    return true;
  }
}
```

Cooldown default: **90 days** (single constant). "Not now" and low-rating feedback also set `lastAskedAt`
so the same version never re-asks (per approved behavior).

---

## 5. Milestone signal wiring

Milestone emission lives in the app layer (where the state is already computed) and routes into a single
provider so the gate is testable end-to-end:

- **Seven-day streak:** the streak computation in `lib/features/habits/presentation/providers/habit_providers.dart`
  (streak value around line 253) — when a completion makes `streak` reach exactly 7, emit `sevenDayStreak`.
- **First challenge completed:** `lib/features/social/domain/services/club_activity_service.dart:32`
  (`challenge_complete` activity type) — when a challenge transitions to completed and the user's
  `completedChallenges` count crosses 1, emit `challengeCompleted`.
- **Emerge reveal:** the `emerge_splash_reveal` flow / `hasEmerged` flag — when the user's first
  emerge reveal happens, emit `emergeReveal`.

Implementation approach: a `RatingPromptControllerProvider` (Notifier) with a `notifyMilestone(signal)`
method. Each existing milestone site calls it once. The controller:
1. Reads persistence (`SharedPreferences`) via a thin `RatingPromptStore` abstraction (so tests inject a
   fake instead of the real plugin).
2. Calls `RatingPromptGate.shouldAsk(...)`.
3. If true, shows the dialog (navigator key from the router, or a top-level scaffold messenger), then
   persists the outcome.

No new analytics/tracking — the signals are already computed; we only observe them.

---

## 6. Rating dialog & feedback form

### 6.1 `RatingPromptDialog` (in-app rating sheet)
- Renders 1–5 star buttons + "Not now".
- ≥4 → review path (§6.2); ≤3 → feedback form (§6.3); "Not now" → persist, close.
- Styled with `EmergeColors` / glass surfaces per `docs/design.md`.

### 6.2 Review path
- **Mobile:** `in_app_review.requestReview()` (new dependency `in_app_review`, checked into pubspec).
  The native prompt is a system sheet; our dialog closes first.
- **Web:** a small "Love Emerge? Rate us on the Play Store" card with a Play Store deep link
  (`https://play.google.com/store/apps/details?id=<bundleId>`), since `in_app_review` is not supported
  on web.
- If `requestReview()` throws or returns unavailable (iOS simulator, rate-limit), fall back to the same
  Play Store card (mobile fallback too).

### 6.3 `FeedbackScreen` (low-rating form)
- One screen: "Help us improve — what got in the way?" with a multiline field + submit.
- Submit → `Firestore.collection('feedback').doc(uid).set({ userId, message, rating, createdAt, appVersion, platform })`.
- Confirmation snackbar, then pop. No follow-up email (that's #3's domain).

---

## 7. Persistence — `RatingPromptStore`

Thin wrapper over `SharedPreferences` (key prefix `rating_prompt.`):
- `lastAskedAt` (ISO string / ms epoch), `versionAskedFor`, `dontAskAgain` (bool).
- Interface + `SharedPreferencesRatingPromptStore` impl; fakes in tests.

---

## 8. Firestore Rules

New `feedback/{uid}` collection (doc id = user id, one per user, upsert):

```firestore
match /feedback/{uid} {
  allow read, write: if isOwner(uid);
}
```

Server-side/admin read is implicit (Admin SDK bypasses rules). This lets the team read feedback from the
console while users can only write their own doc. Cap the message length in validation (client-side
enforced; server validates via rules if desired — keep it simple: client + firestore rules
`request.resource.data.message.size() <= 2000`).

---

## 9. Dependencies

- `in_app_review` (pub.dev) — mobile review prompt.
- `shared_preferences` — already in pubspec (verify; used for other settings).
- `url_launcher` — already in pubspec (used by paywall Terms/Privacy).

---

## 10. Testing (TDD Iron Law)

### Pure Dart (no Flutter — signature pattern)
- `RatingPromptGate`:
  - never asked → asks
  - asked this version → does not ask
  - asked a previous version → asks
  - within cooldown → does not ask
  - `dontAskAgain` → never asks regardless
  - cooldown expiry → asks again
- `RatingPromptStore` (fake): persistence round-trip.

### Widget
- `RatingPromptDialog`: tap 5 stars → review path invoked (injected fake review launcher); tap 2 stars →
  feedback form shown; tap "Not now" → persists + closes.
- `FeedbackScreen`: valid submit writes to the (fake) feedback repository; empty message disabled; success
  snackbar + pop.
- Web/Play-Store card renders when review unavailable (injected fake).

### Integration (controller)
- `RatingPromptControllerProvider.notifyMilestone(sevenDayStreak)` with fake store: first time asks,
  second time (same version) does not.

### Verification commands (focused only — never the full suite)
- `flutter test test/features/rating/...`
- `flutter analyze lib/features/rating`

---

## 11. Rollout

1. Release with the milestone signals wired.
2. Verify: 7-day streak on a test account → dialog appears once; "Not now" → no re-ask this version;
   low rating → feedback form persists to `feedback/{uid}`.
3. High-rating review prompt verified on a physical device (iOS simulator cannot show the native prompt).
4. Play Store link card verified on web.

---

## 12. Open Items / Assumptions

- **Bundle ID** for the Play Store link must be confirmed (`android/app/build.gradle.kts` applicationId;
  the repo has `com.…` — read it during implementation).
- `in_app_review` on web is unsupported; the Play Store card is the web fallback (approved).
- "Don't ask again this version" uses the app version from `package_info_plus` (verify dependency) or a
  build constant; if `package_info_plus` is missing, add it or use the existing version source.
- Milestone emissions are one-shot per achievement (e.g., streak exactly 7) so the gate's cooldown + a
  per-milestone guard in the controller prevent repeat pings in the same session.
