# Plan 1: State Pattern Violations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all loading, error, and empty state violations across timeline, world map, and future self studio screens.

**Architecture:** Replace `CircularProgressIndicator` with `EmergeLoadingSkeleton`, replace raw `e.toString()` errors with `AppErrorWidget`, and fix silent `SizedBox.shrink()` swallow patterns. Each screen gets proper three-state handling per design doc §5.

**Tech Stack:** Flutter, Riverpod, existing `EmergeLoadingSkeleton` and `AppErrorWidget` (confirm existence first), `timeline_screen.dart`, `world_map_screen.dart`, `future_self_studio_screen.dart`.

**State: Pending Implementation**

---

### Task 1: Audit existing reusable widgets

**Files:**
- Search: `lib/core/widgets/` for `EmergeLoadingSkeleton` and `AppErrorWidget`

- [ ] **Step 1: Search for EmergeLoadingSkeleton**

Run: `grep -rn "EmergeLoadingSkeleton\|AppErrorWidget" lib/core/`
Expected: Find existing widgets or confirm they need creation.

- [ ] **Step 2: Read found widget files**

If found, read their constructor signatures and parameter lists.

- [ ] **Step 3: Create missing widgets if needed**

If `EmergeLoadingSkeleton` does not exist, create it at `lib/core/widgets/emerge_loading_skeleton.dart`:

```dart
import 'package:flutter/material.dart';

class EmergeLoadingSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double? itemWidth;

  const EmergeLoadingSkeleton({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 80,
    this.itemWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          height: itemHeight,
          width: itemWidth,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
    );
  }
}
```

If `AppErrorWidget` does not exist, create it at `lib/core/widgets/app_error_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.cloud_off,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 48),
            const Gap(16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            if (onRetry != null) ...[
              const Gap(24),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run analyze to verify no issues**

Run: `dart analyze lib/core/widgets/`
Expected: No errors or warnings.

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/
git commit -m "feat(core): add EmergeLoadingSkeleton and AppErrorWidget for state patterns"
```

---

### Task 2: Fix timeline_screen.dart loading state

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart:185-195`

- [ ] **Step 1: Read the current loading block**

Read lines 180-200 of `timeline_screen.dart` to confirm the exact `CircularProgressIndicator` usage.

- [ ] **Step 2: Replace CircularProgressIndicator with EmergeLoadingSkeleton**

```dart
// Replace:
// return const Center(
//   child: CircularProgressIndicator(color: Colors.cyanAccent),
// );
// With:
return const EmergeLoadingSkeleton(itemCount: 3, itemHeight: 100);
```

Ensure `EmergeLoadingSkeleton` is imported.

- [ ] **Step 3: Run analyze**

Run: `dart analyze lib/features/timeline/presentation/screens/timeline_screen.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "fix(timeline): replace CircularProgressIndicator with EmergeLoadingSkeleton"
```

---

### Task 3: Fix timeline_screen.dart error state (e.toString())

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart` around line 460

- [ ] **Step 1: Read the error block**

Read lines 450-470 to confirm the `e.toString()` pattern.

- [ ] **Step 2: Replace raw error text with AppErrorWidget**

```dart
// Replace:
// error: (error, _) => Center(
//   child: Text(e.toString()),
// ),
// With:
error: (error, _) => AppErrorWidget(
  message: "Couldn't load habits. Check your connection and try again.",
  onRetry: () => ref.invalidate(habitsProvider),
),
```

- [ ] **Step 3: Run analyze**

Run: `dart analyze lib/features/timeline/presentation/screens/timeline_screen.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "fix(timeline): replace e.toString() with AppErrorWidget per design doc §15.2"
```

---

### Task 4: Fix world_map_screen.dart loading state

**Files:**
- Modify: `lib/features/world_map/presentation/screens/world_map_screen.dart` around line 70

- [ ] **Step 1: Read the current loading state**

Read lines 65-80 of `world_map_screen.dart`.

- [ ] **Step 2: Replace CircularProgressIndicator**

```dart
// Replace:
// Center(child: CircularProgressIndicator())
// With:
const EmergeLoadingSkeleton(itemCount: 1, itemHeight: 300)
```

- [ ] **Step 3: Run analyze**

Run: `dart analyze lib/features/world_map/presentation/screens/world_map_screen.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/world_map/presentation/screens/world_map_screen.dart
git commit -m "fix(world-map): replace CircularProgressIndicator with EmergeLoadingSkeleton"
```

---

### Task 5: Fix future_self_studio_screen.dart error state (no retry)

**Files:**
- Modify: `lib/features/profile/presentation/screens/future_self_studio_screen.dart` around line 557-565

- [ ] **Step 1: Read the error block**

Read lines 550-570 of `future_self_studio_screen.dart`.

- [ ] **Step 2: Replace Text('Error: $e') with AppErrorWidget**

```dart
// Replace:
// error: (e, _) => Center(
//   child: Text('Error: $e'),
// ),
// With:
error: (e, _) => AppErrorWidget(
  message: "Couldn't load profile. Check your connection and try again.",
  onRetry: () => ref.invalidate(profileProvider),
),
```

- [ ] **Step 3: Run analyze**

Run: `dart analyze lib/features/profile/presentation/screens/future_self_studio_screen.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/presentation/screens/future_self_studio_screen.dart
git commit -m "fix(profile): replace raw Error text with AppErrorWidget with retry"
```

---

### Task 6: Fix future_self_studio_screen.dart silent loading/error

**Files:**
- Modify: `lib/features/profile/presentation/screens/future_self_studio_screen.dart` around lines 718-736

- [ ] **Step 1: Read the silent swallow block**

Read lines 710-740 of `future_self_studio_screen.dart` to confirm `SizedBox.shrink()` patterns.

- [ ] **Step 2: Replace SizedBox.shrink() with proper states**

```dart
// Replace:
// loading: () => const SizedBox.shrink(),
// error: (e, _) => const SizedBox.shrink(),
// With:
loading: () => const EmergeLoadingSkeleton(itemCount: 1, itemHeight: 200),
error: (e, _) => AppErrorWidget(
  message: "Couldn't load this section.",
  onRetry: () => ref.invalidate(sectionProvider),
),
```

- [ ] **Step 3: Run analyze**

Run: `dart analyze lib/features/profile/presentation/screens/future_self_studio_screen.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/presentation/screens/future_self_studio_screen.dart
git commit -m "fix(profile): replace SizedBox.shrink() with proper loading/error states"
```

---

### Task 7: Fix retroactively-empty timeline (Plan 1d)

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

- [ ] **Step 1: Read the empty state area**

Read lines around 370-390 where `habits.isEmpty` is handled.

- [ ] **Step 2: Ensure empty state shows nothing but the empty message**

When `habits.isEmpty`, the widget should return only the empty state content — not a full dashboard skeleton with calendar, recap, or header UI.

```dart
// Current pattern (if exists):
// if (habits.isEmpty) {
//   return CustomScrollView(
//     slivers: [
//       // header, calendar, recap, all rendered
//       _buildEmptyState(),
//     ],
//   );
// }

// Fixed pattern:
if (habits.isEmpty) {
  return Center(
    child: _buildCompactEmptyState(),
  );
}
```

Where `_buildCompactEmptyState()` returns just the empty state message and an illustration, without calendar/recap/header skeleton.

- [ ] **Step 3: Run analyze**

Run: `dart analyze lib/features/timeline/presentation/screens/timeline_screen.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "fix(timeline): render only empty state when habits.isEmpty, not full skeleton"
```

---

### Task 8: Run full test suite

- [ ] **Step 1: Run flutter analyze on the whole project**

```bash
flutter analyze
```
Expected: No errors or warnings beyond pre-existing ones.

- [ ] **Step 2: Run flutter test**

```bash
flutter test
```
Expected: All tests pass.

- [ ] **Step 3: Commit any final fixes**

```bash
git add -A
git commit -m "fix(state-patterns): verify all state pattern fixes pass analyze and tests"
```
