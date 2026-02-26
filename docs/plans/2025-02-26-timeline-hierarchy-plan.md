# Timeline Hierarchical Habits Display Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform timeline habits display from separate time sections to a hierarchical category layout with bullet-point anchors and indented habits.

**Architecture:** Single scrollable list with time-based category headers (bullet/circle) and indented habit items under each category.

**Tech Stack:** Flutter, Dart, existing habit providers

---

## Current State

**Already Implemented:**
- Time-based anchors exist in onboarding (`FirstHabitScreen`)
- Timeline groups habits by `timeOfDayPreference`
- All 4 slots show as separate sections

**Needs Change:**
- Replace separate sections with hierarchical list
- Use bullet/circle for category headers
- Indent habits under their category
- Align all category headers vertically
- Remove "Anytime Actions" — those habits should show under their assigned time

---

## Visual Design

```
┌─────────────────────────────────────┐
│ ● After You Wake Up                 │  ← Category header
│   ├─ Morning Workout              │  ← Indented habit
│   ├─ 10 min meditation            │
│   └─ Cold shower                   │
│                                     │
│ ● During Lunch                       │  ← Same alignment as morning
│   ├─ Read for 30 minutes           │
│   └─ Take vitamins                 │
│                                     │
│ ● Before Bed                         │  ← Same alignment as morning
│   ├─ Journal today's wins          │
│   ├─ Evening stretch               │
│   └─ Read before sleep             │
└─────────────────────────────────────┘
```

---

## Implementation Plan

### Task 1: Update HabitTimelineSection

**Files:**
- Modify: `lib/features/timeline/presentation/widgets/habit_timeline_section.dart`

**Step 1: Read current timeline widget structure**

First, understand how habits are currently displayed in the timeline.

**Step 2: Create new hierarchical widget**

Create a new widget that displays habits as a hierarchical list:

```dart
/// Hierarchical timeline with category headers and indented habits
class HierarchicalHabitTimeline extends StatelessWidget {
  final Map<String, List<Habit>> groupedHabits;
  final void Function(Habit habit) onHabitTap;
  final void Function(Habit habit) onHabitToggle;

  const HierarchicalHabitTimeline({
    super.key,
    required this.groupedHabits,
    required this.onHabitTap,
    required this.onHabitToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Order: morning, afternoon, evening
    final timeSlots = ['morning', 'afternoon', 'evening'];
    final slotsWithHabits = timeSlots
        .where((slot) => (groupedHabits[slot]?.length ?? 0) > 0)
        .toList();

    if (slotsWithHabits.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final slot in slotsWithHabits)
            _HabitCategorySection(
              slot: slot,
              habits: groupedHabits[slot]!,
              onHabitTap: onHabitTap,
              onHabitToggle: onHabitToggle,
              isLast: slot == slotsWithHabits.last,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.habit_idle_outlined,
              color: Colors.white.withValues(alpha: 0.3),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No habits scheduled today',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category section with bullet header and indented habits
class _HabitCategorySection extends StatelessWidget {
  final String slot;
  final List<Habit> habits;
  final VoidCallback onHabitTap;
  final VoidCallback onHabitToggle;
  final bool isLast;

  const _HabitCategorySection({
    required this.slot,
    required this.habits,
    required this.onHabitTap,
    required this.onHabitToggle,
    required this.isLast,
  });

  String get _categoryTitle {
    switch (slot) {
      case 'morning':
        return 'After You Wake Up';
      case 'afternoon':
        return 'During Lunch';
      case 'evening':
        return 'Before Bed';
      default:
        return slot;
    }
  }

  IconData get _categoryIcon {
    switch (slot) {
      case 'morning':
        return Icons.wb_sunny;
      case 'afternoon':
        return Icons.wb_cloudy;
      case 'evening':
        return Icons.bedtime;
      default:
        return Icons.access_time;
    }
  }

  Color get _categoryColor {
    switch (slot) {
      case 'morning':
        return const Color(0xFFFFB74D); // Warm morning orange
      case 'afternoon':
        return const Color(0xFF64B5F6); // Day blue
      case 'evening':
        return const Color(0xFF7E57C2); // Evening purple
      default:
        return const Color(0xFF2BEE79); // Emerge green
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header with bullet
        _CategoryHeader(
          title: _categoryTitle,
          icon: _categoryIcon,
          color: _categoryColor,
          habitCount: habits.length,
        ),
        const SizedBox(height: 8),
        // Indented habit items
        ...habits.asMap().entries.map((entry) {
          final index = entry.key;
          final habit = entry.value;
          return _IndentedHabitItem(
            habit: habit,
            onTap: () => onHabitTap(habit),
            onToggle: () => onHabitToggle(habit),
            showConnector: index < habits.length - 1,
          );
        }),
        if (!isLast) const SizedBox(height: 16),
      ],
    );
  }
}

/// Category header with bullet/circle icon
class _CategoryHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int habitCount;

  const _CategoryHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.habitCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Bullet/circle
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Category title
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        // Habit count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$habitCount',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Indented habit item
class _IndentedHabitItem extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final bool showConnector;

  const _IndentedHabitItem({
    required this.habit,
    required this.onTap,
    required this.onHabitToggle,
    required this.showConnector,
  });

  bool get _isCompletedToday {
    final last = habit.lastCompletedDate;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  Color get _attributeColor {
    switch (habit.attribute) {
      case HabitAttribute.strength:
        return const Color(0xFFFF6B6B);
      case HabitAttribute.intellect:
        return const Color(0xFF6C63FF);
      case HabitAttribute.vitality:
        return const Color(0xFF2BEE79);
      case HabitAttribute.creativity:
        return const Color(0xFFE040FB);
      case HabitAttribute.focus:
        return const Color(0xFFFFB74D);
      case HabitAttribute.spirit:
        return const Color(0xFF4DD0E1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _isCompletedToday;
    final color = _attributeColor;

    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vertical connector line
              if (showConnector)
                Padding(
                  padding: const EdgeInsets.only(left: 5, top: 0),
                  child: Container(
                    width: 2,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.3),
                          color.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 12),
              // Habit item
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  onLongPress: !completed ? onToggle : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: completed
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: completed
                            ? color.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: completed
                        ? _buildCompleted(color)
                        : _buildPending(color),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPending(Color color) {
    return Row(
      children: [
        // Checkbox
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(
            Icons.radio_button_unchecked,
            color: color.withValues(alpha: 0.5),
            size: 20,
          ),
        ),
        // Habit info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (habit.cue.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  habit.cue,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Attribute indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            habit.attribute.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleted(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            habit.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 3: Update timeline screen to use new widget**

```dart
// Replace the existing HabitTimelineSection loop with:
HierarchicalHabitTimeline(
  groupedHabits: grouped,
  onHabitTap: (habit) => context.push('/detail/${habit.id}'),
  onHabitToggle: (habit) => _toggleHabit(habit),
),
```

**Step 4: Commit**

```bash
git add lib/features/timeline/presentation/widgets/habit_timeline_section.dart
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "feat: hierarchical timeline with category anchors"
```

---

## Summary

### Visual Change

**Before:** Separate full-width sections for each time slot

**After:** Hierarchical list with bullet categories and indented habits

```
● After You Wake Up (3)
    ├─ Morning Workout
    ├─ Meditation
    └─ Cold shower

● During Lunch (2)
    ├─ Read book
    └─ Take vitamins

● Before Bed (2)
    ├─ Journal
    └─ Stretching
```

### Files Modified

| File | Changes |
|------|---------|
| `lib/features/timeline/presentation/widgets/habit_timeline_section.dart` | Add hierarchical widgets |
| `lib/features/timeline/presentation/screens/timeline_screen.dart` | Use new widget |

### Key Design Decisions

1. **No "Anytime" category** — habits with no time preference are either:
   - Hidden from timeline (show only in habits list)
   - Or assigned to a default time slot

2. **Bullet alignment** — All category headers align vertically

3. **Indentation** — Habits are indented under their category

4. **Connector lines** — Visual flow from category to habits

5. **Color coding** — Each time slot has its own color accent

### Optional Enhancements

- Add expand/collapse for categories
- Show completion progress per category
- Drag to reorder time slots
- Quick add habit from category header
