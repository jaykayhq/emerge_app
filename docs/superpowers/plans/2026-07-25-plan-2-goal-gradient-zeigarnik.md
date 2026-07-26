# Plan 2: Goal Gradient + Zeigarnik Effect Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add visual goal-progress signals (FAB completion ring, bottom nav badge, momentum indicator) to leverage the Goal Gradient Effect and Zeigarnik Effect.

**Architecture:** (1) Stack a `CircularProgressIndicator` overlay on the existing FAB in `timeline_screen.dart`. (2) Add a badge to the Timeline tab in `scaffold_with_nav_bar.dart` showing incomplete habit count. (3) Add a momentum dot/ring in `ArchetypeSliverAppBar`. All three read from a shared completion-fraction state derived from today's habits.

**Tech Stack:** Flutter, Riverpod, `timeline_screen.dart`, `scaffold_with_nav_bar.dart` or `emerge_bottom_nav.dart`, `archetype_sliver_app_bar.dart`, `dashboard_state_provider.dart`.

**State: Pending Implementation**

---

### Task 1: Create completion-fraction provider

**Files:**
- Create: `lib/features/timeline/presentation/providers/completion_fraction_provider.dart`
- Test: `test/features/timeline/presentation/providers/completion_fraction_provider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/timeline/presentation/providers/completion_fraction_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/timeline/presentation/providers/completion_fraction_provider.dart';

void main() {
  group('completionFraction', () {
    test('returns 0.0 when no habits exist', () {
      // Pure function test: computeCompletionFraction([])
      final result = computeCompletionFraction([]);
      expect(result, 0.0);
    });

    test('returns 1.0 when all habits completed', () {
      final habits = [
        _TestHabit(isCompleted: true),
        _TestHabit(isCompleted: true),
      ];
      expect(computeCompletionFraction(habits), 1.0);
    });

    test('returns 0.5 when half habits completed', () {
      final habits = [
        _TestHabit(isCompleted: true),
        _TestHabit(isCompleted: false),
      ];
      expect(computeCompletionFraction(habits), 0.5);
    });
  });
}

class _TestHabit {
  final bool isCompleted;
  const _TestHabit({required this.isCompleted});
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/timeline/presentation/providers/completion_fraction_provider_test.dart`
Expected: FAIL with "function not defined" or similar.

- [ ] **Step 3: Write the provider**

```dart
// lib/features/timeline/presentation/providers/completion_fraction_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/features/timeline/presentation/providers/habit_list_provider.dart';
part 'completion_fraction_provider.g.dart';

/// Pure function: compute completion fraction from a list of habit-like items.
/// Extracted for testability — works with any object that has `isCompleted`.
double computeCompletionFraction<T extends HasCompleted>(List<T> habits) {
  if (habits.isEmpty) return 0.0;
  final completed = habits.where((h) => h.isCompleted).length;
  return completed / habits.length;
}

/// Interface for the pure function's input
abstract class HasCompleted {
  bool get isCompleted;
}

/// Returns 0.0–1.0 fraction of today's completed habits.
@riverpod
double completionFraction(Ref ref) {
  final habits = ref.watch(todayHabitsProvider);
  return computeCompletionFraction(habits);
}
```

Note: If `todayHabitsProvider` returns a different type, adjust the provider accordingly. The key is the pure function `computeCompletionFraction` that's unit-testable.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/timeline/presentation/providers/completion_fraction_provider_test.dart`
Expected: PASS

- [ ] **Step 5: Run build_runner**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/timeline/presentation/providers/completion_fraction_provider.dart test/features/timeline/presentation/providers/completion_fraction_provider_test.dart
git commit -m "feat(timeline): add completionFraction provider with pure compute function"
```

---

### Task 2: FAB completion ring

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

- [ ] **Step 1: Wrap the existing FAB with a Stack + progress ring**

Locate the FAB in `timeline_screen.dart` (likely a `floatingActionButton:` parameter). Replace it with:

```dart
floatingActionButton: Stack(
  alignment: Alignment.center,
  children: [
    // Progress ring
    SizedBox(
      width: 64,
      height: 64,
      child: CircularProgressIndicator(
        value: ref.watch(completionFractionProvider),
        strokeWidth: 3,
        strokeCap: StrokeCap.round,
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation<Color>(
          _ringColor(ref.watch(completionFractionProvider)),
        ),
      ),
    ),
    // Original FAB
    FloatingActionButton(
      onPressed: () => _showCreateHabit(context),
      backgroundColor: const Color(0xFF1A1A2E),
      child: const Icon(Icons.add, color: Colors.cyanAccent),
    ),
  ],
),
```

Add the helper method:

```dart
Color _ringColor(double fraction) {
  if (fraction >= 0.8) return const Color(0xFF2BEE79);   // green
  if (fraction >= 0.5) return const Color(0xFFFFC107);   // amber
  return const Color(0xFFFF6B6B);                         // coral
}
```

- [ ] **Step 2: Run analyze**

Run: `dart analyze lib/features/timeline/presentation/screens/timeline_screen.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "feat(timeline): add FAB completion ring showing today's progress"
```

---

### Task 3: Incomplete-habit-count provider

**Files:**
- Create: `lib/features/timeline/presentation/providers/incomplete_count_provider.dart`
- Test: `test/features/timeline/presentation/providers/incomplete_count_provider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
test('returns 0 when all habits completed', () {
  final habits = [_TestHabit(isCompleted: true)];
  expect(computeIncompleteCount(habits), 0);
});

test('returns count of incomplete habits', () {
  final habits = [
    _TestHabit(isCompleted: true),
    _TestHabit(isCompleted: false),
    _TestHabit(isCompleted: false),
  ];
  expect(computeIncompleteCount(habits), 2);
});
```

- [ ] **Step 2: Run to see fail → implement → pass**

```dart
int computeIncompleteCount<T extends HasCompleted>(List<T> habits) {
  return habits.where((h) => !h.isCompleted).length;
}
```

- [ ] **Step 3: Commit**

```bash
git commit -m "feat(timeline): add incompleteCount provider for badge display"
```

---

### Task 4: Bottom nav badge on Timeline tab

**Files:**
- Modify: `lib/core/widgets/scaffold_with_nav_bar.dart` (or `emerge_bottom_nav.dart`)

- [ ] **Step 1: Find the nav bar file**

Run: `grep -rn "Timeline\|timeline" lib/core/widgets/ | grep -i nav`
Expected: Find the correct file.

- [ ] **Step 2: Add badge to Timeline tab**

```dart
// Inside the BottomNavigationBarItem or NavigationDestination for Timeline:
Badge(
  isLabelVisible: ref.watch(incompleteCountProvider) > 0,
  label: Text('${ref.watch(incompleteCountProvider)}'),
  child: const Icon(Icons.timeline_outlined),
),
```

If using `StatefulShellRoute.indexedStack` with navigation destinations, wrap the icon with `Badge`.

- [ ] **Step 3: Add optional pulse animation**

If < 2 hours of daylight remaining and count > 0, wrap badge with a subtle pulse animation using `AnimationController` + `Tween<double>(begin: 1.0, end: 1.2)`.

- [ ] **Step 4: Run analyze and test**

Run: `flutter analyze` and `flutter test`
Expected: No errors, tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/
git commit -m "feat(nav): add incomplete habit badge to Timeline tab"
```

---

### Task 5: Momentum indicator in ArchetypeSliverAppBar

**Files:**
- Modify: `lib/features/profile/presentation/widgets/archetype_sliver_app_bar.dart`

- [ ] **Step 1: Read the current app bar**

Read `archetype_sliver_app_bar.dart` to find where momentum data is available.

- [ ] **Step 2: Add momentum dot/ring**

```dart
// After the title or in the trailing area, add:
Container(
  width: 10,
  height: 10,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: momentumColor(ref.watch(momentumProvider)),
    boxShadow: [
      BoxShadow(
        color: momentumColor(ref.watch(momentumProvider)).withValues(alpha: 0.4),
        blurRadius: 4,
      ),
    ],
  ),
),
```

Helper:
```dart
Color momentumColor(int momentum) {
  if (momentum >= 7) return const Color(0xFF2BEE79);
  if (momentum >= 3) return const Color(0xFFFFC107);
  return const Color(0xFFFF6B6B);
}
```

- [ ] **Step 3: Run analyze**

Run: `dart analyze lib/features/profile/presentation/widgets/archetype_sliver_app_bar.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/presentation/widgets/archetype_sliver_app_bar.dart
git commit -m "feat(profile): add momentum indicator dot to ArchetypeSliverAppBar"
```

---

### Task 6: Full project verification

- [ ] **Step 1: Run build_runner**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2: Run flutter analyze**

```bash
flutter analyze
```
Expected: No new warnings.

- [ ] **Step 3: Run flutter test**

```bash
flutter test
```
Expected: All tests pass, including new unit tests for pure functions.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(goal-gradient): verify all goal gradient features pass analyze and tests"
```
