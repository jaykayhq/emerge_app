# Habit Card Gesture Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace long-press habit completion with tick-circle tap + swipe gestures on the timeline habit card.

**Architecture:** Modify `_IndentedHabitItem` to wrap in `Dismissible` with direction-aware actions (left swipe → complete/snap-back, right swipe → delete after confirmation). Make the existing radio button icon a tappable `GestureDetector`. Remove `onLongPress`. Thread `onDelete` callback from `TimelineScreen` through the widget chain.

**Tech Stack:** Flutter `Dismissible` widget (native SDK), Riverpod for state, Firestore for persistence.

---

### Task 1: Thread `onDelete` through widget chain + remove long press + make tick tappable

**Files:**
- Modify: `lib/features/timeline/presentation/widgets/habit_timeline_section.dart`

- [ ] **Step 1: Add `onDelete` to `HierarchicalHabitTimeline`**

Add `onHabitDelete` parameter and pass it through to `_HabitCategorySection`:

```dart
class HierarchicalHabitTimeline extends StatelessWidget {
  final void Function(Habit habit) onHabitDelete;

  const HierarchicalHabitTimeline({
    ...
    required this.onHabitDelete,
  });
```

In the `for` loop inside `build`, pass it:
```dart
_HabitCategorySection(
  ...
  onHabitDelete: onHabitDelete,
)
```

- [ ] **Step 2: Add `onDelete` to `_HabitCategorySection`**

```dart
class _HabitCategorySection extends StatelessWidget {
  final void Function(Habit habit) onHabitDelete;

  const _HabitCategorySection({
    ...
    required this.onHabitDelete,
  });
```

In the `.map()` inside `build`, pass it:
```dart
_IndentedHabitItem(
  ...
  onDelete: () => onHabitDelete(habit),
)
```

- [ ] **Step 3: Add `onDelete` to `_IndentedHabitItem`**

```dart
class _IndentedHabitItem extends StatefulWidget {
  final VoidCallback? onDelete;

  const _IndentedHabitItem({
    ...
    this.onDelete,
  });
```

- [ ] **Step 4: Remove `onLongPress` from `GestureDetector`**

In the `build` method of `_IndentedHabitItemState`, find the `GestureDetector` wrapping the card container (line ~399). Remove the `onLongPress` line:

```dart
// BEFORE (lines 399-401):
GestureDetector(
  onTap: widget.onTap,
  onLongPress: !completed ? widget.onToggle : null,
  child: Container(...),

// AFTER:
GestureDetector(
  onTap: widget.onTap,
  child: Container(...),
```

- [ ] **Step 5: Make the radio button tappable**

In `_buildPending`, wrap the `Icons.radio_button_unchecked` icon in a `GestureDetector` that calls `widget.onToggle`:

```dart
// BEFORE (lines 561-570):
Padding(
  padding: const EdgeInsets.only(right: 12),
  child: Icon(
    Icons.radio_button_unchecked,
    color: color.withValues(alpha:0.5),
    size: 20,
  ),
),

// AFTER:
Padding(
  padding: const EdgeInsets.only(right: 12),
  child: GestureDetector(
    onTap: widget.onToggle,
    child: Icon(
      Icons.radio_button_unchecked,
      color: color.withValues(alpha:0.5),
      size: 20,
    ),
  ),
),
```

- [ ] **Step 6: Commit**

---

### Task 2: Wrap `_IndentedHabitItem` in `Dismissible` with swipe actions

**Files:**
- Modify: `lib/features/timeline/presentation/widgets/habit_timeline_section.dart`

- [ ] **Step 1: Add Dismissible wrapper + background builders + confirmation dialog**

Wrap the outer `Padding` in `_IndentedHabitItemState.build` with a `Dismissible`. Add three new methods to the State class.

The build method's return changes from:
```dart
return Padding(
  padding: const EdgeInsets.only(left: 24, bottom: 8),
  child: Column(...),
);
```

To:
```dart
return Dismissible(
  key: Key('habit_dismiss_${widget.habit.id}'),
  direction: DismissDirection.horizontal,
  background: _buildDeleteBackground(),
  secondaryBackground: _buildCompleteBackground(color),
  confirmDismiss: _confirmDismiss,
  dismissThresholds: const {
    DismissDirection.startToEnd: 0.4,
    DismissDirection.endToStart: 0.4,
  },
  child: Padding(
    padding: const EdgeInsets.only(left: 24, bottom: 8),
    child: Column(...),
  ),
);
```

Add these methods inside `_IndentedHabitItemState`:

```dart
Widget _buildDeleteBackground() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.red.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(10),
    ),
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.only(left: 24),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.delete_outline, color: Colors.white, size: 24),
        SizedBox(width: 8),
        Text(
          'Delete',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );
}

Widget _buildCompleteBackground(Color color) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF2BEE79).withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(10),
    ),
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 24),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Complete',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        SizedBox(width: 8),
        Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
      ],
    ),
  );
}

Future<bool> _confirmDismiss(DismissDirection direction) async {
  if (direction == DismissDirection.endToStart) {
    // Swipe left → complete habit
    widget.onToggle();
    return false; // snap back — card stays, state updates
  } else {
    // Swipe right → delete habit
    final confirmed = await _showDeleteConfirmation();
    if (confirmed) {
      widget.onDelete?.call();
      return true; // dismiss from tree
    }
    return false; // cancel
  }
}

Future<bool> _showDeleteConfirmation() async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text(
        'Delete Habit',
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        'Are you sure you want to permanently delete this habit and all its history?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Delete',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
```

- [ ] **Step 2: Verify the build method compiles correctly**

Make sure the `Dismissible` key import is present (`import 'package:flutter/material.dart'` already provides `Key`). The `_confirmDismiss` needs the `DismissDirection` enum (from material.dart).

- [ ] **Step 3: Commit**

---

### Task 3: Add delete handler to TimelineScreen

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

- [ ] **Step 1: Add notification service import**

Add at the top with other imports (after line 29):
```dart
import 'package:emerge_app/features/notifications/presentation/providers/notification_providers.dart';
```

- [ ] **Step 2: Add `_deleteHabit` method to `_TimelineScreenState`**

Add this method after `_toggleHabitCompletion` (after line 514):
```dart
Future<void> _deleteHabit(Habit habit) async {
  try {
    final result = await ref.read(habitRepositoryProvider).deleteHabit(habit.id);
    await ref.read(notificationServiceProvider).cancelHabitNotifications(habit.id);
    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${failure.message}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Habit deleted'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting habit'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
```

- [ ] **Step 3: Pass `onHabitDelete` to `HierarchicalHabitTimeline`**

Find the `HierarchicalHabitTimeline` usage in `_buildTimelineList` (line 340-349) and add the new parameter:

```dart
HierarchicalHabitTimeline(
  groupedHabits: timelineGroups,
  selectedDate: _selectedDate,
  onHabitTap: (habit) {
    context.push('/timeline/detail/${habit.id}');
  },
  onHabitToggle: (habit) {
    _toggleHabitCompletion(habit);
  },
  onHabitDelete: (habit) {
    _deleteHabit(habit);
  },
),
```

- [ ] **Step 4: Commit**

---

### Task 4: Self-review & verify

- [ ] **Step 1: Run dart analyzer**

```bash
dart analyze lib/features/timeline/presentation/widgets/habit_timeline_section.dart lib/features/timeline/presentation/screens/timeline_screen.dart
```
Expected: No errors.

- [ ] **Step 2: Run tests**

```bash
flutter test
```
Expected: All tests pass.
