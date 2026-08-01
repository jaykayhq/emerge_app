# SP-C: Theme Lock ("Coming Soon") — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep "Cosmic Nebula" (`AppWorldTheme.nebula`) as the only selectable world theme and lock the other five (`forest`, `city`, `mountain`, `ocean`, `volcanic`) with a "COMING SOON" treatment — dimmed tiles + badge in the Settings picker, a non-blocking "Coming soon" snackbar on tap, and a source-level guard in `WorldThemeNotifier` so nothing can select or persist a locked theme.

**Architecture:** A pure `ThemeLock` unit (`lib/core/domain/services/theme_lock.dart`) is the single source of truth (`isLocked` / `safeTheme` / `unlockedTheme = nebula`). `WorldThemeNotifier` (plain, non-annotated `Notifier` + manual `NotifierProvider`) consumes it in `setTheme` (locked → early return, no state change, no prefs write) and in `_loadFromPrefs` (legacy locked value → clamped to nebula). The private `_WorldThemePicker` in `settings_screen.dart` (71 lines, lines 1342–1412 — stays in place, under the 100-line extraction threshold) consumes it in `itemBuilder`: locked tiles dim with a "COMING SOON" chip (top-right) and taps show a `ScaffoldMessenger` floating snackbar ("Coming soon", `hideCurrentSnackBar` first) instead of calling `onSelect`. The existing `onSelect: (theme) => ref.read(worldThemeProvider.notifier).setTheme(theme)` wiring (lines 85–86) is unchanged. The timeline's `themeOverride: AppWorldTheme.nebula` hardcode (timeline_screen.dart:329) is untouched — it already pins the timeline to nebula regardless.

**Tech Stack:** Flutter 3.x, Dart 3.10+, Riverpod 3.x (plain `NotifierProvider` — **no codegen, no `build_runner`** in this plan), shared_preferences, flutter_test + mocktail. Mirrors SP-A's pure-domain pattern (`CoachAskQuota`) and the existing settings test harness.

**Spec:** `docs/superpowers/specs/2026-08-01-sp-c-theme-lock-design.md`

---

## ⚠️ Pre-flight (read first)

1. **The working tree is dirty** (pre-existing uncommitted changes across ~30 files from earlier sessions — same condition SP-A documented). **Commit only the files each task names** — never `git add -A` or `git add lib` wholesale.
2. **Run `dart analyze lib` before starting** to establish the baseline error count. Only SP-C-introduced errors are this plan's responsibility.
3. **No codegen.** `worldThemeProvider` is a plain `Notifier` with a manual `NotifierProvider` (`lib/core/presentation/providers/world_theme_provider.dart`). None of these tasks add `@Riverpod` annotations or `.g.dart` files — no `build_runner` step exists in this plan.
4. **Verified call sites:** `setTheme` has exactly one caller — `settings_screen.dart:86`. `worldThemeProvider` is watched by `settings_screen.dart:49` and `world_background.dart:33` (`theme = themeOverride ?? ref.watch(worldThemeProvider)`). `WorldBackground` wraps its child in a `Scaffold` (world_background.dart:49), so snackbars work inside the picker.
5. `_WorldThemePicker` renders `theme.displayName.split(' ').first` as the tile label — the visible labels are 'Cosmic', 'Living', 'Neon', 'Sacred', 'Ocean', 'Volcanic'. Tests must use these short labels.
6. The existing settings test harness (`test/features/settings/presentation/screens/settings_screen_test.dart`) uses `await tester.pump()` twice and **never** `pumpAndSettle` (WorldBackground runs continuous animations — `pumpAndSettle` would hang). Follow that rhythm.

## File structure

### New files

| Path | Responsibility |
|---|---|
| `lib/core/domain/services/theme_lock.dart` | Pure lock logic (`isLocked` / `safeTheme` / `unlockedTheme`) — first file in new `lib/core/domain/services/` dir |
| `test/core/domain/services/theme_lock_test.dart` | Unit tests, full 6-theme matrix |
| `test/core/presentation/providers/world_theme_provider_test.dart` | Provider guard tests with `SharedPreferences.setMockInitialValues` |

### Modified files

| Path | Change |
|---|---|
| `lib/core/presentation/providers/world_theme_provider.dart` | `setTheme`: locked → early return; `_loadFromPrefs`: `state = ThemeLock.safeTheme(theme)` |
| `lib/features/settings/presentation/screens/settings_screen.dart` | `_WorldThemePicker` itemBuilder: `isLocked` dim + chip + snackbar tap routing; add `theme_lock.dart` import |
| `test/features/settings/presentation/screens/settings_screen_test.dart` | `FakeWorldThemeNotifier` gains recording `setCalls`; new "World theme lock" test group |

### Deleted files

None.

---

# Phase 1 — Pure foundation (TDD)

## Task 1: `ThemeLock` pure domain + tests

**Files:**
- Create: `lib/core/domain/services/theme_lock.dart`
- Test: `test/core/domain/services/theme_lock_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/domain/services/theme_lock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeLock', () {
    test('unlockedTheme is the nebula default', () {
      expect(ThemeLock.unlockedTheme, AppWorldTheme.nebula);
    });

    test('nebula is unlocked', () {
      expect(ThemeLock.isLocked(AppWorldTheme.nebula), isFalse);
    });

    test('every other theme is locked', () {
      for (final theme in AppWorldTheme.values) {
        if (theme == AppWorldTheme.nebula) continue;
        expect(ThemeLock.isLocked(theme), isTrue, reason: '$theme should be locked');
      }
    });

    test('safeTheme passes the unlocked theme through', () {
      expect(ThemeLock.safeTheme(AppWorldTheme.nebula), AppWorldTheme.nebula);
    });

    test('safeTheme clamps every locked theme to nebula', () {
      for (final theme in AppWorldTheme.values) {
        expect(ThemeLock.safeTheme(theme), AppWorldTheme.nebula);
      }
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/domain/services/theme_lock_test.dart`
Expected: FAIL with "Target of URI doesn't exist: '...theme_lock.dart'"

- [ ] **Step 3: Implement the lock**

```dart
// lib/core/domain/services/theme_lock.dart
import 'package:emerge_app/core/domain/models/app_world_theme.dart';

/// Single source of truth for which world themes are selectable.
///
/// `nebula` (Cosmic Nebula) is the main theme and stays unlocked; all
/// others are "coming soon" and locked. Deliberately free of Flutter,
/// storage, and Riverpod so it can be unit-tested without widgets
/// (mirrors CoachAskQuota / resolveBackgroundAsset).
class ThemeLock {
  /// The one theme users can select today.
  static const AppWorldTheme unlockedTheme = AppWorldTheme.nebula;

  static bool isLocked(AppWorldTheme theme) => theme != unlockedTheme;

  /// Clamps any theme to [unlockedTheme] when it is locked.
  /// Used on load so a legacy persisted locked value can never re-activate.
  static AppWorldTheme safeTheme(AppWorldTheme theme) =>
      isLocked(theme) ? unlockedTheme : theme;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/domain/services/theme_lock_test.dart`
Expected: PASS — 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/core/domain/services/theme_lock.dart test/core/domain/services/theme_lock_test.dart
git commit -m "feat(theme): add ThemeLock pure domain (nebula unlocked, rest locked)"
```

---

# Phase 2 — Provider guard (TDD)

## Task 2: Guard `WorldThemeNotifier` + tests

**Files:**
- Modify: `lib/core/presentation/providers/world_theme_provider.dart`
- Test: `test/core/presentation/providers/world_theme_provider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/presentation/providers/world_theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kKey = 'app_world_theme';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('setTheme ignores a locked theme and never persists it', () async {
    final container = makeContainer();
    await container
        .read(worldThemeProvider.notifier)
        .setTheme(AppWorldTheme.forest);

    expect(container.read(worldThemeProvider), AppWorldTheme.nebula);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_kKey), isNull);
  });

  test('setTheme persists the unlocked theme', () async {
    final container = makeContainer();
    await container
        .read(worldThemeProvider.notifier)
        .setTheme(AppWorldTheme.nebula);

    expect(container.read(worldThemeProvider), AppWorldTheme.nebula);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_kKey), 'nebula');
  });

  test('legacy locked value in prefs loads as nebula', () async {
    SharedPreferences.setMockInitialValues({_kKey: 'forest'});
    final container = makeContainer();

    // build() returns nebula synchronously; _loadFromPrefs resolves async.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(worldThemeProvider), AppWorldTheme.nebula);
  });

  test('unknown saved value loads as nebula', () async {
    SharedPreferences.setMockInitialValues({_kKey: 'jupiter'});
    final container = makeContainer();

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(worldThemeProvider), AppWorldTheme.nebula);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/presentation/providers/world_theme_provider_test.dart`
Expected: FAIL — "setTheme ignores a locked theme" fails because `setTheme(forest)` currently sets state and writes `'forest'` to prefs.

- [ ] **Step 3: Implement the guard**

In `lib/core/presentation/providers/world_theme_provider.dart`, add `import 'package:emerge_app/core/domain/services/theme_lock.dart';` and change `setTheme` + `_loadFromPrefs`:

```dart
  Future<void> setTheme(AppWorldTheme theme) async {
    // Locked themes are "coming soon": ignore entirely (no state change,
    // no prefs write) so no call site can bypass the lock.
    if (ThemeLock.isLocked(theme)) return;
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWorldThemeKey, theme.name);
  }
```

```dart
      final theme = AppWorldTheme.values.firstWhere(
        (t) => t.name == saved,
        orElse: () => AppWorldTheme.nebula,
      );
      // Legacy users may have a locked theme persisted from before the
      // lock shipped — clamp it so it can never re-activate.
      state = ThemeLock.safeTheme(theme);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/presentation/providers/world_theme_provider_test.dart`
Expected: PASS — 4 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/core/presentation/providers/world_theme_provider.dart test/core/presentation/providers/world_theme_provider_test.dart
git commit -m "feat(theme): guard WorldThemeNotifier against locked themes (setTheme + load clamp)"
```

---

# Phase 3 — Picker UI (TDD)

## Task 3: Locked tiles + snackbar in `_WorldThemePicker` + widget tests

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`
- Modify: `test/features/settings/presentation/screens/settings_screen_test.dart`

- [ ] **Step 1: Extend the test harness — recording `FakeWorldThemeNotifier`**

In `test/features/settings/presentation/screens/settings_screen_test.dart`, replace the existing `FakeWorldThemeNotifier` (lines 34–37) with a recording version, and thread it through `createTest`:

```dart
class FakeWorldThemeNotifier extends WorldThemeNotifier {
  final List<AppWorldTheme> setCalls = [];

  @override
  AppWorldTheme build() => AppWorldTheme.nebula;

  @override
  Future<void> setTheme(AppWorldTheme theme) async {
    setCalls.add(theme);
    await super.setTheme(theme); // real guard runs: locked calls no-op
  }
}
```

Change `createTest` to accept an optional notifier (default keeps existing behavior):

```dart
Widget createTest({
  FakeSettings? settings,
  bool premium = false,
  CoachAskQuota? quota,
  FakeWorldThemeNotifier? worldTheme,
}) {
  return ProviderScope(
    overrides: [
      // ...existing overrides unchanged...
      worldThemeProvider.overrideWith(() => worldTheme ?? FakeWorldThemeNotifier()),
      // ...
    ],
    child: const MaterialApp(
      home: SettingsScreen(),
    ),
  );
}
```

- [ ] **Step 2: Write the failing widget tests**

Append a new group inside `main()` in the same test file:

```dart
  group('World theme lock', () {
    testWidgets('locked tiles show a COMING SOON chip', (tester) async {
      await tester.pumpWidget(createTest());
      await tester.pump();
      await tester.pump();

      await tester.ensureVisible(find.text('Cosmic'));
      await tester.pump();

      // nebula unlocked; the other five themes locked.
      expect(find.text('COMING SOON'), findsNWidgets(5));
    });

    testWidgets('tapping a locked tile shows the snackbar and selects nothing',
        (tester) async {
      final worldTheme = FakeWorldThemeNotifier();
      await tester.pumpWidget(createTest(worldTheme: worldTheme));
      await tester.pump();
      await tester.pump();

      await tester.ensureVisible(find.text('Living'));
      await tester.pump();
      await tester.tap(find.text('Living'));
      await tester.pump();

      expect(find.text('Coming soon'), findsOneWidget);
      expect(worldTheme.setCalls, isEmpty);
    });

    testWidgets('tapping the unlocked theme selects it without a snackbar',
        (tester) async {
      final worldTheme = FakeWorldThemeNotifier();
      await tester.pumpWidget(createTest(worldTheme: worldTheme));
      await tester.pump();
      await tester.pump();

      await tester.ensureVisible(find.text('Cosmic'));
      await tester.pump();
      await tester.tap(find.text('Cosmic'));
      await tester.pump();

      expect(find.text('Coming soon'), findsNothing);
      expect(worldTheme.setCalls, [AppWorldTheme.nebula]);
    });
  });
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/settings/presentation/screens/settings_screen_test.dart`
Expected: FAIL — "locked tiles show a COMING SOON chip" finds no 'COMING SOON' text; the tap tests find no 'Coming soon' snackbar.

- [ ] **Step 4: Implement the picker lock UI**

In `lib/features/settings/presentation/screens/settings_screen.dart`:

1. Add the import (alphabetical, near the other core imports, after `app_world_theme.dart` at line 21):

```dart
import 'package:emerge_app/core/domain/services/theme_lock.dart';
```

2. In `_WorldThemePicker.build`'s `itemBuilder` (lines 1357–1408), compute `isLocked` next to `isSelected`, route taps, and wrap the tile content:

```dart
        itemBuilder: (context, index) {
          final theme = AppWorldTheme.values[index];
          final isSelected = theme == selected;
          final isLocked = ThemeLock.isLocked(theme);
          return GestureDetector(
            onTap: () {
              if (isLocked) {
                // Replace, never queue: repeat taps keep a single snackbar.
                ScaffoldMessenger.maybeOf(context)
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Coming soon'),
                      duration: Duration(milliseconds: 1500),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                return;
              }
              onSelect(theme);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: isLocked ? 0.03 : 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: isLocked ? 0.1 : 0.15),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Opacity(
                      opacity: isLocked ? 0.4 : 1.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(theme.emoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(
                            theme.displayName.split(' ').first,
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: isSelected ? 0.9 : 0.5,
                              ),
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (isLocked)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'COMING SOON',
                          style: TextStyle(
                            fontSize: 6.5,
                            color: Colors.white70,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/settings/presentation/screens/settings_screen_test.dart`
Expected: PASS — the 3 pre-existing top-level tests + 4 Tutorials tests + 3 new lock tests all pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/presentation/screens/settings_screen.dart test/features/settings/presentation/screens/settings_screen_test.dart
git commit -m "feat(settings): lock non-nebula world themes — coming-soon chip + snackbar"
```

---

# Phase 4 — Verification

## Task 4: Full verification + manual smoke checklist

No code changes expected; commit only if a fix is required.

- [ ] **Step 1: Analyze**

```bash
dart analyze lib test
```

Expected: 0 issues (matching the SP-A baseline; the pre-existing `tribe_membership_service_test.dart` failure is unrelated — SP-G).

- [ ] **Step 2: Run the SP-C test set**

```bash
flutter test test/core/domain/services/theme_lock_test.dart test/core/presentation/providers/world_theme_provider_test.dart test/features/settings/presentation/screens/settings_screen_test.dart
```

Expected: PASS — 5 (ThemeLock) + 4 (provider) + 10 (settings screen: 2 + 4 tutorials + 3 lock + 1 renders).

- [ ] **Step 3: Focused regression sweep**

```bash
flutter test test/features/settings test/core/presentation/providers
```

Expected: PASS (no other test touches `world_theme_provider` or the picker — grep-verified at plan time).

- [ ] **Step 4: Manual smoke checklist (device/emulator)**

1. Open Settings → World Theme: nebula tile shows the check; the other 5 tiles are dimmed with a 'COMING SOON' chip.
2. Tap 'Living Forest' → floating 'Coming soon' snackbar; no selection change; repeat taps replace (not queue) the snackbar.
3. Tap 'Cosmic Nebula' → selected immediately, no snackbar.
4. Kill and relaunch the app → nebula still selected; `app_world_theme` in shared_prefs is `'nebula'` (or absent).
5. Timeline background unaffected (hardcodes nebula at timeline_screen.dart:329).

- [ ] **Step 5: Commit only if fixes were made**

```bash
# only if Step 1–3 surfaced SP-C-introduced issues that required fixes
git add <fixed files>
git commit -m "fix(theme): SP-C verification fixes"
```
