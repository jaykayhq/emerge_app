# Web Paystack Order Confirmation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After a successful Paystack web payment, redirect back to an order-complete confirmation screen showing a receipt reference and a path back into the app.

**Architecture:** Wire the existing `initializePaystackTransaction` callable into the web paywall (replacing static Payment Page URLs), pass a validated `callbackUrl` so Paystack redirects back to `/order-confirmed?reference=…`, and render `OrderConfirmedScreen`. Entitlement continues to flip via the existing webhook → `isPremiumProvider` stream.

**Tech Stack:** Flutter/Riverpod, go_router, Firebase Cloud Functions (TypeScript, jest), Paystack REST API via axios.

---

## File Structure

**New (Flutter):**
- `lib/features/monetization/presentation/screens/order_confirmed_screen.dart`
- `test/features/monetization/presentation/screens/order_confirmed_screen_test.dart`

**Modified (Flutter):**
- `lib/features/monetization/presentation/providers/paywall_provider.dart` — add `startWebCheckout`.
- `lib/features/monetization/presentation/screens/paywall_screen.dart` — replace static URLs with controller call.
- `lib/features/monetization/data/repositories/paystack_payment_repository.dart` — add `callbackUrl` param.
- `lib/features/monetization/presentation/providers/subscription_provider.dart` (verify `isPremiumProvider` untouched).
- `lib/core/router/router.dart` — add `/order-confirmed` route.
- `test/features/monetization/presentation/screens/paywall_screen_test.dart` (web override tests, if present).
- `test/features/monetization/data/repositories/paystack_payment_repository_test.dart` (add callbackUrl test).

**Modified (functions):**
- `functions/src/payments/paystack.ts` — accept + validate `callbackUrl` (host allow-list).
- `functions/test/paystack.test.ts` — callbackUrl tests.

---

## Task 1: Cloud Function — `callbackUrl` support

**Files:**
- Modify: `functions/src/payments/paystack.ts:26-36`
- Test: `functions/test/paystack.test.ts`

- [ ] **Step 1: Write the failing tests**

Append to `functions/test/paystack.test.ts` (read the existing file first to match its mock style):

```ts
describe("initializePaystackTransaction callbackUrl", () => {
  const auth = { uid: "u1", token: {} };

  it("forwards a valid app-domain callbackUrl to Paystack", async () => {
    const result = await initializePaystackTransaction.run({
      auth,
      data: {
        amount: 1500000,
        email: "a@b.com",
        callbackUrl: "https://emerge.web.app/order-confirmed",
      },
    });
    expect(result).toMatchObject({ authorization_url: expect.any(String) });
    // Assert the axios POST body contained callback_url with the app origin.
    expect(axiosPost).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({
        callback_url: "https://emerge.web.app/order-confirmed",
      }),
      expect.any(Object)
    );
  });

  it("omits callback_url when not provided (backward compatible)", async () => {
    await initializePaystackTransaction.run({
      auth,
      data: { amount: 1500000, email: "a@b.com" },
    });
    const [, body] = axiosPost.mock.calls[0];
    expect(body.callback_url).toBeUndefined();
  });

  it("rejects a non-string callbackUrl", async () => {
    await expect(
      initializePaystackTransaction.run({
        auth,
        data: { amount: 1500000, email: "a@b.com", callbackUrl: 42 },
      })
    ).rejects.toHaveProperty("code", "invalid-argument");
  });

  it("rejects a disallowed callback host", async () => {
    await expect(
      initializePaystackTransaction.run({
        auth,
        data: {
          amount: 1500000,
          email: "a@b.com",
          callbackUrl: "https://evil.example.com/phish",
        },
      })
    ).rejects.toHaveProperty("code", "invalid-argument");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npx jest test/paystack.test.ts`
Expected: FAIL — callbackUrl not forwarded / not validated

- [ ] **Step 3: Implement**

In `functions/src/payments/paystack.ts`, add an allow-list helper near the top:

```ts
const CALLBACK_ALLOWED_HOSTS = (
  process.env.CALLBACK_ALLOWED_HOSTS ?? "emerge.web.app,emerge.firebaseapp.com"
)
  .split(",")
  .map((h) => h.trim())
  .filter(Boolean);
```

In `initializePaystackTransaction`, after the email validation:

```ts
const { amount, email, metadata, callbackUrl } = request.data;
// ...existing amount/email validation unchanged...

// callbackUrl is optional (backward compatible) but must be https and its
// host must be allow-listed — prevents the callback being pointed at a
// phishing origin.
let validatedCallbackUrl: string | undefined;
if (callbackUrl !== undefined) {
  if (typeof callbackUrl !== "string") {
    throw new HttpsError("invalid-argument", "callbackUrl must be a string");
  }
  let parsed: URL;
  try {
    parsed = new URL(callbackUrl);
  } catch {
    throw new HttpsError("invalid-argument", "callbackUrl must be a valid URL");
  }
  if (parsed.protocol !== "https:" || !CALLBACK_ALLOWED_HOSTS.includes(parsed.host)) {
    throw new HttpsError("invalid-argument", "callbackUrl host is not allowed");
  }
  validatedCallbackUrl = callbackUrl;
}
```

Then include it in the Paystack body:

```ts
const body: Record<string, unknown> = {
  amount: amount, // in kobo
  email: email,
  channels: ["card", "apple_pay", "google_pay"],
  metadata: { /* existing custom_fields, unchanged */ },
};
if (validatedCallbackUrl) {
  body.callback_url = validatedCallbackUrl;
}
```

Replace the literal `{ amount, email, channels, metadata }` object passed to `axios.post` with `body`.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd functions && npm run build && npx jest test/paystack.test.ts`
Expected: PASS (existing + 4 new)

- [ ] **Step 5: Commit**

```bash
cd functions && npm run build && npx eslint src/payments/paystack.ts && npx jest test/paystack.test.ts
cd .. && git add functions/src/payments/paystack.ts functions/test/paystack.test.ts
git commit -m "feat(functions): validated callbackUrl for Paystack web checkout"
```

---

## Task 2: Repository — add `callbackUrl`

**Files:**
- Modify: `lib/features/monetization/data/repositories/paystack_payment_repository.dart`
- Test: `test/features/monetization/data/repositories/paystack_payment_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Read the existing repo test file first. Add:

```dart
  test('initializeTransaction forwards callbackUrl to the callable', () async {
    when(() => functions.httpsCallable('initializePaystackTransaction'))
        .thenReturn(callable);
    when(() => callable.call<Map<String, dynamic>>(any()))
        .thenAnswer((_) async => {
              'authorization_url': 'https://checkout.paystack.com/abc',
              'access_code': 'x',
              'reference': 'ref1',
            });

    await repo.initializeTransaction(
      amount: 15000,
      email: 'a@b.com',
      identityType: 'yearly',
      callbackUrl: 'https://emerge.web.app/order-confirmed',
    );

    final payload = verify(() => callable.call<Map<String, dynamic>>(captureAny()))
        .captured
        .single as Map<String, dynamic>;
    expect(payload['callbackUrl'], 'https://emerge.web.app/order-confirmed');
    expect(payload['amount'], 1500000); // kobo conversion unchanged
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/monetization/data/repositories/paystack_payment_repository_test.dart --timeout 60s`
Expected: FAIL — `callbackUrl` is not a named parameter

- [ ] **Step 3: Implement**

`lib/features/monetization/data/repositories/paystack_payment_repository.dart`:

```dart
  Future<String> initializeTransaction({
    required double amount,
    required String email,
    required String identityType,
    String? callbackUrl,
  }) async {
    try {
      final callable = _functions.httpsCallable('initializePaystackTransaction');
      final result = await callable.call<Map<String, dynamic>>({
        'amount': amount * 100, // Paystack uses kobo/cents
        'email': email,
        'metadata': {'identity_type': identityType},
        if (callbackUrl != null) 'callbackUrl': callbackUrl,
      });
      // ...rest unchanged...
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/monetization/data/repositories/paystack_payment_repository_test.dart --timeout 60s`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/monetization/data/repositories/paystack_payment_repository.dart test/features/monetization/data/repositories/paystack_payment_repository_test.dart
git commit -m "feat(monetization): forward callbackUrl through Paystack repository"
```

---

## Task 3: Provider — `startWebCheckout`

**Files:**
- Modify: `lib/features/monetization/presentation/providers/paywall_provider.dart`
- Test: `test/features/monetization/presentation/providers/paywall_provider_test.dart` (or a new controller test)

- [ ] **Step 1: Write the failing test**

Read the existing provider test file. Add a test that `startWebCheckout` calls the repository with the plan amount and callback, then assigns the authorization URL. Use a fake/override for `paystackPaymentRepositoryProvider`:

```dart
  test('startWebCheckout calls initializeTransaction with plan amount + callback',
      () async {
    final repo = _MockPaystackRepo();
    when(() => repo.initializeTransaction(
          amount: any(named: 'amount'),
          email: any(named: 'email'),
          identityType: any(named: 'identityType'),
          callbackUrl: any(named: 'callbackUrl'),
        )).thenAnswer((_) async => 'https://checkout.paystack.com/abc');

    final container = ProviderContainer(overrides: [
      paystackPaymentRepositoryProvider.overrideWithValue(repo),
      // override auth provider to return a known email
    ]);
    final notifier = container.read(paywallControllerProvider.notifier);
    await notifier.startWebCheckout(planKey: 'yearly');

    verify(() => repo.initializeTransaction(
          amount: 15000.0,
          email: any(named: 'email'),
          identityType: 'yearly',
          callbackUrl: any(named: 'callbackUrl'),
        )).called(1);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/monetization/presentation/providers/paywall_provider_test.dart --timeout 60s`
Expected: FAIL — `startWebCheckout` not defined

- [ ] **Step 3: Implement**

In `paywall_provider.dart`:

```dart
import 'dart:html' show window; // web only — guard with kIsWeb
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/monetization/data/repositories/paystack_payment_repository.dart';

/// Web plan amounts in NGN (matching the old static Payment Page prices).
const webPlans = <String, double>{
  'monthly': 2500.0,
  'yearly': 15000.0,
};
```

In `PaywallController`:

```dart
  /// Web-only: initializes a Paystack transaction and redirects the browser
  /// to the Payment Page. The webhook flips isPremium on charge.success.
  Future<void> startWebCheckout({required String planKey}) async {
    if (!kIsWeb) return;
    final amount = webPlans[planKey];
    if (amount == null) {
      state = state.copyWith(isLoading: false, error: () => 'Unknown plan.');
      return;
    }
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final authUser = ref.read(authStateChangesProvider).valueOrNull;
      if (authUser == null || authUser.email.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: () => 'Please sign in before upgrading.',
        );
        return;
      }
      final repository = ref.read(paystackPaymentRepositoryProvider);
      final authorizationUrl = await repository.initializeTransaction(
        amount: amount,
        email: authUser.email,
        identityType: planKey,
        callbackUrl: '${Uri.base.origin}/order-confirmed',
      );
      state = state.copyWith(isLoading: false, error: () => null);
      // ignore: avoid_web_libraries_in_flutter
      window.location.assign(authorizationUrl);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: () => 'Checkout failed. Please try again.',
      );
    }
  }
```

NOTE: `dart:html` is web-only. For a pure widget-testable controller, split the redirect behind an injectable `void Function(String url)? redirect` callback (default `window.location.assign`). The test overrides it to capture the URL. Match the file's codegen (`@riverpod` → `.g.dart` must be regenerated with build_runner).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter pub run build_runner build --delete-conflicting-outputs && flutter test test/features/monetization/presentation/providers/paywall_provider_test.dart --timeout 60s`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
flutter analyze lib/features/monetization/presentation/providers/paywall_provider.dart
git add lib/features/monetization/presentation/providers/paywall_provider.dart lib/features/monetization/presentation/providers/paywall_provider.g.dart test/features/monetization/presentation/providers/paywall_provider_test.dart
git commit -m "feat(monetization): web checkout via Paystack with callback redirect"
```

---

## Task 4: Paywall screen — wire web checkout

**Files:**
- Modify: `lib/features/monetization/presentation/screens/paywall_screen.dart`

- [ ] **Step 1: Replace `_buildPaystackPurchase`**

In `paywall_screen.dart`:
- Delete `_monthlyPayUrl` / `_yearlyPayUrl` constants and `_openPaystackPage`.
- `_buildPaystackPurchase` now calls the controller:

```dart
  Widget _buildPaystackPurchase() {
    final paywallState = ref.watch(paywallControllerProvider);
    final busy = paywallState.isLoading;
    return Column(
      children: [
        _GoldShimmerButton(
          onPressed: busy
              ? () {}
              : () => ref
                  .read(paywallControllerProvider.notifier)
                  .startWebCheckout(planKey: 'yearly'),
          child: busy
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
              : const _CtaLabel(price: 'Best Value — ₦15,000/yr'),
        ),
        const Gap(12),
        InkWell(
          onTap: busy
              ? null
              : () => ref
                  .read(paywallControllerProvider.notifier)
                  .startWebCheckout(planKey: 'monthly'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            // ...existing monthly container, unchanged styling...
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month, color: Colors.white70, size: 18),
                Gap(8),
                Text('₦2,500 / month',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/features/monetization/presentation/screens/paywall_screen.dart && flutter test test/features/monetization/presentation/screens/paywall_screen_test.dart --timeout 60s`
Expected: analyze clean; existing paywall tests pass (adjust if any asserted the static URLs).

- [ ] **Step 3: Commit**

```bash
git add lib/features/monetization/presentation/screens/paywall_screen.dart
git commit -m "feat(monetization): paywall web checkout via Paystack callable"
```

---

## Task 5: `OrderConfirmedScreen` + route

**Files:**
- Create: `lib/features/monetization/presentation/screens/order_confirmed_screen.dart`
- Modify: `lib/core/router/router.dart`
- Test: `test/features/monetization/presentation/screens/order_confirmed_screen_test.dart`

- [ ] **Step 1: Write the failing widget test**

`test/features/monetization/presentation/screens/order_confirmed_screen_test.dart`:

```dart
import 'package:emerge_app/features/monetization/presentation/screens/order_confirmed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders confirmation with the reference', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: OrderConfirmedScreen(reference: 'PSK_abc123'),
    ));

    expect(find.text('Order complete'), findsOneWidget);
    expect(find.textContaining('PSK_abc123'), findsOneWidget);
    expect(find.text('Start exploring'), findsOneWidget);
  });

  testWidgets('renders fallback copy when reference is null', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: OrderConfirmedScreen(reference: null),
    ));

    expect(find.text('Order complete'), findsOneWidget);
    expect(find.textContaining('PSK'), findsNothing);
    expect(find.textContaining('Payment received'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/monetization/presentation/screens/order_confirmed_screen_test.dart --timeout 60s`
Expected: FAIL — module not found

- [ ] **Step 3: Write the screen**

`lib/features/monetization/presentation/screens/order_confirmed_screen.dart`:

```dart
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// Shown after a Paystack web checkout redirects back with a reference.
/// Pure receipt/acknowledgement — entitlement flips via the webhook stream.
class OrderConfirmedScreen extends StatelessWidget {
  final String? reference;

  const OrderConfirmedScreen({super.key, this.reference});

  @override
  Widget build(BuildContext context) {
    final referenceText = (reference == null || reference!.isEmpty)
        ? 'Payment received'
        : 'Reference: $reference';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 96, color: EmergeColors.teal),
                const Gap(24),
                const Text(
                  'Order complete',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(12),
                Text(
                  'Your payment went through. Welcome to Emerge Premium.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const Gap(24),
                SelectableText(
                  referenceText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const Gap(40),
                FilledButton(
                  onPressed: () => context.go('/timeline'),
                  style: FilledButton.styleFrom(
                    backgroundColor: EmergeColors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                  ),
                  child: const Text(
                    'Start exploring',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Register the route**

In `lib/core/router/router.dart`, next to `/paywall`:

```dart
      GoRoute(
        path: '/order-confirmed',
        builder: (context, state) => OrderConfirmedScreen(
          reference: state.uri.queryParameters['reference'],
        ),
      ),
```

Add the import.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/monetization/presentation/screens/order_confirmed_screen_test.dart --timeout 60s`
Expected: PASS

- [ ] **Step 6: Verify + commit**

```bash
flutter analyze lib/features/monetization/presentation/screens/order_confirmed_screen.dart lib/core/router/router.dart
flutter test test/features/monetization/presentation/screens/order_confirmed_screen_test.dart --timeout 60s
git add lib/features/monetization/presentation/screens/order_confirmed_screen.dart lib/core/router/router.dart test/features/monetization/presentation/screens/order_confirmed_screen_test.dart
git commit -m "feat(monetization): order-complete confirmation screen with reference"
```

---

## Self-Review (paystack plan)

**Spec coverage:** §4 function change → Task 1; §5.1 provider → Task 3; §5.2 paywall → Task 4; §5.3 screen → Task 5; §5.4 route → Task 5; §6 error handling → Tasks 3+4 (error snackbar via existing guard); §7 no rules change → verified; §8 tests → all tasks.

**Placeholders:** none.

**Type consistency:** `initializeTransaction({amount, email, identityType, callbackUrl?})` matches repo + provider; `startWebCheckout({required String planKey})` matches paywall; `OrderConfirmedScreen(reference)` matches route + tests; function request field is `callbackUrl` (camelCase) throughout.

**Note for implementer:** `dart:html` is web-only — inject the redirect callback for testability (Task 3 Step 3 note). `Uri.base.origin` gives the current origin; on the deployed web app this is the Firebase Hosting domain, which must be in `CALLBACK_ALLOWED_HOSTS` (Task 1, defaults `emerge.web.app,emerge.firebaseapp.com` — update to the real domain at deploy).

---

## Task 6: Full verification pass

- [ ] **Step 1: Functions**

```bash
cd functions && npm run build && npx eslint src/payments/paystack.ts && npx jest test/paystack.test.ts
```

- [ ] **Step 2: Flutter**

```bash
cd .. && flutter analyze lib/features/monetization lib/core/router/router.dart
flutter test test/features/monetization --timeout 60s
```
Expected: analyze clean, monetization tests pass. Do NOT run the full suite.

- [ ] **Step 3: Deploy notes (ops)**

1. Confirm `CALLBACK_ALLOWED_HOSTS` matches the live web domain (set via `firebase functions:config:set` or env when deploying).
2. `firebase deploy --only functions:initializePaystackTransaction`.
3. Release web app update.
4. Manual: web paywall → Paystack → test card `4084 0840 8408 4081` → redirect back to `/order-confirmed?reference=…` → premium flips.

- [ ] **Step 4: Final commit**

```bash
git add -A && git commit -m "chore: web paystack confirmation verification pass" || echo "nothing to commit"
```
