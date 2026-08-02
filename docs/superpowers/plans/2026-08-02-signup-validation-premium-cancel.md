# Signup Validation + Premium Cancel & Retention Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add real-time inline validation with a conditional password-requirements checklist to the signup forms, and a retention-psychology cancel flow for premium (Android + web) backed by a new `managePremium` Cloud Function.

**Architecture:** Two independent feature tracks that merge only at the Settings screen. Forms track: shared `PasswordRules` constants drive both `validatePassword` and a new `PasswordRequirementChecklist` widget, plus `AutovalidateMode.onUserInteraction` on both signup forms. Premium track: a pure `computePremiumState` maps Firestore premium records (active/paused/cancelled) for the web `isPremiumProvider`; a new `managePremium` callable (pause/cancel) revokes Firestore + claims on web; a 3-step cancel screen (loss framing → pause step → confirm) uses the callable on web and RevenueCat's `managementURL` on Android.

**Tech Stack:** Flutter (Riverpod codegen, go_router, fpdart `Either`, url_launcher), Firebase Cloud Functions Gen 2 (TS, jest), purchases_flutter 10.3.0.

## Global Constraints

- **Platform scope:** Android + web ONLY. **No iOS configuration** — no Info.plist/entitlement changes, no iOS branches, no App Store copy. (User decision, recorded in spec.)
- Web billing is Paystack (one-time charges, not recurring); web premium is granted per `users/{uid}.isPremium` — the new callable is a grant revocation, not a billing operation. Paystack refunds stay manual (out of scope).
- Apple/Google policy: **never** provide an in-app button that disables auto-renew. Android cancellation happens on the Google Play manage page via RevenueCat `managementURL`.
- Riverpod: `@riverpod` + `part 'file.g.dart'`, run `dart run build_runner build --delete-conflicting-outputs` after adding/changing providers. Never hand-edit `*.g.dart`.
- fpdart: repositories return `Either<String, T>` (monetization convention) — never throw across boundaries. The `managePremium` service returns `Either<String, void>`.
- `docs/design.md` §10.2: `AutovalidateMode.onUserInteraction`, errors below field, never over-validate untouched fields; §5.4: inline error persists until fixed.
- Checklist shows **only on the password field, never the confirm field** (user decision).
- TDD (Iron Law): failing test → watch it fail → minimal implementation → green. Do not run the full test suite — only focused tests + `dart analyze`.
- Commit per task. Never `git add -A` (working tree may carry pre-existing changes); stage only the task's files.

---

### Task 1: `PasswordRules` — single source of truth for password validation + checklist

**Files:**
- Create: `lib/core/utils/password_rules.dart`
- Modify: `lib/core/utils/validators.dart:47-96` (`validatePassword`)
- Test: `test/core/utils/password_rules_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `abstract final class PasswordRules` with:
  - `static const int minLength = 12`, `static const int maxLength = 128`, `static const int minCharacterClasses = 3`
  - `static bool hasUpper(String)`, `hasLower`, `hasDigit`, `hasSpecial`, `static int characterClasses(String)`
  - `static bool isCommon(String)`, `static bool hasSequentialChars(String)`, `static bool hasRepeatedChars(String)`
  - `static bool isValid(String value)` — all rules pass (length ≤ maxLength included)
  - `static final List<PasswordRule> checklistItems` where `PasswordRule` is `class PasswordRule { final String label; final bool Function(String value) passes; const PasswordRule({required this.label, required this.passes}); }` with labels: `'At least 12 characters'`, `'3 of 4 character types'`, `'No common or sequential passwords'`, `'No repeated characters'`.

- [ ] **Step 1: Write the failing test**

Create `test/core/utils/password_rules_test.dart`:

```dart
import 'package:emerge_app/core/utils/password_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordRules predicates', () {
    test('length rules', () {
      expect(PasswordRules.minLength, 12);
      expect(PasswordRules.maxLength, 128);
      expect(PasswordRules.hasUpper('aBc'), isTrue);
      expect(PasswordRules.hasLower('aBc'), isTrue);
      expect(PasswordRules.hasDigit('a1c'), isTrue);
      expect(PasswordRules.hasSpecial('a@c'), isTrue);
    });

    test('characterClasses counts the 4 classes', () {
      expect(PasswordRules.characterClasses('abc'), 1);
      expect(PasswordRules.characterClasses('abc1'), 2);
      expect(PasswordRules.characterClasses('aB1@'), 4);
    });

    test('isCommon catches leaked passwords and substrings', () {
      expect(PasswordRules.isCommon('password123'), isTrue);
      expect(PasswordRules.isCommon('Tr0ub4dor!'), isFalse);
    });

    test('hasSequentialChars catches abc and 321', () {
      expect(PasswordRules.hasSequentialChars('abcdef'), isTrue);
      expect(PasswordRules.hasSequentialChars('cba'), isTrue);
      expect(PasswordRules.hasSequentialChars('Tr0ub4dor!'), isFalse);
    });

    test('hasRepeatedChars catches aaa', () {
      expect(PasswordRules.hasRepeatedChars('paaaword'), isTrue);
      expect(PasswordRules.hasRepeatedChars('Tr0ub4dor!'), isFalse);
    });
  });

  group('checklistItems', () {
    test('items match the validator contract', () {
      // Every checklist item must have a label and a predicate, and a
      // password that fails ONLY that item must exist so the checklist can
      // never drift from validatePassword.
      expect(PasswordRules.checklistItems, hasLength(4));
      for (final item in PasswordRules.checklistItems) {
        expect(item.label, isNotEmpty);
        expect(item.passes('Tr0ub4dor!'), isTrue);
      }
    });

    test('isValid requires every checklist item', () {
      expect(PasswordRules.isValid('Tr0ub4dor!'), isTrue);
      expect(PasswordRules.isValid('short'), isFalse);
      expect(PasswordRules.isValid('aaaaaaaaaaaa'), isFalse); // repeated
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/utils/password_rules_test.dart`
Expected: FAIL — `target of URI doesn't exist: 'package:emerge_app/core/utils/password_rules.dart'`

- [ ] **Step 3: Write minimal implementation**

Create `lib/core/utils/password_rules.dart`:

```dart
/// Single source of truth for password rules.
///
/// `AppValidators.validatePassword` and the `PasswordRequirementChecklist`
/// both consume these — a rules change can never desync the UI from
/// validation.
class PasswordRule {
  final String label;
  final bool Function(String value) passes;
  const PasswordRule({required this.label, required this.passes});
}

abstract final class PasswordRules {
  static const int minLength = 12;
  static const int maxLength = 128;
  static const int minCharacterClasses = 3;

  static final RegExp _uppercase = RegExp(r'[A-Z]');
  static final RegExp _lowercase = RegExp(r'[a-z]');
  static final RegExp _digits = RegExp(r'[0-9]');
  static final RegExp _special = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
  static final RegExp _repeated = RegExp(r'(.)\1{2,}');

  static bool hasUpper(String v) => _uppercase.hasMatch(v);
  static bool hasLower(String v) => _lowercase.hasMatch(v);
  static bool hasDigit(String v) => _digits.hasMatch(v);
  static bool hasSpecial(String v) => _special.hasMatch(v);

  static int characterClasses(String v) => [
        hasUpper(v),
        hasLower(v),
        hasDigit(v),
        hasSpecial(v),
      ].where((b) => b).length;

  static final Set<String> _commonPasswords = {
    'password', '123456', '12345678', 'qwerty', 'abc123', 'password1',
    '123456789', '1234567', '12345', '1234567890', 'iloveyou', 'princess',
    'admin', 'welcome', '666666', 'football', '111111', '123123', '654321',
    'password123', 'qwerty123', 'qwertyuiop', 'asdfgh', 'zxcvbnm', 'letmein',
    'monkey', 'dragon', 'baseball', 'superman', 'master', '2019', '2020',
    '2021', '2022', '2023', '2024', '2025', '11111111', '00000000',
    'aaaaaaaa', 'passw0rd', 'admin123',
  };

  static bool isCommon(String value) {
    final normalized = value.toLowerCase();
    if (_commonPasswords.contains(normalized)) return true;
    for (final common in _commonPasswords.take(50)) {
      if (normalized.contains(common) &&
          common.length >= normalized.length * 0.5) {
        return true;
      }
    }
    return false;
  }

  static bool hasSequentialChars(String value) {
    final lower = value.toLowerCase();
    for (int i = 0; i <= lower.length - 3; i++) {
      final c1 = lower.codeUnitAt(i);
      final c2 = lower.codeUnitAt(i + 1);
      final c3 = lower.codeUnitAt(i + 2);
      if (c2 == c1 + 1 && c3 == c2 + 1) return true;
      if (c2 == c1 - 1 && c3 == c2 - 1) return true;
    }
    return false;
  }

  static bool hasRepeatedChars(String value) => _repeated.hasMatch(value);

  static bool isValid(String value) =>
      value.length >= minLength &&
      value.length <= maxLength &&
      !isCommon(value) &&
      characterClasses(value) >= minCharacterClasses &&
      !hasSequentialChars(value) &&
      !hasRepeatedChars(value);

  static final List<PasswordRule> checklistItems = [
    PasswordRule(
      label: 'At least 12 characters',
      passes: (v) => v.length >= minLength,
    ),
    PasswordRule(
      label: '3 of 4 character types',
      passes: (v) => characterClasses(v) >= minCharacterClasses,
    ),
    PasswordRule(
      label: 'No common or sequential passwords',
      passes: (v) => !isCommon(v) && !hasSequentialChars(v),
    ),
    PasswordRule(
      label: 'No repeated characters',
      passes: (v) => !hasRepeatedChars(v),
    ),
  ];
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/utils/password_rules_test.dart`
Expected: PASS (all groups green).

- [ ] **Step 5: Refactor `validatePassword` to consume `PasswordRules` (no behavior change)**

In `lib/core/utils/validators.dart`, replace the body of `validatePassword` (lines 47-96) and delete the now-unused private helpers `_isCommonPassword` (lines 205-266), `_hasRepeatedChars` (lines 268-271), `_hasSequentialChars` (lines 273-295) — their logic lives in `PasswordRules` now:

```dart
  // Password validation with enhanced security
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < PasswordRules.minLength) {
      return 'Password must be at least 12 characters long';
    }

    if (value.length > PasswordRules.maxLength) {
      return 'Password is too long';
    }

    if (PasswordRules.isCommon(value)) {
      return 'This password is too common. Please choose a stronger one.';
    }

    if (PasswordRules.characterClasses(value) <
        PasswordRules.minCharacterClasses) {
      return 'Password must include at least 3 of: uppercase, lowercase, numbers, special characters';
    }

    if (PasswordRules.hasSequentialChars(value)) {
      return 'Password cannot contain sequential characters (e.g., "abc", "123")';
    }

    if (PasswordRules.hasRepeatedChars(value)) {
      return 'Password cannot contain repeated characters (e.g., "aaa", "111")';
    }

    return null;
  }
```

Add the import at the top of `validators.dart` (alphabetical, with the other `package:emerge_app/...` imports — the file currently starts with `import 'package:flutter/foundation.dart';`-style imports; place it as the first import):

```dart
import 'package:emerge_app/core/utils/password_rules.dart';
```

- [ ] **Step 6: Run validator tests + analyze**

Run: `flutter test test/core/utils/ && dart analyze lib/core/utils`
Expected: PASS, no analyzer issues. (If a pre-existing `validators_test.dart` doesn't exist, the `flutter test` run still passes on the new file; `dart analyze` is the gate.)

- [ ] **Step 7: Commit**

```bash
git add lib/core/utils/password_rules.dart lib/core/utils/validators.dart test/core/utils/password_rules_test.dart
git commit -m "feat(validators): extract PasswordRules as single source of truth for password validation"
```

---

### Task 2: `PasswordRequirementChecklist` widget (conditional, ticks live)

**Files:**
- Create: `lib/features/auth/presentation/widgets/password_requirement_checklist.dart`
- Test: `test/features/auth/presentation/widgets/password_requirement_checklist_test.dart`

**Interfaces:**
- Consumes: `PasswordRules.checklistItems` (Task 1).
- Produces: `class PasswordRequirementChecklist extends StatelessWidget { const PasswordRequirementChecklist({super.key, required this.passwordController}); final TextEditingController passwordController; }` — visible only while the controller has text; hides when empty; collapses to one green line when all rules pass.

- [ ] **Step 1: Write the failing widget test**

Create `test/features/auth/presentation/widgets/password_requirement_checklist_test.dart`:

```dart
import 'package:emerge_app/features/auth/presentation/widgets/password_requirement_checklist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(TextEditingController controller) {
  return MaterialApp(
    home: Scaffold(
      body: PasswordRequirementChecklist(passwordController: controller),
    ),
  );
}

void main() {
  testWidgets('hidden while the password field is empty', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(controller));

    expect(find.byType(PasswordRequirementChecklist), findsOneWidget);
    expect(find.text('At least 12 characters'), findsNothing);
  });

  testWidgets('appears while typing and ticks items as rules pass',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(controller));
    controller.text = 'abc';
    await tester.pump();

    expect(find.text('At least 12 characters'), findsOneWidget);
    expect(find.text('3 of 4 character types'), findsOneWidget);

    controller.text = 'Tr0ub4dor!';
    await tester.pump();

    // All rules pass -> collapses to a single success line.
    expect(find.text('Password looks good'), findsOneWidget);
    expect(find.text('At least 12 characters'), findsNothing);
  });

  testWidgets('hides again when the field is cleared', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(controller));
    controller.text = 'abc';
    await tester.pump();
    expect(find.text('At least 12 characters'), findsOneWidget);

    controller.clear();
    await tester.pump();
    expect(find.text('At least 12 characters'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/presentation/widgets/password_requirement_checklist_test.dart`
Expected: FAIL — `target of URI doesn't exist`.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/auth/presentation/widgets/password_requirement_checklist.dart`:

```dart
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/utils/password_rules.dart';
import 'package:flutter/material.dart';

/// Live password-requirements checklist.
///
/// Visible only while the password field is being completed (non-empty),
/// per the design decision: never render on an untouched/empty field, and
/// never attach to the confirm-password field. When every rule passes the
/// list collapses to a single success line so a valid field stays compact.
class PasswordRequirementChecklist extends StatelessWidget {
  const PasswordRequirementChecklist({super.key, required this.passwordController});

  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: passwordController,
      builder: (context, _) {
        final value = passwordController.text;
        if (value.isEmpty) return const SizedBox.shrink();

        final allPass = PasswordRules.checklistItems
            .every((rule) => rule.passes(value));

        if (allPass) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: EmergeColors.teal),
                const SizedBox(width: 6),
                Text(
                  'Password looks good',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: EmergeColors.teal,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final rule in PasswordRules.checklistItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        rule.passes(value)
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: rule.passes(value)
                            ? EmergeColors.teal
                            : AppTheme.textSecondaryDark,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          rule.label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: rule.passes(value)
                                    ? AppTheme.textMainDark
                                    : AppTheme.textSecondaryDark,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
```

Check `EmergeColors.teal` and `AppTheme` exist and are exported as used elsewhere (they are — `signup_screen.dart` imports `emerge_colors.dart` and `app_theme.dart`). If `EmergeColors.teal` is not the exact color name, use the same token the signup screen uses (`EmergeColors.teal` per `signup_screen.dart:301`).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/presentation/widgets/password_requirement_checklist_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/widgets/password_requirement_checklist.dart test/features/auth/presentation/widgets/password_requirement_checklist_test.dart
git commit -m "feat(auth): add conditional password requirements checklist widget"
```

---

### Task 3: Wire into the user signup screen (real-time validation + checklist)

**Files:**
- Modify: `lib/features/auth/presentation/screens/signup_screen.dart` (Form at 259 + tablet Form at 674; password fields at 355-397 + ~789-830)
- Modify: `test/features/auth/presentation/screens/signup_screen_test.dart`

**Interfaces:**
- Consumes: `PasswordRequirementChecklist` (Task 2).
- Produces: both forms get `autovalidateMode: AutovalidateMode.onUserInteraction`; checklist inserted directly after the password `TextFormField` in **both** mobile and tablet blocks; the confirm field gets NO checklist.

- [ ] **Step 1: Write the failing tests**

Append to `test/features/auth/presentation/screens/signup_screen_test.dart`:

```dart
  testWidgets('errors appear only after interacting with a field',
      (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    // Untouched fields must not show errors on first frame.
    expect(find.text('Email is required'), findsNothing);
    expect(find.text('Username is required'), findsNothing);

    // Typing invalid text then leaving the field surfaces the error.
    await tester.enterText(find.byType(TextFormField).at(0), 'ab');
    await tester.pumpAndSettle();
    expect(find.text('Username is required'), findsNothing);
    expect(
      find.text('Username must be at least 3 characters long'),
      findsOneWidget,
    );
  });

  testWidgets('password checklist appears while typing, not on confirm field',
      (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    expect(find.text('At least 12 characters'), findsNothing);

    // Typing into the password field shows the checklist.
    await tester.enterText(find.byType(TextFormField).at(2), 'abc');
    await tester.pumpAndSettle();
    expect(find.text('At least 12 characters'), findsOneWidget);

    // Typing into the confirm field must NOT show the checklist — the
    // widget is attached only to the password field.
    await tester.enterText(find.byType(TextFormField).at(3), 'abc');
    await tester.pumpAndSettle();
    expect(find.byType(PasswordRequirementChecklist), findsOneWidget);
    expect(find.text('Password looks good'), findsNothing);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/presentation/screens/signup_screen_test.dart`
Expected: FAIL — first new test fails because errors show after `pumpAndSettle` with `AutovalidateMode.disabled` only on submit (empty submit shows errors in the existing "shows validation on empty submit" test — but the new test types `'ab'` and expects an error without submitting, which currently never appears).

- [ ] **Step 3: Implement — mobile block**

In `signup_screen.dart`:

1. Add the import (alphabetical with the other feature imports, near line 6):

```dart
import 'package:emerge_app/features/auth/presentation/widgets/password_requirement_checklist.dart';
```

2. Mobile `Form` (line 259):

```dart
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
```

3. After the mobile password field's `.animate(...)` line (line 397, `).animate(delay: 350.ms).fadeIn().slideX(begin: 0.02),`), insert before `const Gap(16),` (line 398):

```dart
                      PasswordRequirementChecklist(
                        passwordController: _passwordController,
                      ),
```

- [ ] **Step 4: Implement — tablet block**

4. Tablet `Form` (line 674):

```dart
                            child: Form(
                              key: _formKey,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              child: Column(
```

5. After the tablet password field's `.animate(...)` line (the tablet password field is the one with `validator: AppValidators.validatePassword` at ~line 826-830 — insert directly after its `.animate(...)` close, before `const Gap(16),`), insert:

```dart
                                  PasswordRequirementChecklist(
                                    passwordController: _passwordController,
                                  ),
```

(If exact line numbers drifted, the anchor is: the tablet password `TextFormField` with `controller: _passwordController` and `validator: AppValidators.validatePassword` — insert the checklist as the next child after that field's `.animate(...)` call.)

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/auth/presentation/screens/signup_screen_test.dart`
Expected: PASS (existing 4 tests + 2 new ones).

- [ ] **Step 6: Analyze + commit**

Run: `dart analyze lib/features/auth/presentation/screens/signup_screen.dart`
Expected: no issues.

```bash
git add lib/features/auth/presentation/screens/signup_screen.dart test/features/auth/presentation/screens/signup_screen_test.dart
git commit -m "feat(auth): real-time validation and password checklist on user signup"
```

---

### Task 4: Wire into the creator signup screen

**Files:**
- Modify: `lib/features/auth/presentation/screens/creator_signup_screen.dart` (Form at 236, password field at 288-320)
- Modify: `test/features/auth/presentation/screens/creator_signup_screen_test.dart`

**Interfaces:**
- Consumes: `PasswordRequirementChecklist` (Task 2).
- Produces: same behavior as Task 3 on the creator form (single shared form — no tablet duplicate).

**Harness (verified):** the existing test file uses `_buildTest({overrides, required router})` + `setMobileViewport(tester)`; fields are indexed `0`=Username, `1`=Email, `2`=Password, `3`=Confirm, `4`=Invite Code.

- [ ] **Step 1: Write the failing tests**

Add the import to `test/features/auth/presentation/screens/creator_signup_screen_test.dart` (with the other `emerge_app` imports):

```dart
import 'package:emerge_app/features/auth/presentation/widgets/password_requirement_checklist.dart';
```

Append these two tests:

```dart
  testWidgets('errors appear only after interacting with a field',
      (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(router: router));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'ab');
    await tester.pumpAndSettle();
    expect(
      find.text('Username must be at least 3 characters long'),
      findsOneWidget,
    );
  });

  testWidgets('password checklist appears while typing, not on confirm field',
      (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(router: router));
    await tester.pumpAndSettle();

    expect(find.text('At least 12 characters'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(2), 'abc');
    await tester.pumpAndSettle();
    expect(find.text('At least 12 characters'), findsOneWidget);

    // Confirm field gets real-time validation but never the checklist.
    await tester.enterText(find.byType(TextFormField).at(3), 'abc');
    await tester.pumpAndSettle();
    expect(find.byType(PasswordRequirementChecklist), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/presentation/screens/creator_signup_screen_test.dart`
Expected: FAIL on the new real-time test (no autovalidate yet).

- [ ] **Step 3: Implement**

In `creator_signup_screen.dart`:

1. Add import (alphabetical with other feature imports):

```dart
import 'package:emerge_app/features/auth/presentation/widgets/password_requirement_checklist.dart';
```

2. `Form` (line 236):

```dart
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
```

3. After the password field's `.animate(delay: 200.ms).fadeIn().slideX(begin: 0.02),` (line 320), insert before `const Gap(16),`:

```dart
              PasswordRequirementChecklist(
                passwordController: _passwordController,
              ),
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/auth/presentation/screens/creator_signup_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Analyze + commit**

Run: `dart analyze lib/features/auth/presentation/screens/creator_signup_screen.dart`
Expected: no issues.

```bash
git add lib/features/auth/presentation/screens/creator_signup_screen.dart test/features/auth/presentation/screens/creator_signup_screen_test.dart
git commit -m "feat(auth): real-time validation and password checklist on creator signup"
```

---

### Task 5: `computePremiumState` pure function + paused-web-premium reads

**Files:**
- Create: `lib/features/monetization/domain/models/premium_state.dart`
- Modify: `lib/features/monetization/data/services/web_premium_service.dart`
- Modify: `lib/features/monetization/presentation/providers/subscription_provider.dart:105-119` (`_buildFromFirestore`)
- Modify: `test/features/monetization/data/web_premium_service_test.dart`
- Test: `test/features/monetization/domain/premium_state_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `class PremiumState { final bool isPremium; final bool isPaused; final DateTime? premiumEndsAt; const PremiumState({required this.isPremium, this.isPaused = false, this.premiumEndsAt}); }`
  - `PremiumState computePremiumState({required Map<String, dynamic>? record, required DateTime now})` — pure: `isPremium == true` and (not paused, or `premiumEndsAt` in the future) → premium; paused + `premiumEndsAt` past → free; anything else → free.

- [ ] **Step 1: Write the failing test**

Create `test/features/monetization/domain/premium_state_test.dart`:

```dart
import 'package:emerge_app/features/monetization/domain/models/premium_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 2, 12);

  test('active premium doc is premium', () {
    final state = computePremiumState(
      record: {'isPremium': true},
      now: now,
    );
    expect(state.isPremium, isTrue);
  });

  test('missing or free doc is not premium', () {
    expect(computePremiumState(record: null, now: now).isPremium, isFalse);
    expect(
      computePremiumState(record: {'isPremium': false}, now: now).isPremium,
      isFalse,
    );
  });

  test('paused with future end date stays premium', () {
    final state = computePremiumState(
      record: {
        'isPremium': true,
        'subscriptionStatus': 'paused',
        'premiumEndsAt': now.add(const Duration(days: 30)),
      },
      now: now,
    );
    expect(state.isPremium, isTrue);
    expect(state.isPaused, isTrue);
    expect(state.premiumEndsAt, now.add(const Duration(days: 30)));
  });

  test('paused after end date is free', () {
    final state = computePremiumState(
      record: {
        'isPremium': true,
        'subscriptionStatus': 'paused',
        'premiumEndsAt': now.subtract(const Duration(days: 1)),
      },
      now: now,
    );
    expect(state.isPremium, isFalse);
  });

  test('cancelled doc is free', () {
    final state = computePremiumState(
      record: {
        'isPremium': false,
        'subscriptionStatus': 'cancelled',
        'cancelledAt': now,
      },
      now: now,
    );
    expect(state.isPremium, isFalse);
  });

  test('isPremium non-boolean values are not premium', () {
    expect(
      computePremiumState(record: {'isPremium': 'yes'}, now: now).isPremium,
      isFalse,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/monetization/domain/premium_state_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/monetization/domain/models/premium_state.dart`:

```dart
/// Premium state derived from a `users/{uid}` Firestore record.
///
/// Pure and time-injected so the pause/expiry matrix is unit-testable
/// without Firebase (the `decideRedirect` signature pattern).
class PremiumState {
  final bool isPremium;
  final bool isPaused;
  final DateTime? premiumEndsAt;

  const PremiumState({
    required this.isPremium,
    this.isPaused = false,
    this.premiumEndsAt,
  });
}

PremiumState computePremiumState({
  required Map<String, dynamic>? record,
  required DateTime now,
}) {
  if (record == null || record['isPremium'] != true) {
    return const PremiumState(isPremium: false);
  }

  final status = record['subscriptionStatus'] as String?;
  final endsAt = record['premiumEndsAt'] as DateTime?;

  if (status == 'paused') {
    if (endsAt != null && !endsAt.isAfter(now)) {
      return const PremiumState(isPremium: false);
    }
    return PremiumState(isPremium: true, isPaused: true, premiumEndsAt: endsAt);
  }

  return const PremiumState(isPremium: true);
}
```

Design note: the model stays import-free — `record['premiumEndsAt']` must already be a `DateTime`. The Firestore layer (which imports cloud_firestore) owns Timestamp→DateTime parsing before calling `computePremiumState` (per AGENTS.md's "Firestore Timestamp parsing" gotcha — never assume the raw type).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/monetization/domain/premium_state_test.dart`
Expected: PASS.

- [ ] **Step 5: Route `streamWebPremium` + `_buildFromFirestore` through `computePremiumState`**

Modify `lib/features/monetization/data/services/web_premium_service.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/monetization/domain/models/premium_state.dart';

/// Streams web premium status from the `users/{uid}` Firestore document.
///
/// The Paystack webhook (`functions/src/payments/paystack.ts:129-136`)
/// writes `users/{uid}.isPremium = true` (+ `premium_since`,
/// `identity_type`) on charge.success; the `managePremium` callable writes
/// `subscriptionStatus: "paused"` + `premiumEndsAt` (pause) or
/// `isPremium: false` (cancel). Existing rules
/// (`firestore.rules:283-290`, owner-read of `users/{userId}`) already
/// permit this read — no rules change needed. Emits `false` while the
/// document is missing, free, or a pause window has expired.
Stream<bool> streamWebPremium(FirebaseFirestore firestore, String uid) {
  return firestore
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => _recordToPremium(snap.data()));
}

/// Firestore-layer mapping: Timestamp -> DateTime, then the pure decision.
bool _recordToPremium(Map<String, dynamic>? data) {
  final endsAtRaw = data?['premiumEndsAt'];
  final parsed = <String, dynamic>{
    if (data != null) ...data,
    if (endsAtRaw != null)
      'premiumEndsAt': endsAtRaw is Timestamp
          ? endsAtRaw.toDate()
          : endsAtRaw is DateTime
              ? endsAtRaw
              : DateTime.tryParse(endsAtRaw.toString()),
  };
  return computePremiumState(record: parsed, now: DateTime.now()).isPremium;
}
```

Note: `DateTime.tryParse` may return null — fine, `computePremiumState` treats null `premiumEndsAt` as "still premium while paused" (no end date → stays paused-premium), matching the spec (pause without end date = indefinite). Keep it.

Modify `subscription_provider.dart` `_buildFromFirestore` (lines 105-119) to use the same mapping for its initial read:

```dart
  Future<bool> _buildFromFirestore(String uid) async {
    final firestore = ref.watch(firestoreProvider);
    final sub = streamWebPremium(firestore, uid).listen((isPremium) {
      state = AsyncValue.data(isPremium);
    });
    ref.onDispose(sub.cancel);
    try {
      final snap = await firestore.collection('users').doc(uid).get();
      return _recordToPremium(snap.data());
    } catch (e) {
      AppLogger.w('Web premium Firestore check failed', error: e);
      final cached = await _readCachedPremiumStatus();
      return cached ?? false;
    }
  }
```

To avoid duplicating `_recordToPremium`, export it from `web_premium_service.dart` (rename to `recordToPremium` with a doc comment; keep `_recordToPremium` name only if private — **use the public name**):

```dart
/// Firestore-layer mapping: Timestamp -> DateTime, then the pure decision.
/// Public so `IsPremium._buildFromFirestore` reuses it for the initial read.
bool recordToPremium(Map<String, dynamic>? data) { ... }
```

and in `subscription_provider.dart` import it and call `recordToPremium(snap.data())` (replace `snap.data()?['isPremium'] == true`).

- [ ] **Step 6: Extend the web premium service tests with paused cases**

Append to `test/features/monetization/data/web_premium_service_test.dart`:

```dart
  test('paused with future premiumEndsAt stays premium', () async {
    final fdb = FakeFirebaseFirestore();
    final values = <bool>[];
    final sub = streamWebPremium(fdb, 'uid-1').listen(values.add);

    await fdb.collection('users').doc('uid-1').set({
      'isPremium': true,
      'subscriptionStatus': 'paused',
      'premiumEndsAt':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    });
    await pumpEventQueue();

    expect(values.last, isTrue);
    await sub.cancel();
  });

  test('paused past premiumEndsAt is free', () async {
    final fdb = FakeFirebaseFirestore();
    final values = <bool>[];
    final sub = streamWebPremium(fdb, 'uid-1').listen(values.add);

    await fdb.collection('users').doc('uid-1').set({
      'isPremium': true,
      'subscriptionStatus': 'paused',
      'premiumEndsAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
    });
    await pumpEventQueue();

    expect(values.last, isFalse);
    await sub.cancel();
  });
```

- [ ] **Step 7: Run all monetization domain/service tests + analyze**

Run: `flutter test test/features/monetization/domain/premium_state_test.dart test/features/monetization/data/web_premium_service_test.dart && dart analyze lib/features/monetization`
Expected: PASS, no analyzer issues.

- [ ] **Step 8: Commit**

```bash
git add lib/features/monetization/domain/models/premium_state.dart lib/features/monetization/data/services/web_premium_service.dart lib/features/monetization/presentation/providers/subscription_provider.dart test/features/monetization/domain/premium_state_test.dart test/features/monetization/data/web_premium_service_test.dart
git commit -m "feat(monetization): pure premium-state model + paused web premium reads"
```

---

### Task 6: `managePremium` Cloud Function callable (pause/cancel, idempotent)

**Files:**
- Create: `functions/src/managePremium.ts`
- Modify: `functions/src/index.ts` (add export)
- Test: `functions/test/managePremium.test.ts`

**Interfaces:**
- Consumes: admin SDK (same mock pattern as `functions/test/creator_invites.test.ts`).
- Produces: `export const managePremium = onCall<{action: "pause" | "cancel"}>(...)` — auth required; `cancel` → `users/{uid}`: `{isPremium: false, subscriptionStatus: "cancelled", cancelledAt: serverTimestamp()}`, claims rewritten without `"premium"`; `pause` → `{subscriptionStatus: "paused", premiumEndsAt: Timestamp.fromDate(now+30d)}`, claims untouched. Returns `{ok: true, action, premium: false | true}`.

- [ ] **Step 1: Write the failing test**

Create `functions/test/managePremium.test.ts` (mirror the admin-mock boilerplate from `creator_invites.test.ts` — the `setCustomUserClaims`, `getUser`, `docGet`, `docSet`, `collection` fakes and the `firebase-admin` jest mock):

```ts
/**
 * Tests for managePremium.ts — offline mode (no emulator).
 * Run with: cd functions && npm run build && npx jest test/managePremium.test.ts
 *
 * NOTE: the firebase-admin mock MUST be registered before
 * firebase-functions-test loads (it imports firebase-admin at require time).
 */
const setCustomUserClaims = jest.fn().mockResolvedValue(undefined);
const getUser = jest.fn();
const docSet = jest.fn();
const docGet = jest.fn();
const collection = jest.fn((name: string) => ({
  doc: jest.fn((id?: string) => ({
    id: id ?? "auto-1",
    get: jest.fn(() => docGet(name, id)),
    set: docSet,
  })),
}));

const firestoreMock = jest.fn(() => ({ collection }));
(
  firestoreMock as unknown as {
    FieldValue: { serverTimestamp: () => string };
    Timestamp: { fromDate: (d: Date) => Date };
  }
).FieldValue = { serverTimestamp: () => "SERVER_TIMESTAMP" };
(
  firestoreMock as unknown as {
    Timestamp: { fromDate: (d: Date) => Date };
  }
).Timestamp = { fromDate: (d: Date) => d };

jest.mock("firebase-admin", () => ({
  apps: [],
  initializeApp: jest.fn(),
  firestore: firestoreMock,
  auth: () => ({ getUser, setCustomUserClaims }),
}));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { managePremium } = require("../src/managePremium");

beforeEach(() => {
  jest.clearAllMocks();
  getUser.mockResolvedValue({
    customClaims: { role: "user", activeEntitlements: ["premium"] },
  });
  docGet.mockResolvedValue({ exists: true, data: () => ({ isPremium: true }) });
});

describe("managePremium", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      managePremium.run({ auth: undefined, data: { action: "cancel" } })
    ).rejects.toHaveProperty("code", "unauthenticated");
  });

  it("rejects invalid action values", async () => {
    await expect(
      managePremium.run({ auth: { uid: "u1" }, data: { action: "refund" } })
    ).rejects.toHaveProperty("code", "invalid-argument");
  });

  it("cancel writes isPremium=false and removes the premium claim (merge-safe)", async () => {
    const result = await managePremium.run({
      auth: { uid: "u1" },
      data: { action: "cancel" },
    });

    expect(result).toEqual({ ok: true, action: "cancel", premium: false });
    expect(docSet).toHaveBeenCalledWith(
      {
        isPremium: false,
        subscriptionStatus: "cancelled",
        cancelledAt: "SERVER_TIMESTAMP",
      },
      { merge: true }
    );
    expect(setCustomUserClaims).toHaveBeenCalledWith("u1", {
      role: "user",
      activeEntitlements: [],
    });
  });

  it("cancel preserves unrelated claims", async () => {
    getUser.mockResolvedValue({
      customClaims: { role: "user", activeEntitlements: ["premium"], other: 1 },
    });
    await managePremium.run({
      auth: { uid: "u1" },
      data: { action: "cancel" },
    });
    expect(setCustomUserClaims).toHaveBeenCalledWith("u1", {
      role: "user",
      activeEntitlements: [],
      other: 1,
    });
  });

  it("pause writes paused status + 30-day end, leaves claims untouched", async () => {
    const result = await managePremium.run({
      auth: { uid: "u1" },
      data: { action: "pause" },
    });

    expect(result).toEqual({ ok: true, action: "pause", premium: true });
    const call = docSet.mock.calls[0][0];
    expect(call.subscriptionStatus).toBe("paused");
    expect(call.isPremium).toBeUndefined();
    expect(call.premiumEndsAt).toBeInstanceOf(Date);
    expect(setCustomUserClaims).not.toHaveBeenCalled();
  });

  it("cancel is idempotent — a second call succeeds identically", async () => {
    docGet.mockResolvedValue({
      exists: true,
      data: () => ({ isPremium: false, subscriptionStatus: "cancelled" }),
    });
    const first = await managePremium.run({
      auth: { uid: "u1" },
      data: { action: "cancel" },
    });
    const second = await managePremium.run({
      auth: { uid: "u1" },
      data: { action: "cancel" },
    });
    expect(first).toEqual({ ok: true, action: "cancel", premium: false });
    expect(second).toEqual(first);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npm run build && npx jest test/managePremium.test.ts`
Expected: FAIL — `Cannot find module '../src/managePremium'`.

- [ ] **Step 3: Write minimal implementation**

Create `functions/src/managePremium.ts`:

```ts
/**
 * managePremium — pause or cancel a user's premium entitlement.
 *
 * Web premium is a one-time Paystack charge (no recurring billing to stop),
 * so "cancel" is a grant revocation: clears `users/{uid}.isPremium` and the
 * `activeEntitlements` custom claim (merge-safe — never clobbers other
 * claims, mirroring setUserRole.ts). "pause" defers revocation by writing a
 * 30-day `premiumEndsAt` window; the client's `computePremiumState` treats a
 * paused doc as premium until that date.
 *
 * Firestore rules already forbid client writes to `isPremium`, so this
 * callable is the only revocation path. Paystack refunds stay manual.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const VALID_ACTIONS = ["pause", "cancel"] as const;
type ManagePremiumAction = (typeof VALID_ACTIONS)[number];

interface ManagePremiumRequest {
  action: ManagePremiumAction;
}

const PAUSE_DURATION_MS = 30 * 24 * 60 * 60 * 1000; // 30 days

export const managePremium = onCall<ManagePremiumRequest>(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const data = request.data;
  const action = data?.action;
  if (!action || !VALID_ACTIONS.includes(action)) {
    throw new HttpsError(
      "invalid-argument",
      `action must be one of: ${VALID_ACTIONS.join(", ")}.`
    );
  }

  const uid = request.auth.uid;
  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);
  const now = admin.firestore.FieldValue.serverTimestamp();

  if (action === "cancel") {
    await userRef.set(
      {
        isPremium: false,
        subscriptionStatus: "cancelled",
        cancelledAt: now,
      },
      { merge: true }
    );

    // Merge-safe claims rewrite: drop only the premium entitlement.
    const userRecord = await admin.auth().getUser(uid);
    const existingClaims = userRecord.customClaims ?? {};
    const entitlements = Array.isArray(existingClaims.activeEntitlements)
      ? (existingClaims.activeEntitlements as string[]).filter(
          (e) => e !== "premium"
        )
      : [];
    await admin.auth().setCustomUserClaims(uid, {
      ...existingClaims,
      activeEntitlements: entitlements,
    });

    return { ok: true, action: "cancel", premium: false };
  }

  await userRef.set(
    {
      subscriptionStatus: "paused",
      premiumEndsAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + PAUSE_DURATION_MS)
      ),
    },
    { merge: true }
  );

  return { ok: true, action: "pause", premium: true };
});
```

- [ ] **Step 4: Export from index.ts**

In `functions/src/index.ts`, add to the SUB-MODULE EXPORTS block (after `export * from "./creator_invites";` at line 264):

```ts
export { managePremium } from "./managePremium";
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd functions && npm run build && npx jest test/managePremium.test.ts`
Expected: PASS (all 6 cases).

- [ ] **Step 6: Commit**

```bash
git add functions/src/managePremium.ts functions/src/index.ts functions/test/managePremium.test.ts
git commit -m "feat(functions): add managePremium pause/cancel callable"
```

---

### Task 7: `openManageSubscription()` on the monetization repository (Android)

**Files:**
- Modify: `lib/features/monetization/domain/repositories/monetization_repository.dart`
- Modify: `lib/features/monetization/data/repositories/revenue_cat_repository.dart`

**Interfaces:**
- Consumes: existing repository; `purchases_flutter` `CustomerInfo.managementURL` (verified present in purchases_flutter 10.3.0, `customer_info_wrapper.dart:56`).
- Produces: `Future<Either<String, bool>> openManageSubscription()` on `MonetizationRepository` — gets `Purchases.getCustomerInfo().managementURL`, `launchUrl(url, mode: LaunchMode.externalApplication)`, returns `Right(true)`; `Left('...')` when not configured, no URL, or launch fails. Web is never the caller (screen guards with `kIsWeb`); still early-return `Left` if `_isConfigured` is false.

- [ ] **Step 1: Write the interface change (compile-time failing first)**

Modify `lib/features/monetization/domain/repositories/monetization_repository.dart` — add after `restorePurchases` (line 29):

```dart
  /// Open the platform's subscription management page (Google Play on
  /// Android) so the user can pause/cancel the auto-renewing subscription
  /// through the store — the only policy-compliant cancellation path.
  /// Returns Right(true) once the page was opened.
  Future<Either<String, bool>> openManageSubscription();
```

- [ ] **Step 2: Verify it fails to compile (no implementation yet)**

Run: `dart analyze lib/features/monetization`
Expected: FAIL — `RevenueCatRepository doesn't implement openManageSubscription`.

- [ ] **Step 3: Implement in `RevenueCatRepository`**

Add to `lib/features/monetization/data/repositories/revenue_cat_repository.dart` (after `restorePurchases`, line 295). Imports needed at top: `package:url_launcher/url_launcher.dart` (new), `package:flutter/foundation.dart` already imported (line 5):

```dart
  @override
  Future<Either<String, bool>> openManageSubscription() async {
    if (!_isConfigured) {
      return const Left('RevenueCat not configured');
    }
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final url = customerInfo.managementURL;
      if (url == null || url.isEmpty) {
        return const Left('No subscription management URL available');
      }
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        return const Left('Could not open subscription management page');
      }
      return const Right(true);
    } on PlatformException catch (e) {
      return Left(e.message ?? 'Failed to open subscription management');
    } catch (e) {
      return Left(e.toString());
    }
  }
```

- [ ] **Step 4: Analyze**

Run: `dart analyze lib/features/monetization`
Expected: PASS (no analyzer issues; `purchases_flutter` types resolve).

- [ ] **Step 5: Commit**

```bash
git add lib/features/monetization/domain/repositories/monetization_repository.dart lib/features/monetization/data/repositories/revenue_cat_repository.dart
git commit -m "feat(monetization): add openManageSubscription (RevenueCat managementURL)"
```

---

### Task 8: `ManagePremiumService` (callable wrapper) — TDD at the pure/service layer

**Files:**
- Create: `lib/features/monetization/data/services/manage_premium_service.dart`
- Create: `test/features/monetization/data/manage_premium_service_test.dart`

**Interfaces:**
- Consumes: `FirebaseFunctions` (cloud_functions 6.1.2).
- Produces: `class ManagePremiumService { ManagePremiumService(this._functions); Future<Either<String, void>> cancel(); Future<Either<String, void>> pause(); }` + `@riverpod ManagePremiumService managePremiumService(Ref ref) => ManagePremiumService(FirebaseFunctions.instance);`

- [ ] **Step 1: Write the failing test**

Create `test/features/monetization/data/manage_premium_service_test.dart` — mock `FirebaseFunctions` by wrapping the service's callable injection. `FirebaseFunctions` is a concrete class; the codebase precedent (`paystack_payment_repository.dart`) constructs it directly. For testability, define the service against an abstract seam:

```dart
import 'package:emerge_app/features/monetization/data/services/manage_premium_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeFunctions implements ManagePremiumCaller {
  final calls = <Map<String, dynamic>>[];
  bool throwError = false;

  @override
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data) async {
    if (throwError) throw Exception('boom');
    calls.add({...data, '_fn': name});
    return {'ok': true};
  }
}

void main() {
  test('cancel calls the callable with action cancel', () async {
    final fake = _FakeFunctions();
    final service = ManagePremiumService(fake);

    final result = await service.cancel();

    expect(result.isRight(), isTrue);
    expect(fake.calls.single['action'], 'cancel');
    expect(fake.calls.single['_fn'], 'managePremium');
  });

  test('pause calls the callable with action pause', () async {
    final fake = _FakeFunctions();
    final service = ManagePremiumService(fake);

    final result = await service.pause();

    expect(result.isRight(), isTrue);
    expect(fake.calls.single['action'], 'pause');
  });

  test('callable failure returns Left with a message', () async {
    final fake = _FakeFunctions()..throwError = true;
    final service = ManagePremiumService(fake);

    final result = await service.cancel();

    expect(result.isLeft(), isTrue);
    expect(result.fold((l) => l, (r) => ''), contains('boom'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/monetization/data/manage_premium_service_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/monetization/data/services/manage_premium_service.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'manage_premium_service.g.dart';

/// Thin seam so the service is testable without a Firebase emulator.
abstract interface class ManagePremiumCaller {
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data);
}

/// Default adapter over the Firebase Functions SDK.
class FirebaseFunctionsCaller implements ManagePremiumCaller {
  final FirebaseFunctions _functions;
  FirebaseFunctionsCaller(this._functions);

  @override
  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> data,
  ) async {
    final result = await _functions.httpsCallable(name).call(data);
    return result.data as Map<String, dynamic>;
  }
}

/// Calls the `managePremium` Cloud Function (pause/cancel).
///
/// Web is the primary consumer (grant revocation for a one-time Paystack
/// charge); the Android path uses the store manage page instead and never
/// calls this.
class ManagePremiumService {
  final ManagePremiumCaller _caller;

  ManagePremiumService(this._caller);

  Future<Either<String, void>> cancel() => _run('cancel');

  Future<Either<String, void>> pause() => _run('pause');

  Future<Either<String, void>> _run(String action) async {
    try {
      await _caller.call('managePremium', {'action': action});
      return const Right(null);
    } catch (e, s) {
      AppLogger.e('managePremium ($action) failed', e, s);
      return Left(e.toString());
    }
  }
}

@riverpod
ManagePremiumService managePremiumService(Ref ref) {
  return ManagePremiumService(FirebaseFunctionsCaller(FirebaseFunctions.instance));
}
```

- [ ] **Step 4: Generate the provider + run tests**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: generates `manage_premium_service.g.dart`.

Run: `flutter test test/features/monetization/data/manage_premium_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Analyze + commit**

Run: `dart analyze lib/features/monetization/data/services/manage_premium_service.dart`
Expected: no issues.

```bash
git add lib/features/monetization/data/services/manage_premium_service.dart lib/features/monetization/data/services/manage_premium_service.g.dart test/features/monetization/data/manage_premium_service_test.dart
git commit -m "feat(monetization): add ManagePremiumService callable wrapper"
```

---

### Task 9: `ManagePremiumScreen` — 3-step retention cancel flow

**Files:**
- Create: `lib/features/monetization/presentation/screens/manage_premium_screen.dart`
- Create: `test/features/monetization/presentation/screens/manage_premium_screen_test.dart`
- Modify: `lib/core/router/router.dart` (add `/manage-premium` top-level route)
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart:142-164` (tile → push route)
- Modify: `test/features/settings/presentation/screens/settings_screen_test.dart` (tile now navigates)

**Interfaces:**
- Consumes: `monetizationRepositoryProvider` (Task 7 `openManageSubscription`), `managePremiumServiceProvider` (Task 8), `userStreakProvider` (`lib/features/gamification/presentation/providers/user_stats_providers.dart:79`, `Stream<int>`), `habitsProvider` (`lib/features/habits/presentation/providers/habit_providers.dart:69`, `Stream<List<Habit>>`), `firestoreProvider` (web tenure line).
- Produces: `ManagePremiumScreen` (ConsumerStatefulWidget) with internal 3-step state machine: `_CancelStep { recap, pause, confirm }`; web cancel → `managePremiumService.cancel()`; Android confirm → `monetizationRepository.openManageSubscription()`; pause step on web → `managePremiumService.pause()`; pause step on Android → `openManageSubscription()` with adjusted copy. No iOS branches.

- [ ] **Step 1: Write the failing widget test**

Create `test/features/monetization/presentation/screens/manage_premium_screen_test.dart` (native path — widget tests run with `kIsWeb == false`):

```dart
import 'package:emerge_app/features/monetization/domain/repositories/monetization_repository.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/monetization/presentation/screens/manage_premium_screen.dart';
import 'package:emerge_app/features/monetization/data/services/manage_premium_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _FakeMonetizationRepository implements MonetizationRepository {
  int openManageCalls = 0;
  @override
  Future<Either<String, bool>> openManageSubscription() async {
    openManageCalls++;
    return const Right(true);
  }
  // Unused members — fail loudly if touched.
  @override
  Future<Either<String, Map<String, String>>> getConsumablePrices(List<String> productIds) async => const Left('unused');
  @override
  Future<Either<String, bool>> get isPremium async => const Right(true);
  @override
  Future<Either<String, Offerings>> getOfferings() async => const Left('unused');
  @override
  Future<void> identify(String uid) async {}
  @override
  Future<void> initialize({String? uid}) async {}
  @override
  Future<Either<String, bool>> purchaseConsumable(String productId) async => const Left('unused');
  @override
  Future<Either<String, bool>> purchasePremium([Package? package]) async => const Right(true);
  @override
  Future<Either<String, bool>> restorePurchases() async => const Right(true);
  @override
  Future<String?> get premiumPriceString async => '\$4.99/mo';
  @override
  Stream<bool> get premiumStatusStream => const Stream.empty();
  @override
  Future<void> reset() async {}
}

class _FakeManagePremiumService extends ManagePremiumService {
  _FakeManagePremiumService() : super(_FakeCaller());
  int cancelCalls = 0;
  int pauseCalls = 0;

  @override
  Future<Either<String, void>> cancel() async {
    cancelCalls++;
    return const Right(null);
  }

  @override
  Future<Either<String, void>> pause() async {
    pauseCalls++;
    return const Right(null);
  }
}

class _FakeCaller implements ManagePremiumCaller {
  @override
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data) async {
    return {'ok': true};
  }
}

class _FakeIsPremium extends IsPremium {
  final bool premium;
  _FakeIsPremium(this.premium);

  @override
  Future<bool> build() async => premium;
}

ProviderScope _pump({
  required MonetizationRepository repo,
  required ManagePremiumService service,
}) {
  return ProviderScope(
    overrides: [
      monetizationRepositoryProvider.overrideWithValue(repo),
      managePremiumServiceProvider.overrideWithValue(service),
      isPremiumProvider.overrideWith(() => _FakeIsPremium(true)),
      userStreakProvider.overrideWith((ref) => Stream.value(0)),
      habitsProvider.overrideWith((ref) => Stream.value(const [])),
    ],
    child: const MaterialApp(home: ManagePremiumScreen()),
  );
}

void main() {
  testWidgets('renders plan status and the cancel entry', (tester) async {
    await tester.pumpWidget(_pump(
      repo: _FakeMonetizationRepository(),
      service: _FakeManagePremiumService(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Manage Premium'), findsOneWidget);
    expect(find.text('Cancel subscription'), findsOneWidget);
  });

  testWidgets('cancel flow: recap -> pause step -> confirm opens store manage page',
      (tester) async {
    final repo = _FakeMonetizationRepository();
    final service = _FakeManagePremiumService();
    await tester.pumpWidget(_pump(repo: repo, service: service));
    await tester.pumpAndSettle();

    // Step 1 — loss framing + endowment recap.
    await tester.tap(find.text('Cancel subscription'));
    await tester.pumpAndSettle();
    expect(find.textContaining("You're about to lose"), findsOneWidget);
    expect(find.text('Keep Premium'), findsOneWidget);

    // Step 2 — pause/save step.
    await tester.tap(find.text('Continue cancelling'));
    await tester.pumpAndSettle();
    expect(find.text('Pause instead?'), findsOneWidget);

    // Step 3 — confirm; native opens the store manage page, never a callable.
    await tester.tap(find.text('Cancel anyway'));
    await tester.pumpAndSettle();
    expect(repo.openManageCalls, 1);
    expect(service.cancelCalls, 0);
    expect(find.textContaining('Google Play'), findsOneWidget);
  });
}
```

(The `Offerings`/`Package` types come from `purchases_flutter` — import `package:purchases_flutter/purchases_flutter.dart`; `userStreakProvider` comes from `package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart`; `habitsProvider` from `package:emerge_app/features/habits/presentation/providers/habit_providers.dart`; `IsPremium`/`isPremiumProvider` from `subscription_provider.dart`.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/monetization/presentation/screens/manage_premium_screen_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/monetization/presentation/screens/manage_premium_screen.dart`:

```dart
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/data/services/manage_premium_service.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// Manage Premium — plan status + retention-focused cancel flow.
///
/// Three steps: (1) endowment recap + loss framing, (2) pause/save step,
/// (3) confirm. Web cancellation revokes the grant via the `managePremium`
/// callable (Paystack charges are one-time); Android cancellation opens the
/// Google Play manage page via RevenueCat's `managementURL` — the only
/// policy-compliant path. No iOS configuration (platform scope decision).
class ManagePremiumScreen extends ConsumerStatefulWidget {
  const ManagePremiumScreen({super.key});

  @override
  ConsumerState<ManagePremiumScreen> createState() => _ManagePremiumScreenState();
}

enum _CancelStep { recap, pause, confirm, done }

class _ManagePremiumScreenState extends ConsumerState<ManagePremiumScreen> {
  _CancelStep _step = _CancelStep.recap;
  bool _busy = false;

  Future<void> _continueCancelling() async {
    setState(() => _step = _CancelStep.pause);
  }

  Future<void> _confirmCancel() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (kIsWeb) {
        final result = await ref.read(managePremiumServiceProvider).cancel();
        result.fold(
          (error) => messenger.showSnackBar(
            SnackBar(content: Text('Could not cancel premium: $error')),
          ),
          (_) {
            if (mounted) setState(() => _step = _CancelStep.done);
          },
        );
      } else {
        final result = await ref
            .read(monetizationRepositoryProvider)
            .openManageSubscription();
        result.fold(
          (error) => messenger.showSnackBar(
            SnackBar(content: Text('Could not open subscription settings: $error')),
          ),
          (_) => setState(() => _step = _CancelStep.done),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pauseInstead() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (kIsWeb) {
        final result = await ref.read(managePremiumServiceProvider).pause();
        result.fold(
          (error) => messenger.showSnackBar(
            SnackBar(content: Text('Could not pause premium: $error')),
          ),
          (_) => messenger.showSnackBar(
            const SnackBar(
              content: Text('Premium paused — your data stays safe. Resume anytime.'),
            ),
          ),
        );
      } else {
        final result = await ref
            .read(monetizationRepositoryProvider)
            .openManageSubscription();
        result.fold(
          (error) => messenger.showSnackBar(
            SnackBar(content: Text('Could not open pause options: $error')),
          ),
          (_) => messenger.showSnackBar(
            const SnackBar(
              content: Text('Google Play pause options opened — you can pause there.'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Premium')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: switch (_step) {
            _CancelStep.recap => _buildRecap(),
            _CancelStep.pause => _buildPauseStep(),
            _CancelStep.confirm => _buildConfirmStep(),
            _CancelStep.done => _buildDoneState(),
          },
        ),
      ),
    );
  }

  Widget _buildRecap() {
    final streak = ref.watch(userStreakProvider).value ?? 0;
    final habits = ref.watch(habitsProvider).value ?? const [];
    final activeHabits = habits.where((h) => !h.isArchived).length;
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    final price = ref.watch(monetizationRepositoryProvider).premiumPriceString;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "You're about to lose",
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: AppTheme.textMainDark, fontWeight: FontWeight.bold),
        ),
        const Gap(8),
        Text(
          isPremium
              ? 'Your Premium plan${price != null ? ' ($price)' : ''} includes:'
              : 'Your Premium plan includes:',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.textSecondaryDark),
        ),
        const Gap(16),
        const _BenefitRow('Unlimited active habits'),
        const _BenefitRow('Your Pro World'),
        const _BenefitRow('Daily AI coaching'),
        const _BenefitRow('Ad-free experience'),
        const Gap(24),
        if (streak > 0 || activeHabits > 0) ...[
          Text(
            'What you have built',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: EmergeColors.teal, fontWeight: FontWeight.w600),
          ),
          const Gap(8),
          if (streak > 0)
            Text(
              'A $streak-day streak',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMainDark),
            ),
          if (activeHabits > 0)
            Text(
              '$activeHabits active ${activeHabits == 1 ? 'habit' : 'habits'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMainDark),
            ),
          const Gap(24),
        ],
        _PrimaryButton(label: 'Keep Premium', onPressed: () => context.pop()),
        const Gap(12),
        OutlinedButton(
          onPressed: _busy ? null : _continueCancelling,
          child: const Text('Continue cancelling'),
        ),
      ],
    );
  }

  Widget _buildPauseStep() {
    final isWeb = kIsWeb;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pause instead?',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: AppTheme.textMainDark, fontWeight: FontWeight.bold),
        ),
        const Gap(8),
        Text(
          isWeb
              ? 'Pause keeps everything safe — your streak, habits, and world. '
                  'Resume anytime within 30 days.'
              : 'Pause keeps everything safe — your streak, habits, and world. '
                  'Google Play pause options open next.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.textSecondaryDark),
        ),
        const Gap(24),
        _PrimaryButton(
          label: isWeb ? 'Pause for 30 days' : 'Continue to pause options',
          onPressed: _busy ? null : _pauseInstead,
        ),
        const Gap(12),
        OutlinedButton(
          onPressed: _busy ? null : () => setState(() => _step = _CancelStep.confirm),
          child: const Text('Cancel anyway'),
        ),
        const Gap(12),
        TextButton(
          onPressed: () => setState(() => _step = _CancelStep.recap),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cancel Premium',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: AppTheme.textMainDark, fontWeight: FontWeight.bold),
        ),
        const Gap(8),
        Text(
          kIsWeb
              ? 'Cancelling ends your premium access now. Your account stays free — your data and world are safe.'
              : "You'll be redirected to Google Play to finish cancelling. "
                  'Your account stays free — your data and world are safe.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.textSecondaryDark),
        ),
        const Gap(24),
        _PrimaryButton(
          label: 'Confirm cancellation',
          onPressed: _busy ? null : _confirmCancel,
        ),
        const Gap(12),
        TextButton(
          onPressed: () => setState(() => _step = _CancelStep.pause),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _buildDoneState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 64, color: EmergeColors.teal),
        const Gap(16),
        Text(
          'Premium cancelled',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: AppTheme.textMainDark, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const Gap(8),
        Text(
          'Your account stays free — your data and world are safe.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.textSecondaryDark),
          textAlign: TextAlign.center,
        ),
        const Gap(24),
        _PrimaryButton(label: 'Done', onPressed: () => context.pop()),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.close, size: 16, color: EmergeColors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textMainDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: EmergeColors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
```

Note: the step enum includes `confirm`; the recap step's primary CTA is "Keep Premium" (returns). If the analyzer flags `setState` used inside `finally` before/after `mounted` checks, follow the existing screens' patterns (`mounted` guard — already present).

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/monetization/presentation/screens/manage_premium_screen_test.dart`
Expected: PASS. (If the fake's `openManageCalls` lands at 1 and the Google Play copy renders, the flow is verified.)

- [ ] **Step 5: Add the route**

In `lib/core/router/router.dart`, add next to the `/paywall` route (line 304-307):

```dart
      GoRoute(
        path: '/manage-premium',
        builder: (context, state) => const ManagePremiumScreen(),
      ),
```

Add the import at the top of `router.dart`:

```dart
import 'package:emerge_app/features/monetization/presentation/screens/manage_premium_screen.dart';
```

- [ ] **Step 6: Wire the Settings tile**

In `lib/features/settings/presentation/screens/settings_screen.dart`, replace the tile's `onTap` (lines 150-161):

```dart
                    onTap: () => context.push('/manage-premium'),
```

The `trailingText: isPremium ? 'Premium' : 'Free'` stays. (The `isPremium` watch stays for the trailing label.)

- [ ] **Step 7: Update/extend the settings screen test**

In `test/features/settings/presentation/screens/settings_screen_test.dart`, find the existing test that taps "Manage Subscription" (it currently asserts the "active Premium member" SnackBar) and replace that expectation:

**Settings harness (verified):** `createTest({settings, premium, quota, worldTheme})` returns a plain `MaterialApp(home: SettingsScreen())` with no router — `context.push` needs a router, and `ManagePremiumScreen` watches `userStreakProvider`/`habitsProvider`/`monetizationRepositoryProvider`/`managePremiumServiceProvider`. Modify the harness:

1. Add imports to `test/features/settings/presentation/screens/settings_screen_test.dart`:

```dart
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/monetization/presentation/screens/manage_premium_screen.dart';
```

2. Extend `createTest` (add `GoRouter? router` param; add provider overrides; wrap with `MaterialApp.router` when a router is given):

```dart
Widget createTest({
  FakeSettings? settings,
  bool premium = false,
  CoachAskQuota? quota,
  FakeWorldThemeNotifier? worldTheme,
  GoRouter? router,
}) {
  return ProviderScope(
    overrides: [
      // ... existing overrides unchanged ...
      isPremiumProvider.overrideWith(() => FakeIsPremium(premium)),
      habitsProvider.overrideWith((ref) => Stream.value(const [])),
      userStreakProvider.overrideWith((ref) => Stream.value(0)),
      monetizationRepositoryProvider.overrideWithValue(
        _FakeMonetizationRepository(),
      ),
      managePremiumServiceProvider.overrideWithValue(
        _FakeManagePremiumService(),
      ),
      // ... remaining existing overrides ...
    ],
    child: router != null
        ? MaterialApp.router(routerConfig: router)
        : const MaterialApp(home: SettingsScreen()),
  );
}
```

(Keep the existing `if (settings != null)` and quota overrides where they are; the two added fakes are file-private copies of Task 9 Step 1's `_FakeMonetizationRepository`/`_FakeManagePremiumService` — test files cannot import each other's private classes, so copy them into this file, and also copy `_FakeCaller` which `_FakeManagePremiumService` extends. Imports needed for the fakes: `fpdart`, `purchases_flutter`, `emerge_app/features/monetization/domain/repositories/monetization_repository.dart`, `emerge_app/features/monetization/data/services/manage_premium_service.dart`, `mocktail` if not already present.)

3. Add the navigation test:

```dart
  testWidgets('Manage Subscription tile navigates to manage premium',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(
          path: '/manage-premium',
          builder: (_, __) => const ManagePremiumScreen(),
        ),
      ],
    );

    await tester.pumpWidget(createTest(premium: true, router: router));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Manage Subscription'));
    await tester.pumpAndSettle();

    expect(find.text('Manage Premium'), findsOneWidget);
  });
```

Note: the existing tests keep calling `createTest()` with no router — their behavior is unchanged (no navigation attempted).

- [ ] **Step 8: Run full focused tests + analyze**

Run: `flutter test test/features/monetization/presentation/screens/manage_premium_screen_test.dart test/features/settings/presentation/screens/settings_screen_test.dart && dart analyze lib/features/monetization lib/features/settings lib/core/router`
Expected: PASS, no analyzer issues.

- [ ] **Step 9: Commit**

```bash
git add lib/features/monetization/presentation/screens/manage_premium_screen.dart test/features/monetization/presentation/screens/manage_premium_screen_test.dart lib/core/router/router.dart lib/features/settings/presentation/screens/settings_screen.dart test/features/settings/presentation/screens/settings_screen_test.dart
git commit -m "feat(monetization): manage premium screen with retention cancel flow + route"
```

---

### Task 10: End-to-end verification + smoke checklist

**Files:** none (verification only).

- [ ] **Step 1: Focused test sweep**

Run (all focused suites from the plan):

```bash
flutter test test/core/utils/password_rules_test.dart \
  test/features/auth/presentation/widgets/password_requirement_checklist_test.dart \
  test/features/auth/presentation/screens/signup_screen_test.dart \
  test/features/auth/presentation/screens/creator_signup_screen_test.dart \
  test/features/monetization/domain/premium_state_test.dart \
  test/features/monetization/data/web_premium_service_test.dart \
  test/features/monetization/data/manage_premium_service_test.dart \
  test/features/monetization/presentation/screens/manage_premium_screen_test.dart \
  test/features/settings/presentation/screens/settings_screen_test.dart
```

Expected: all green.

- [ ] **Step 2: Functions suite**

Run: `cd functions && npm run build && npx jest test/managePremium.test.ts`
Expected: PASS.

- [ ] **Step 3: Static analysis**

Run: `dart analyze`
Expected: no issues (only pre-existing ones, if any — verify none are newly introduced).

- [ ] **Step 4: Manual smoke (Android + web)**

- Signup (web + Android): fill fields → errors appear per-interaction only; checklist appears while typing password, ticks live, collapses to "Password looks good", hidden on empty field, absent under confirm password.
- Settings → Manage Subscription → Manage Premium: plan status shows; cancel flow steps render in order (recap → pause → confirm).
- Web cancel: after confirm, `isPremiumProvider` flips to free within seconds (stream); Firestore `users/{uid}` has `isPremium: false`, `subscriptionStatus: "cancelled"`; auth claims no longer include `premium`.
- Web pause: after pause, stays premium; after 30 days (manual backdate in Firestore for testing) flips free.
- Android cancel: Google Play manage page opens; never an in-app revoke.
- Re-upgrade: after web cancel, re-purchase via Paystack → premium returns (existing webhook path).
- **No iOS configuration was touched** (verify `git status` shows no `ios/` changes).
