# Creator Invite Code — Dashboard Discoverability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface the existing creator invite-code generation on the creator dashboard **Overview** tab (the "creator login dashboard") so the default creator can generate invite codes without the GCP CLI, and improve the error messaging to explain the real failure (10-code cap / verification).

**Architecture:** The feature already exists end-to-end (deployed callable `generateCreatorInviteCode` at `functions/src/index.ts:313`, Riverpod `CreatorInviteController` at `lib/features/social/presentation/providers/creator_invite_provider.dart`, working dialog + tests). The problems: (1) the dialog is a **private** `_InviteCreatorDialog` inside `creator_tribe_management_tab.dart` — only reachable inside the Tribe tab, invisible on the Overview; (2) its error message is generic and hides the real cause. Fix: extract the dialog into a public `CreatorInviteDialog` widget, add a pure error mapper, wire an "Invite Creators" card into the Overview tab, and update tests.

**Tech Stack:** Flutter, Riverpod, `cloud_functions` (existing dep), existing test conventions (`creator_invite_dialog_test.dart`).

---

### Task 1: Extract public `CreatorInviteDialog` + pure error mapper

**Files:**
- Create: `lib/features/social/presentation/screens/creator/creator_invite_messages.dart`
- Create: `lib/features/social/presentation/screens/creator/creator_invite_dialog.dart`
- Modify: `lib/features/social/presentation/screens/creator/creator_tribe_management_tab.dart`
- Test: `test/features/social/domain/services/creator_invite_messages_test.dart` (create `test/features/social/presentation/screens/creator/creator_invite_messages_test.dart` if the domain dir is preferred — use the presentation path to mirror the source file)
- Modify: `test/features/social/presentation/screens/creator/creator_invite_dialog_test.dart`

- [ ] **Step 1: Write the failing mapper test**

Create `test/features/social/presentation/screens/creator/creator_invite_messages_test.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_invite_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps resource-exhausted to the outstanding-code limit message', () {
    const error = FirebaseFunctionsException(
      code: 'resource-exhausted',
      message: 'limit reached',
    );
    final message = inviteCodeErrorMessage(error);
    expect(message, contains('10 outstanding'));
    expect(message, contains('expiry'));
  });

  test('maps permission-denied to the verification message', () {
    const error = FirebaseFunctionsException(
      code: 'permission-denied',
      message: 'denied',
    );
    final message = inviteCodeErrorMessage(error);
    expect(message, contains('verified creators'));
  });

  test('falls back to a generic message for unknown errors', () {
    expect(inviteCodeErrorMessage(Exception('boom')), contains('Could not'));
    expect(inviteCodeErrorMessage('plain string'), contains('Could not'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/screens/creator/creator_invite_messages_test.dart --timeout 120s`
Expected: FAIL — missing `creator_invite_messages.dart`

- [ ] **Step 3: Implement the mapper**

Create `lib/features/social/presentation/screens/creator/creator_invite_messages.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';

/// Maps a failed `generateCreatorInviteCode` call to a user-facing message.
/// Returns the specific cause when known (10-code cap, verification), else a
/// generic retry prompt.
String inviteCodeErrorMessage(Object error) {
  if (error is FirebaseFunctionsException) {
    switch (error.code) {
      case 'resource-exhausted':
        return 'You have 10 outstanding invite codes — redeem one or wait for '
            'expiry before generating another.';
      case 'permission-denied':
        return 'Only verified creators can generate invite codes.';
    }
  }
  return 'Could not generate an invite code. Try again in a moment.';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/screens/creator/creator_invite_messages_test.dart --timeout 120s`
Expected: PASS (3 tests)

- [ ] **Step 5: Extract the dialog (move verbatim, rename, use mapper)**

Create `lib/features/social/presentation/screens/creator/creator_invite_dialog.dart` — move the `_InviteCreatorDialog` widget (currently `creator_tribe_management_tab.dart:508-655`) verbatim with these changes:
- Class renamed `_InviteCreatorDialog` → `CreatorInviteDialog` (public), same constructor shape (`const CreatorInviteDialog({super.key})`).
- `_generate()` catch block uses the mapper:

```dart
    } catch (e) {
      if (mounted) {
        setState(() => _error = inviteCodeErrorMessage(e));
      }
    }
```

- Imports needed in the new file (gather from what the moved code uses): `package:flutter/material.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `package:gap/gap.dart`, `package:emerge_app/core/theme/emerge_colors.dart`, `package:flutter/services.dart` (Clipboard), `package:emerge_app/features/social/presentation/providers/creator_invite_provider.dart`, and `creator_invite_messages.dart`.

- [ ] **Step 6: Slim the tribe tab**

In `lib/features/social/presentation/screens/creator/creator_tribe_management_tab.dart`:
- Delete the private `_InviteCreatorDialog` class (lines 508-655) and the now-unused imports (verify by `dart analyze` on the file: remove `creator_invite_provider.dart` import only if nothing else in the file uses it — the provider import stays if used elsewhere in the file; check first).
- Replace `_showInviteCreatorDialog` (line 500-505) with:

```dart
  void _showInviteCreatorDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => const CreatorInviteDialog(),
    );
  }
```

- Add import: `package:emerge_app/features/social/presentation/screens/creator/creator_invite_dialog.dart`.

- [ ] **Step 7: Adapt the existing dialog test**

In `test/features/social/presentation/screens/creator/creator_invite_dialog_test.dart`, the harness pumps the dialog — if it references `_InviteCreatorDialog` (private) via the tribe tab, change it to pump `CreatorInviteDialog` directly in a `MaterialApp` (the existing harness mocks: `firebaseFunctionsProvider.overrideWithValue(_MockFunctions())` etc. stay as-is). Keep all existing assertions green; add one assertion that a `FirebaseFunctionsException(code: 'resource-exhausted')` thrown by the mocked callable surfaces the '10 outstanding' message.

- [ ] **Step 8: Run all focused tests**

Run: `flutter test test/features/social/presentation/screens/creator/creator_invite_messages_test.dart test/features/social/presentation/screens/creator/creator_invite_dialog_test.dart test/features/social/presentation/screens/creator/creator_tribe_management_tab_test.dart --timeout 120s`
Expected: PASS (all)

- [ ] **Step 9: Commit**

```bash
git add lib/features/social/presentation/screens/creator/creator_invite_messages.dart lib/features/social/presentation/screens/creator/creator_invite_dialog.dart lib/features/social/presentation/screens/creator/creator_tribe_management_tab.dart test/features/social/presentation/screens/creator/creator_invite_messages_test.dart test/features/social/presentation/screens/creator/creator_invite_dialog_test.dart
git commit -m "feat(creator): public CreatorInviteDialog with specific error messages"
```

---

### Task 2: Surface invite generation on the Overview tab

**Files:**
- Modify: `lib/features/social/presentation/screens/creator/creator_overview_tab.dart`
- Modify: `test/features/social/presentation/screens/creator/creator_overview_tab_test.dart`

- [ ] **Step 1: Write the failing widget test**

Append to `test/features/social/presentation/screens/creator/creator_overview_tab_test.dart` (use the file's existing harness — it already overrides the profile/blueprint providers):

```dart
  testWidgets('overview shows the Invite Creators entry', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Invite Creators'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/screens/creator/creator_overview_tab_test.dart --timeout 120s`
Expected: FAIL — no 'Invite Creators' text

- [ ] **Step 3: Add the nav card**

In `lib/features/social/presentation/screens/creator/creator_overview_tab.dart`, in the MANAGE section, insert after the Tribe Management `_NavCard` (after line 201's `const Gap(10),`):

```dart
              _NavCard(
                icon: Icons.card_giftcard_rounded,
                title: 'Invite Creators',
                subtitle: 'Generate a single-use invite code',
                color: EmergeColors.warmGold,
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (ctx) => const CreatorInviteDialog(),
                ),
              ),
              const Gap(10),
```

Add import: `package:emerge_app/features/social/presentation/screens/creator/creator_invite_dialog.dart`.
(Verify `EmergeColors.warmGold` exists — it is used by the dialog's generate button; if the overview file doesn't import `emerge_colors.dart`, add it.)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/screens/creator/creator_overview_tab_test.dart --timeout 120s`
Expected: PASS (existing + new test)

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/screens/creator/creator_overview_tab.dart test/features/social/presentation/screens/creator/creator_overview_tab_test.dart
git commit -m "feat(creator): invite-code generation entry on the dashboard overview"
```

---

### Task 3: Verification

**Files:** none (verification only)

- [ ] **Step 1: Static analysis**

Run: `dart analyze lib/features/social test/features/social`
Expected: `No issues found!` (fix any issues in the touched files and re-run)

- [ ] **Step 2: Full focused test pass**

Run: `flutter test test/features/social/presentation/screens/creator/ --timeout 120s`
Expected: PASS (all creator screen tests: blueprint_builder, blueprints_tab, create_challenge_dialog, dashboard_scaffold, invite_dialog, invite_messages, overview_tab, tribe_management)

- [ ] **Step 3: Commit any analyzer fixes**

If Step 1 changed files:

```bash
git add lib/features/social test/features/social
git commit -m "chore(creator): analyzer cleanups for invite dialog extraction"
```

---

## Notes for the implementer

- Do NOT run the full test suite — only the focused files listed. Use `--timeout 120s`.
- Do NOT run multiple commands at once.
- The working tree has unrelated staged/unstaged WIP (release 1.0.7, reflections work). Stage ONLY the files each task names — never `git add -A` or `git add .`. Verify each commit with `git show --stat HEAD`.
- The dialog move is a verbatim extraction — do not redesign the UI; only rename the class and swap the error message to the mapper.
- The `creator_invite_dialog_test.dart` harness already mocks `firebaseFunctionsProvider` (existing pattern) — preserve it.
