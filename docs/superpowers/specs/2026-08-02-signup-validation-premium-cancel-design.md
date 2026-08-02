# Real-Time Signup Validation + Premium Cancel & Retention Flow — Design Spec

> **Scope:** Two user-facing changes + one backend addition:
> (1) real-time inline validation on the signup forms with a conditional password-requirements checklist; (2) a full premium cancellation flow with retention psychology (loss framing, endowment recap, pause step) for both native (RevenueCat) and web (Paystack). Documentation only — no code changes in this file.
>
> **Related specs:** `2026-08-01-sp-b-paywall-premium-limits-design.md` (web premium source of truth via `users/{uid}.isPremium`), `2026-07-25-ux-psychology-and-habit-features-design.md` (prior psychology work — no password-checklist overlap).
>
> **Platform scope (user decision):** this feature ships for **Android + web only**. **No iOS configuration** — no Info.plist/entitlement/capability changes, no App Store-specific setup, and no iOS-specific branches. The native management-link path covers Android via the RevenueCat `managementURL`; iOS is neither configured nor tested here.

---

## 1. Goals

1. **Sign-up forms indicate what is missing before completion.** User signup (`lib/features/auth/presentation/screens/signup_screen.dart`) and creator signup (`lib/features/auth/presentation/screens/creator_signup_screen.dart`) validate fields in real time as the user interacts (`AutovalidateMode.onUserInteraction`), per `docs/design.md` §10.2 (line 679) — currently no form sets an autovalidate mode, so errors only surface on submit.
2. **Conditional password-requirements checklist.** A checklist of the real `validatePassword` rules appears **only while the password is being completed** (focused + non-empty) and ticks off live. It appears on the **password field only — never the confirm-password field** (user decision). Checklist rules derive from the same constants as the validator so UI can never contradict validation.
3. **Premium cancellation exists.** Replace the Settings stub (`lib/features/settings/presentation/screens/settings_screen.dart:142-164`) with a real manage flow:
   - **Native (Android):** cancel via the Google Play manage page opened through RevenueCat's `managementURL` — the only store-policy-compliant path for auto-renewing subscriptions. **No iOS configuration** (user decision).
   - **Web:** in-app cancellation via a new `managePremium` Cloud Function callable that revokes `isPremium` + the `activeEntitlements` claim (Paystack charges are one-time, not recurring — revocation is a grant-revocation, not a billing operation).
4. **Retention psychology in the cancel flow** (research-backed, honest, no dark patterns):
   - **Loss aversion** — "You'll lose X" framing (thesigma.co/Ordergroove research).
   - **Endowment/IKEA effect** — recap what the user has built (streak, habits, world).
   - **Pause/save step** — "Pause instead?" — industry data shows save steps recover ~17–24% of cancelling subscribers.
   - **Ease of exit** (Nielsen heuristic #3 + FTC click-to-cancel) — no hidden friction; friction-free exit builds trust.

---

## 2. Recorded decisions

### D1 — Real-time validation: `AutovalidateMode.onUserInteraction` on both signup forms

- Set `AutovalidateMode.onUserInteraction` on the `Form` widget in `signup_screen.dart` (mobile + tablet copies) and `creator_signup_screen.dart`. Fields show errors only after the user has interacted with that field — untouched fields stay quiet (NNGroup: premature validation is a hostile pattern).
- Validators are the **existing** `AppValidators` (`lib/core/utils/validators.dart`); no new rules.
- `LoginScreen`/`CreatorLoginScreen` are **out of scope** (no requirement — user confirmed checklist is signup-only; login screens already validate on submit; the repo-side validator mismatch on login is a pre-existing issue, tracked in §7 as future work).
- The two duplicated form blocks in `signup_screen.dart` (mobile `_buildMobileForm`-style block ~line 259, tablet block ~line 674) share one `_formKey` and controllers; the autovalidate mode applies to the shared `Form` state, so both blocks get the behavior in one change. No refactor of the duplication in this spec (YAGNI — flagged in §7).

### D2 — `PasswordRequirementChecklist` widget (shared, conditional, validator-driven)

- **New widget:** `lib/features/auth/presentation/widgets/password_requirement_checklist.dart` (auth feature owns it; both signup screens import it).
- **Rule source of truth:** extract the rule predicates from `validatePassword` (`lib/core/utils/validators.dart:47-96`) into shared constants/functions — e.g. `PasswordRules` (min length 12, 3-of-4 character classes, no common/sequential/repeated patterns). `validatePassword` and the checklist both consume `PasswordRules`, so a rules change can never desync UI from validation. A consistency unit test enforces this (§5).
- **Visibility rule (the "only when completing it" requirement):** visible whenever the password field is focused with content, or has any typed content (hidden only when the field is empty or untouched). It never renders on an untouched/empty field.
  - **Never shown on the confirm-password field** (user decision; confirm field keeps real-time validation only).
- **Behavior:** each requirement row shows a check icon the moment its predicate passes (live, on every keystroke). All-pass → checklist collapses to a single green "Password looks good" line (collapsing avoids a permanent 4-row block once the field is valid — keeps the form compact).
- **Placement:** directly under the password `TextFormField`, inside the form flow (not an overlay). Style follows `docs/design.md` §10.4 dark-theme input styling and the design system's feedback hierarchy (§5.4: inline, persistent until fixed).

### D3 — Manage Premium screen replaces the Settings stub

- **New screen:** `lib/features/monetization/presentation/screens/manage_premium_screen.dart`, pushed from the Settings "Manage Subscription" tile (`settings_screen.dart:142-164`).
- Shows:
   - Plan state (Premium active / paused / free), price string from `monetizationRepositoryProvider.premiumPriceString`, billing channel label (Paystack on web / Google Play on Android), and "Premium since {date}" from `users/{uid}.premium_since` (web only).
  - Primary action: **"Cancel subscription"** — honest, standard destructive styling, always visible; no hidden-friction links.
- Native + web share the screen; platform-specific behavior lives behind the existing `kIsWeb` fork pattern (same split as `paywall_screen.dart:214-217`).

### D4 — Cancel flow: 3-step full screen (loss framing → pause step → confirm)

The cancel flow is a **full screen** (not a bottom sheet) — it holds a 3-step sequence with two decision points; per design doc §5.4, modality is reserved for severe single-step errors, and the user approved full-screen.

1. **Endowment recap + loss framing** (step 1):
   - Header: honest, archetype-toned copy, e.g. "You're about to lose:" — benefit list (unlimited habits, Pro World, daily AI coaching, ad-free, theme).
   - Endowment line sourced from existing providers: `userStreakProvider` (`lib/core/presentation/widgets/emerge_bottom_nav.dart:38`) for "your N-day streak", habit count from the existing habit providers, and "Premium since {date}". If data is unavailable, fall back to the plain benefit list (no broken UI).
   - CTA: "Keep Premium" (primary, returns) + "Continue cancelling" (secondary).
2. **Pause/save step** (step 2): "Pause instead?" — honest copy: "Pause keeps everything safe — your streak, habits, and world. Resume anytime."
   - **Web:** "Pause for 30 days" → `managePremium(action: "pause")` → screen transitions to a "Premium paused" state.
   - **Native (Android):** the pause CTA opens the Google Play manage page (where pause actually lives). Wording adjusts per platform. CTA: "Continue to pause options".
   - CTA: "Keep Premium" + "Cancel anyway".
3. **Confirm cancel** (step 3):
   - **Web:** "Cancel Premium" → `managePremium(action: "cancel")` (instant revocation) → success state: "Premium cancelled — your account stays free. Your data and world are safe." (endowment reassurance; no exit survey — user declined it).
   - **Native (Android):** confirmation dialog copy: "You'll be redirected to Google Play to finish cancelling" → open `CustomerInfo.managementURL` (RevenueCat SDK). The store page performs the actual cancellation; RevenueCat's cancellation webhook + status stream update `isPremiumProvider` live. **No in-app cancel button that disables auto-renew** (store policy).

### D5 — Native management link via RevenueCat (Android)

- Extend `MonetizationRepository` (`lib/features/monetization/domain/repositories/monetization_repository.dart:7-44`) with `openManageSubscription()`: implemented in `RevenueCatRepository` (`revenue_cat_repository.dart`) as — get `Purchases.getCustomerInfo()`, use `customerInfo.managementURL` (parsed by `purchases_flutter` 10.3.0, `customer_info_wrapper.dart:56`), and `launchUrl` it externally. Native only; web never calls it (guarded by `kIsWeb`). **No iOS configuration required — `managementURL` comes from the SDK/store, not from app config.**

### D6 — `managePremium` Cloud Function callable (web revocation + pause)

- **New file:** `functions/src/managePremium.ts`, exported from `functions/src/index.ts`, Gen 2 `onCall`, auth required, modeled on `setUserRole.ts` (`functions/src/setUserRole.ts:92-97` merge-safe claims pattern).
- `{action: "pause" | "cancel"}`:
  - **cancel:** idempotent write to `users/{uid}`: `isPremium: false`, `subscriptionStatus: "cancelled"`, `cancelledAt` (serverTimestamp). Rewrite custom claims `activeEntitlements` **without** `"premium"` (merge-safe — never clobbers other claims).
  - **pause:** `users/{uid}`: `subscriptionStatus: "paused"`, `premiumEndsAt` = now + 30 days. Claims untouched (still premium while paused).
- **Security:** Firestore rules already forbid client writes to `isPremium`/`premium_since` (`firestore.rules:57` users, `:180` user_stats) — the callable is the only revocation path. No rules change needed.
- **Paystack refunds are out of scope** — one-time charges; refunds remain a manual Paystack-dashboard operation (documented in §7). The callable revokes app-state regardless of payment; charge remains settled.
- **Note (pre-existing, not fixed here):** the RevenueCat cancellation/expiration event handlers (`functions/src/revenuecat_events.ts:114-161,167-211`) write `subscriptionStatus` but never clear `isPremium`/claims — irrelevant on native (RevenueCat entitlement `isActive` is the live truth) but flagged in §7 as future hardening for the Firestore mirror.

### D7 — Web premium read honors "paused" (small change to `isPremiumProvider`)

- `IsPremium.build()` web branch — `_buildFromFirestore` (`lib/features/monetization/presentation/providers/subscription_provider.dart:105-119`) — currently maps the doc to `isPremium == true`. Extend: if `subscriptionStatus == "paused"` and `premiumEndsAt` is in the future → still premium; on/after `premiumEndsAt` → free.
- Native path untouched (RevenueCat status stream already handles cancellation live).

### D8 — Pure `computePremiumState` for testability (project signature pattern)

- Extract the doc→state mapping into a **pure function** `computePremiumState({required bool isPremium, String? subscriptionStatus, DateTime? premiumEndsAt, DateTime now}) → PremiumState` (`PremiumState = {isPremium, paused, endsAt}`) — the `decideRedirect` + `RedirectContext` pattern (`lib/core/router/router.dart:68-231`, tested in `test/core/router/router_redirect_test.dart`).
- Used by `_buildFromFirestore` (D7). Unit-tested without Firebase (§5).

---

## 3. Architecture

```
┌─ Sign-up (client) ──────────────────────────────────────────────┐
│ Form(AutovalidateMode.onUserInteraction)                        │
│   ├─ Username  TextFormField ─ AppValidators.validateUsername   │
│   ├─ Email     TextFormField ─ AppValidators.validateEmail      │
│   ├─ Password  TextFormField ─ validatePassword ← PasswordRules │
│   │                └─ PasswordRequirementChecklist (conditional)│
│   └─ Confirm   TextFormField ─ validateConfirmPassword          │
│            (real-time validation, NO checklist)                 │
└─────────────────────────────────────────────────────────────────┘
        both signup screens (user + creator)

┌─ Cancel flow ───────────────────────────────────────────────────┐
│ Settings "Manage Subscription" → ManagePremiumScreen            │
│   → step1: endowment recap + loss framing ("You'll lose…")      │
│   → step2: pause/save ("Pause instead?")                        │
│   → step3: confirm                                              │
│      ├─ web   → managePremium(action: cancel|pause)  callable   │
│      │           → users/{uid} + activeEntitlements claim       │
│      └─ native → Purchases.showManageSubscriptions()            │
│                    → store manage page (pause/cancel live here) │
│   isPremiumProvider (web) ← computePremiumState(record, now)    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Edge cases & hardening

| Case | Handling |
|---|---|
| Checklist flicker on field focus | Show only when focused **and** non-empty; hide when unfocused with empty content — no flash on plain focus |
| Checklist vs validator drift | Both consume shared `PasswordRules` constants + consistency unit test (§5) |
| Sign-up submit while checklist open | No change to submit behavior — `_formKey.currentState!.validate()` still gates (`signup_screen.dart:48`, `creator_signup_screen.dart:46`); checklist is advisory, validator remains authority |
| Cancel tapped twice (web) | `managePremium` idempotent (same outcome on repeat); client disables the confirm button while the call is in flight |
| Paused user hits `premiumEndsAt` | `computePremiumState` flips to free past the end date; stream self-updates on web |
| Paused user on native | Pause is store-managed there; no `premiumEndsAt` written for native (guard the callable: web-origin flag or client only calls it on web) |
| No streak/habit data (fresh user) | Endowment line omitted; plain benefit list shown — no broken layout |
| `managePremium` unauthorized/unauthenticated | `HttpsError("unauthenticated"/"permission-denied")`; client surfaces the failure inline (red SnackBar per existing patterns) |
| Web user cancels then re-purchases | Webhook re-writes `isPremium: true` + claim (existing path, `functions/src/payments/paystack.ts:130-147`) — re-upgrade works |
| Native cancel via store → app status | RevenueCat `premiumStatusStream` updates `isPremiumProvider` live; claims fallback is pre-existing behavior, unchanged |

---

## 5. Testing

- **Pure logic (no Firebase):** `computePremiumState` matrix — active / paused-future / paused-expired / cancelled / plain-free, unit-tested in `test/features/monetization/...` (mirrors `router_redirect_test.dart` pattern).
- **Validator/checklist consistency:** test asserting every `PasswordRules` predicate is rendered by the checklist (and vice versa) — drift fails CI.
- **Widget tests:**
  - `signup_screen_test.dart` / `creator_signup_screen_test.dart`: error appears only after field interaction (not on first frame); checklist visible while password focused+non-empty; **absent on confirm field**; ticks flip as rules pass.
  - `manage_premium_screen_test.dart` (fake RevenueCat via existing test seams + `kIsWeb`-safe injection): steps render in order; web cancel calls the callable; native cancel attempts the manage link, never an in-app revoke.
- **Functions (jest):** `managePremium` — unauthenticated rejection, cancel idempotency (double-call), claims removal merge-safety (other claims preserved), pause writes `premiumEndsAt` and leaves claims.
- **Dev workflow:** focused tests + `dart analyze` only — no full-suite runs during development (AGENTS.md test discipline).

---

## 6. Verification

1. `dart analyze` clean.
2. `flutter test test/features/auth/... test/features/monetization/...` focused runs green (signup checklist, manage flow, `computePremiumState`).
3. `npm test` in `functions/` — `managePremium` cases green.
4. Manual smoke: fill signup form → field errors appear per-interaction; password checklist appears on typing, ticks live, absent on confirm field; Settings → Manage Premium → cancel path (web: revoke then `isPremiumProvider` flips free; native: store page opens).

## 7. Out of scope / future work

- Login-screen real-time validation + repo/client validator mismatch (login checks non-empty, repository enforces 12-char password — `firebase_auth_repository.dart:77-86`) — flagged, not fixed here.
- Refactor of the duplicated mobile/tablet form blocks in `signup_screen.dart`.
- RevenueCat cancellation/expiration handlers clearing the Firestore `isPremium` mirror + claims (`revenuecat_events.ts`) — native is correct today via RevenueCat entitlements; server-mirror hygiene is future hardening.
- Paystack refund automation (webhook only receives `charge.success`; expiry/refund clearing explicitly deferred, per `paystack.ts:136-140`).
- Exit survey (user declined option C).
- Other retention levers from research (streak-protection promos, win-back offers) — not requested; the pause step is the only save mechanic in this iteration.
