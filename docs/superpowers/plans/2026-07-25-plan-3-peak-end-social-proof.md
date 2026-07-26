# Plan 3: Peak-End Rule + Social Proof Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add positive peak-end experiences (all-done celebration, tribal presence strip, revised miss recovery sheet) and social proof elements to the timeline.

**Architecture:** (1) A `CompletionCelebration` widget triggered when the last habit completes. (2) A tribe presence pill below the app bar showing social proof. (3) A revised `MissRecoverySheet` with "Complete Now" quick action buttons. All coordinate through a shared `lastHabitCompletedProvider` signal.

**Tech Stack:** Flutter, Riverpod, `timeline_screen.dart`, HapticFeedback, existing `MissRecoverySheet`, `tribe_stats_service.dart`.

**State: Pending Implementation**

---

### Task 1: Create last-habit-completed trigger provider

**Files:**
- Create: `lib/features/timeline/presentation/providers/last_habit_completed_provider.dart`
- Test: `test/features/timeline/presentation/providers/last_habit_completed_provider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// Pure function: was the last habit just completed?
bool isLastHabitJustCompleted({
  required int previousCompleted,
  required int currentCompleted,
  required int totalHabits,
}) {
  return previousCompleted < totalHabits
      && currentCompleted == totalHabits
      && currentCompleted > previousCompleted;
}

void main() {
  group('isLastHabitJustCompleted', () {
    test('returns true when count goes from total-1 to total', () {
      expect(isLastHabitJustCompleted(
        previousCompleted: 4,
        currentCompleted: 5,
        totalHabits: 5,
      ), true);
    });

    test('returns false when already all done', () {
      expect(isLastHabitJustCompleted(
        previousCompleted: 5,
        currentCompleted: 5,
        totalHabits: 5,
      ), false);
    });

    test('returns false when only partial progress', () {
      expect(isLastHabitJustCompleted(
        previousCompleted: 2,
        currentCompleted: 3,
        totalHabits: 5,
      ), false);
    });
  });
}
```

- [ ] **Step 2: Implement the pure function in a provider file**

- [ ] **Step 3: Create the Riverpod provider**

```dart
@riverpod
bool isLastHabitJustCompleted(Ref ref) {
  final habits = ref.watch(todayHabitsProvider);
  // Count completed, compare with previous state
  // The provider watches todayHabitsProvider and detects the transition
  // from (completedCount < total) to (completedCount == total).
  // Uses ref.listen to detect state changes.
}
```

- [ ] **Step 4: Run tests → pass**

- [ ] **Step 5: Commit**

---

### Task 2: All-done celebration widget

**Files:**
- Create: `lib/features/timeline/presentation/widgets/completion_celebration.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
testWidgets('shows narrator one-liner when all habits done', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: CompletionCelebration()));
  // Initially not visible
  expect(find.text("All done. Your future self thanks you."), findsNothing);

  // Trigger show() via the widget's GlobalKey reference
  // celebrationKey.currentState?.show();
  await tester.pumpAndSettle();
  expect(find.text("All done. Your future self thanks you."), findsOneWidget);
});
```

- [ ] **Step 2: Implement CompletionCelebration**

```dart
class CompletionCelebration extends StatefulWidget {
  const CompletionCelebration({super.key});

  @override
  State<CompletionCelebration> createState() => _CompletionCelebrationState();
}

class _CompletionCelebrationState extends State<CompletionCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void show() {
    if (!_controller.isCompleted) {
      HapticFeedback.heavyImpact();
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _glowAnimation,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.3 * _glowAnimation.value),
              blurRadius: 50 * _glowAnimation.value,
              spreadRadius: 20 * _glowAnimation.value,
            ),
          ],
        ),
        child: Center(
          child: Text(
            "All done. Your future self thanks you.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 3: Integrate into timeline_screen.dart**

Watch the `lastHabitCompletedProvider` and call `show()` when it transitions to true.

```dart
ref.listen<bool>(lastHabitCompletedProvider, (prev, next) {
  if (next == true) {
    celebrationKey.currentState?.show();
  }
});
```

- [ ] **Step 4: Run widget test → pass**

- [ ] **Step 5: Commit**

```bash
git add lib/features/timeline/presentation/widgets/completion_celebration.dart
git commit -m "feat(timeline): add all-done celebration with glow pulse and haptic"
```

---

### Task 3: Move AdBannerWidget

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

- [ ] **Step 1: Locate the ad banner position**

Find `AdBannerWidget` in `timeline_screen.dart`. Cut it from between habit list and narrator.

- [ ] **Step 2: Paste below narrator summary card**

Place `AdBannerWidget` after the narrator summary card widget in the sliver list.

- [ ] **Step 3: Commit**

```bash
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "fix(timeline): move AdBannerWidget below narrator summary card"
```

---

### Task 4: Tribal presence strip

**Files:**
- Create: `lib/features/timeline/presentation/widgets/tribal_presence_strip.dart`
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('shows tribe members done message', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: TribalPresenceStrip(memberCount: 3, habitLabel: 'morning habits'),
  ));
  expect(find.text("🏟️ Tribe: 3 members done morning habits so far"), findsOneWidget);
});
```

- [ ] **Step 2: Implement TribalPresenceStrip**

```dart
class TribalPresenceStrip extends StatelessWidget {
  final int memberCount;
  final String habitLabel;

  const TribalPresenceStrip({
    super.key,
    required this.memberCount,
    required this.habitLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/pulse-feed'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("🏟️", style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              "Tribe: $memberCount members done $habitLabel so far",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Integrate into timeline_screen.dart**

Add below the ArchetypeSliverAppBar. Only shown when `userHasTribe` is true. Data from tribe stats provider.

- [ ] **Step 4: Run test → pass**

- [ ] **Step 5: Commit**

```bash
git add lib/features/timeline/presentation/widgets/tribal_presence_strip.dart
git commit -m "feat(timeline): add tribal presence strip with social proof"
```

---

### Task 5: Miss Recovery Sheet with quick actions

**Files:**
- Modify: `lib/features/timeline/presentation/widgets/miss_recovery_sheet.dart`

- [ ] **Step 1: Read current miss_recovery_sheet.dart**

- [ ] **Step 2: Add streak visualization**

```dart
// At the top of the sheet:
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 28),
    const SizedBox(width: 8),
    Text(
      '${currentStreak} day streak at risk!',
      style: TextStyle(
        color: Colors.orangeAccent,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  ],
),
Text(
  'Complete your habits to keep it alive.',
  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
),
```

- [ ] **Step 3: Add "Complete Now" buttons per missed habit**

Each missed habit gets a row:
```dart
ListTile(
  title: Text(habit.title),
  subtitle: habit.twoMinuteVersion != null
      ? Text('Suggested: ${habit.twoMinuteVersion}')
      : null,
  trailing: ElevatedButton(
    onPressed: () {
      ref.read(habitCompletionProvider.notifier).complete(habit.id);
      setState(() {}); // Or re-read the list
    },
    child: const Text('Complete Now'),
  ),
),
```

- [ ] **Step 4: Run analyze**

Run: `dart analyze lib/features/timeline/presentation/widgets/miss_recovery_sheet.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/timeline/presentation/widgets/miss_recovery_sheet.dart
git commit -m "feat(timeline): add streak visualization and Complete Now buttons to miss recovery sheet"
```

---

### Task 6: Full verification

- [ ] **Step 1: Run build_runner**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2: Run analyze + test**

```bash
flutter analyze && flutter test
```
Expected: Clean.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat(peak-end): verify all celebration and social proof features"
```
