# Web Paystack Order Confirmation — Design

**Date:** 2026-08-08
**App:** Emerge — Identity-First Habit Formation
**Sub-project:** #2 (of the post-verification sequence: #1 verification ✓ → #3 marketing email → #4 rating popup → this #2 web payments)

---

## 1. Problem Statement

Web premium checkout already exists: the paywall (`lib/features/monetization/presentation/screens/paywall_screen.dart:282`)
opens **static** Paystack Payment Pages (`https://paystack.shop/pay/…`) in an external browser, and the
`paystackWebhook` (`functions/src/payments/paystack.ts:86`) flips `users/{uid}.isPremium` + the premium claim
on `charge.success`. The backend is fully built (`initializePaystackTransaction` + webhook + tests).

**Gap:** there is no order-complete confirmation. The customer pays on Paystack's page, and the only
feedback is the premium flag flipping behind the scenes. The user asked for a clear "order has been done"
confirmation, linked to the web flow.

Root cause of the gap: the static Payment Pages are opened in a new tab and **cannot return a reference**
to the app, so there is nothing to confirm against.

---

## 2. Goals & Non-Goals

**Goals**
- After a successful Paystack web payment, land the user on a dedicated **order-complete confirmation screen**.
- The confirmation shows a receipt reference and a clear "Start exploring" path back into the app.
- Confirmation is reachable without the user manually digging for it (redirect-back, same tab).
- Premium entitlement continues to flip via the existing webhook → Firestore stream (no entitlement logic rework).

**Non-Goals**
- No mobile payment changes (RevenueCat/Play Store/App Store unchanged).
- No subscription/entitlement architecture changes.
- No new billing provider.
- No invoice/PDF receipt generation — a reference string + confirmation copy is enough (per the approved
  "simple receipt confirmation" choice).
- No changes to the existing `initializePaystackTransaction` webhook behavior on `charge.success`.

---

## 3. Architecture

```
Web paywall (PaywallScreen, kIsWeb)
  └─> httpsCallable('initializePaystackTransaction') { amount, email, identity_type, callbackUrl }
        └─> Paystack /transaction/initialize (with callback_url)
              └─> returns { authorization_url, access_code, reference }
  └─> window.location = authorization_url          (same tab)
        └─> customer pays on Paystack Payment Page
              └─> Paystack redirects to callbackUrl + ?reference=PSK_xxxx
                    └─> GoRouter route /order-confirmed?reference=...
                          └─> OrderConfirmedScreen: checkmark, "Order complete", reference, CTA → /timeline
  (background) paystackWebhook flips users/{uid}.isPremium + premium claim → isPremium stream updates
```

The confirmation screen does **not** gate on premium — the webhook/stream already reflects entitlement
within seconds. The screen is a receipt/acknowledgement surface, not a source of truth.

---

## 4. Cloud Function Change — `functions/src/payments/paystack.ts`

`initializePaystackTransaction` gains a `callbackUrl` request field, validated and forwarded to Paystack:

```ts
const { amount, email, metadata, callbackUrl } = request.data;
// ... existing amount/email validation ...
if (callbackUrl !== undefined &&
    typeof callbackUrl !== "string") {
  throw new HttpsError("invalid-argument", "callbackUrl must be a string when provided");
}
const body: Record<string, unknown> = {
  amount: amount,          // kobo
  email: email,
  channels: ["card", "apple_pay", "google_pay"],
  metadata: { /* existing custom_fields, unchanged */ },
};
if (callbackUrl && typeof callbackUrl === "string") {
  body.callback_url = callbackUrl;
}
```

Validation rule: `callbackUrl` is optional for backward compatibility (the mobile/web old clients and any
other caller keep working), but when present it must be an HTTP(S) string. The function returns the same
`{ authorization_url, access_code, reference }` shape.

**Security:** the callback URL is an open redirect surface if unvalidated. Constrain it: allow only
`https://` origins whose host is the app's web domain (or a comma-separated allow-list in the function's
env, defaulting to the Firebase Hosting domain). Reject anything else with `invalid-argument`. This
prevents a caller from pointing the callback at a phishing URL.

---

## 5. Client Changes

### 5.1 `lib/features/monetization/presentation/providers/paywall_provider.dart`

The controller (`paywallControllerProvider`) currently has `fetchOfferings`, `purchasePackage`, and
`restorePurchases` (RevenueCat-focused). Add a web path:

- `startWebCheckout({ required String planKey })` → calls the `initializePaystackTransaction` callable
  with `amount` (from the plan config), the current user email, `identity_type: planKey`, and
  `callbackUrl: Uri.base.origin + '/order-confirmed'`.
- On success, performs `window.location.assign(authorizationUrl)` (same-tab redirect).
- On failure, surfaces the mapped error (existing error path).

A small `PaystackPlan` map holds the two web plans (monthly ₦2,500 → 250000 kobo; yearly ₦15,000 →
1500000 kobo) so amounts stay in one place (they already appear as strings in `paywall_screen.dart:288,309`).

### 5.2 `lib/features/monetization/presentation/screens/paywall_screen.dart`

Replace `_buildPaystackPurchase`'s static-page launch with the new controller path:

- `_GoldShimmerButton` (yearly) → `controller.startWebCheckout(planKey: 'yearly')`.
- Monthly row → `controller.startWebCheckout(planKey: 'monthly')`.
- Delete `_monthlyPayUrl` / `_yearlyPayUrl` constants and `_openPaystackPage`.

Loading state: disable the buttons while a checkout is in flight.

### 5.3 New `OrderConfirmedScreen`

New screen `lib/features/monetization/presentation/screens/order_confirmed_screen.dart`:
- Reads `reference` from the GoRouter query parameter (`/order-confirmed?reference=...`).
- Full-screen confirmation: checkmark icon, "Order complete", "Your payment went through. Welcome to
  Emerge Premium.", the reference string (copyable), and a primary CTA "Start exploring" → `context.go('/timeline')`.
- Styling matches the paywall's cosmic/glass identity (`EmergeColors`, `paywall_screen.dart` patterns)
  but calmer (celebration, not sales).
- No entitlement gating; the existing `isPremiumProvider` stream reflects entitlement live.

### 5.4 Route registration — `lib/core/router/router.dart`

Add a top-level route (parent `_rootNavigatorKey`, like `/paywall`):

```dart
GoRoute(
  path: '/order-confirmed',
  builder: (context, state) => OrderConfirmedScreen(
    reference: state.uri.queryParameters['reference'],
  ),
),
```

Add the import. The route is reachable without auth (public, like the paywall), so a logged-out user who
lands there just sees the confirmation and is routed to login on "Start exploring".

### 5.5 `lib/features/monetization/domain/services/paywall_web_guard.dart`

`shouldFetchOfferings` / `shouldShowPaywallErrorSnackBar` already branch on `kIsWeb`. Verify no change
needed; the web flow no longer calls `fetchOfferings` on web (unchanged behavior — web never configures
RevenueCat).

---

## 6. Error Handling

- **Callable failure** (`resource-exhausted`, `failed-precondition` if `PAYSTACK_SECRET_KEY` missing,
  `internal`): reuse the existing `paywall_web_guard` error snackbar path so web users see a clear message
  and can retry.
- **Callback with no `reference` param:** the screen shows "Order complete" with an empty-reference
  fallback ("Payment received") rather than crashing — the premium stream is the real signal anyway.
- **Redirect-back before webhook lands:** the confirmation screen shows immediately; the premium flag
  flips within seconds via the webhook. No polling needed (per approved design).

---

## 7. Firestore Rules

No rule changes required — `users/{uid}` isPremium writes already come from the Admin SDK webhook
(`isPremium`/`premium_since` are server-owned per `isValidUser`). The confirmation screen reads no new
collections.

---

## 8. Testing (TDD Iron Law)

### Cloud Function (jest, `functions/test/paystack.test.ts` extension)
- `initializePaystackTransaction` forwards `callbackUrl` to Paystack's body when provided (assert the
  axios POST payload includes `callback_url`).
- Omits `callback_url` when not provided (backward compatible).
- Rejects a non-string `callbackUrl` (`invalid-argument`).
- Rejects a disallowed origin callback (`invalid-argument`), allows the app domain.
- Existing tests (auth guard, amount/email validation, error mapping) still pass.

### Pure Dart
- `paywallProvider.startWebCheckout` mapping: success returns the authorization URL; callable error maps
  to a user-facing `Failure`; disallowed/malformed callback throws at the guard (unit-testable pure helper
  `_buildCallbackUrl(origin)`).
- A pure `parseOrderReference(uri)` helper for reading `reference` from the redirect URL (test the
  query-param parsing).

### Widget
- `OrderConfirmedScreen`: renders checkmark + "Order complete" + reference when provided; renders the
  fallback copy when `reference` is null; "Start exploring" triggers navigation (harness permitting).
- `PaywallScreen` (web override): yearly/monthly buttons call `startWebCheckout` with the right planKey.

### Verification commands (focused only — never the full suite)
- `cd functions && npm run build && npx jest test/paystack.test.ts`
- `flutter test test/features/monetization/...`
- `flutter analyze lib/features/monetization lib/core/router/router.dart`

---

## 9. Rollout

1. Deploy functions (`firebase deploy --only functions:initializePaystackTransaction`).
2. Release app update (web).
3. Manual verify: web paywall → Paystack page → pay (test card `4084 0840 8408 4081`) → redirect back
   to `/order-confirmed?reference=…` → premium flips via webhook within seconds.

---

## 10. Open Items / Assumptions

- **Callback host allow-list** defaults to the Firebase Hosting domain; production deploy should confirm
  the list matches the live domain (and `web/version.json` domain, if different).
- Amounts are hardcoded in the provider config (kobo) to match the current static-page prices
  (₦2,500/month, ₦15,000/year). If pricing moves to Remote Config later, that's a separate change.
- The web redirect uses `window.location.assign` (full reload) — acceptable for web; no SPA-state carryover
  needed since `reference` travels in the URL.
