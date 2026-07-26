# Plan 6: Card Polish + Recap Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce habit card sizing, increase card contrast between pending/completed states, reposition ad banner, and redesign recap card with momentum arc + streak flame.

**Architecture:** Visual-only changes to habit card dimensions and colors in `habit_timeline_section.dart`, and a full rewrite of `recap_summary_card.dart` with a circular progress arc and streak flame display.

**Tech Stack:** Flutter, `habit_timeline_section.dart`, `recap_summary_card.dart`, `timeline_screen.dart`.

**State: Pending Implementation**

---

### Task 1: Reduce habit card sizing

**Files:**
- Modify: `lib/features/timeline/presentation/widgets/habit_timeline_section.dart`

- [ ] **Step 1: Read current card dimensions**

Read `habit_timeline_section.dart` around lines 337-495 to find padding, font sizes, and spacing values.

- [ ] **Step 2: Reduce card padding**

```dart
// Find and change:
// padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
// To:
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
```

- [ ] **Step 3: Reduce title font size**

```dart
// Find and change:
// style: TextStyle(fontSize: 14, ...),
// To:
style: TextStyle(fontSize: 13, ...),
```

- [ ] **Step 4: Reduce XP badge font size**

```dart
// XP badge text:
// style: TextStyle(fontSize: 12, ...),
// To:
style: TextStyle(fontSize: 11, ...),
```

- [ ] **Step 5: Reduce category circle and spacing**

```dart
// Category circle:
// width: 12, height: 12,
// To:
width: 10, height: 10,

// Card spacing (SizedBox or SizedBox with height):
// height: 8,
// To:
height: 4,

// Connector line:
// width: 2,
// To:
width: 1.5,
```

- [ ] **Step 6: Run analyze**

```bash
dart analyze lib/features/timeline/presentation/widgets/habit_timeline_section.dart
```
Expected: No errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/timeline/presentation/widgets/habit_timeline_section.dart
git commit -m "fix(timeline): reduce habit card sizing (padding, font, spacing)"
```

---

### Task 2: Card contrast (completed vs pending)

**Files:**
- Modify: `lib/features/timeline/presentation/widgets/habit_timeline_section.dart`

- [ ] **Step 1: Find completed card background color**

Look for the `_buildCompleted()` method and its container decoration.

- [ ] **Step 2: Add darker tint for completed cards**

```dart
// In completed card container:
color: const Color(0xFF1A1A2E).withValues(alpha: 0.8),
// vs pending card (if different):
color: const Color(0xFF1A1A2E).withValues(alpha: 0.6),
// Completed gets +5% darker
```

- [ ] **Step 3: Add green glow to next incomplete habit**

```dart
// In the first incomplete habit card:
decoration: BoxDecoration(
  border: Border.all(
    color: const Color(0xFF2BEE79).withValues(alpha: 0.2),
    width: 1,
  ),
  color: const Color(0xFF1A1A2E).withValues(alpha: 0.6),
  borderRadius: BorderRadius.circular(12),
),
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/timeline/presentation/widgets/habit_timeline_section.dart
git commit -m "fix(timeline): increase card contrast between completed/pending states"
```

---

### Task 3: Recap card redesign — momentum arc + streak flame

**Files:**
- Modify: `lib/features/timeline/presentation/widgets/recap_summary_card.dart`

- [ ] **Step 1: Read current recap_summary_card.dart**

- [ ] **Step 2: Write the widget test**

```dart
testWidgets('shows momentum arc and streak flame', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: RecapSummaryCard(
      completionFraction: 0.75,
      currentStreak: 7,
      bestStreak: 14,
      totalCompletions: 42,
      tribePercentile: 90,
    ),
  ));
  expect(find.text('75%'), findsOneWidget);
  expect(find.text('7'), findsOneWidget);
  expect(find.text('day streak'), findsOneWidget);
  expect(find.text("You're ahead of 90% of your tribe today."), findsOneWidget);
});
```

- [ ] **Step 3: Implement new RecapSummaryCard**

```dart
class RecapSummaryCard extends StatelessWidget {
  final double completionFraction; // 0.0–1.0
  final int currentStreak;
  final int bestStreak;
  final int totalCompletions;
  final int tribePercentile;
  final VoidCallback? onTap;

  const RecapSummaryCard({
    super.key,
    required this.completionFraction,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCompletions,
    required this.tribePercentile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.go('/world-map/recap'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            // Left: Circular progress arc
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: completionFraction,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _arcColor(completionFraction),
                    ),
                  ),
                  Text(
                    '${(completionFraction * 100).toInt()}%',
                    style: TextStyle(
                      color: _arcColor(completionFraction),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right: Streak flame
            Row(
              children: [
                Text(
                  _flameEmoji(currentStreak),
                  style: TextStyle(fontSize: currentStreak >= 7 ? 24 : 20),
                ),
                const SizedBox(width: 4),
                Text(
                  '$currentStreak',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: currentStreak >= 7 ? 22 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'day streak',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _arcColor(double fraction) {
    if (fraction >= 0.5) return const Color(0xFF2BEE79); // green
    if (fraction >= 0.25) return const Color(0xFFFFC107); // amber
    return const Color(0xFFFF6B6B); // coral
  }

  String _flameEmoji(int streak) {
    if (streak >= 21) return '🔥🔥';
    if (streak >= 7) return '🔥';
    return '🔥';
  }
}
```

Also add the narrative line below in the parent widget (or include it in this card):

```dart
// Narrative line (rendered below the main row):
Padding(
  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
  child: Text(
    _narrativeText(),
    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
  ),
),

String _narrativeText() {
  if (completionFraction >= 1.0) {
    return "All done today! You're in the top $tribePercentile% of your tribe.";
  }
  if (completionFraction >= 0.5) {
    return "You're ahead of $tribePercentile% of your tribe today.";
  }
  if (completionFraction > 0) {
    return "Every habit counts — you're at ${(completionFraction * 100).toInt()}%.";
  }
  return "Your day hasn't started yet.";
}
```

- [ ] **Step 4: Run test → pass**

- [ ] **Step 5: Integrate into timeline_screen.dart**

Replace the old `RecapSummaryCard` instantiation with the new one, passing the required data from the dashboard state provider.

- [ ] **Step 6: Commit**

```bash
git add lib/features/timeline/presentation/widgets/recap_summary_card.dart
git commit -m "feat(timeline): redesign recap card with momentum arc + streak flame"
```

---

### Task 4: Reposition ad banner (already in Plan 3, verify here too)

- [ ] **Step 1: Ensure AdBannerWidget is below narrator summary card**

Check `timeline_screen.dart` to confirm the ad banner was moved in Plan 3. If not, move it now.

- [ ] **Step 2: Commit if changes needed**

---

### Task 5: Full verification

- [ ] **Step 1: Run analyze + test**

```bash
flutter analyze
flutter test
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "fix(card-polish): verify all card polish and recap redesign"
```
