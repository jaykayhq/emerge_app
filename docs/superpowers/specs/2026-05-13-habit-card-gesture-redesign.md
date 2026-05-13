# Habit Card Gesture Redesign

## Problem
The timeline habit card (`_IndentedHabitItem`) uses long-press to complete habits — a low-discoverability gesture. Users cannot swipe for actions, and the tick-circle icon is decorative only.

## Changes

### 1. Remove Long-Press Completion
Delete `onLongPress` from the outer `GestureDetector` in `_IndentedHabitItem` (`habit_timeline_section.dart:401`).

### 2. Make Tick Circle Interactive
Wrap `Icons.radio_button_unchecked` in a `GestureDetector` calling `onToggle`. When completed, show `Icons.check_circle` (already implemented via `_buildCompleted`).

### 3. Swipe Left to Complete
Wrap the card in `Dismissible`:
- **Direction**: `endToStart` (swipe left)
- **Background**: Green (EmergeColors.teal) with check-circle icon + "Complete" label
- **Action**: `confirmDismiss` calls `onToggle()` then returns `false` (snaps back — card stays but updates to completed state)

### 4. Swipe Right to Delete
- **Direction**: `startToEnd` (swipe right)
- **Background**: Red with delete/trash icon + "Delete" label
- **Action**: `confirmDismiss` shows an `AlertDialog` confirmation. If confirmed, returns `true` (card dismisses). `onDismissed` calls `onDelete`.
- **New callback**: `onDelete` passed through `HierarchicalHabitTimeline` → `_HabitCategorySection` → `_IndentedHabitItem`

### 5. TimelineScreen Integration
- Add `onHabitDelete` callback to `HierarchicalHabitTimeline`
- Handler calls `ref.read(habitRepositoryProvider).deleteHabit(habit.id)` + cancels notifications
- Confirmation dialog reuses the existing pattern from `habit_detail_screen.dart`

## Files Modified
- `lib/features/timeline/presentation/widgets/habit_timeline_section.dart` — main changes
- `lib/features/timeline/presentation/screens/timeline_screen.dart` — add delete handler

## Gesture Summary
| Gesture | Action | Notes |
|---------|--------|-------|
| Tap circle | Toggle complete | New interactive tick circle |
| Tap card body | Navigate detail | Unchanged |
| Swipe left ← | Complete | Snaps back, state updates |
| Swipe right → | Delete | Confirmation dialog, then removes |

## Accessibility
Tick-circle tap remains available for keyboard/non-swipe users. `Dismissible` provides built-in semantics.
