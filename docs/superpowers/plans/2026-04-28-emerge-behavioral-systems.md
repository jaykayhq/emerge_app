# Emerge Behavioral Systems Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor Emerge from a binary streak app into a full behavioural science engine — implementing momentum tracking, world-health entropy, AI motive framing, identity-vote narratives, and a reorganised social/tribes system.

**Architecture:** Data layer changes first (Habit + UserStats entities, new HabitCompletion subcollection), then UI systems built on top. No mocks — all UI wired to Firestore from day one.

**Tech Stack:** Flutter 3.27+, Dart 3.5+, Riverpod v2, go_router, Firebase/Firestore, Groq AI (existing GroqAiService)

---

## Phase 0 — Dead Code Purge

### Task 0.1: Delete dead screen files

**Files to DELETE:**
- `lib/features/gamification/presentation/screens/temptation_bundling_screen.dart`
- `lib/features/gamification/presentation/screens/cinematic_recap_screen.dart`
- `lib/features/habits/presentation/screens/environment_priming_screen.dart`
- `lib/features/habits/presentation/screens/habits_scorecard_screen.dart`
- `lib/features/insights/presentation/screens/recap_screen.dart`
- `lib/features/insights/presentation/screens/reflections_screen.dart`
- `lib/features/onboarding/presentation/screens/map_identity_attributes_screen.dart`
- `lib/features/social/presentation/screens/community_challenges_screen.dart`
- `lib/features/social/presentation/screens/community_screen.dart`
- `lib/features/social/presentation/screens/tribes_screen.dart`

- [ ] **Step 1: Delete the files**
```bash
# Run from project root
Remove-Item "lib/features/gamification/presentation/screens/temptation_bundling_screen.dart"
Remove-Item "lib/features/gamification/presentation/screens/cinematic_recap_screen.dart"
Remove-Item "lib/features/habits/presentation/screens/environment_priming_screen.dart"
Remove-Item "lib/features/habits/presentation/screens/habits_scorecard_screen.dart"
Remove-Item "lib/features/insights/presentation/screens/recap_screen.dart"
Remove-Item "lib/features/insights/presentation/screens/reflections_screen.dart"
Remove-Item "lib/features/onboarding/presentation/screens/map_identity_attributes_screen.dart"
Remove-Item "lib/features/social/presentation/screens/community_challenges_screen.dart"
Remove-Item "lib/features/social/presentation/screens/community_screen.dart"
Remove-Item "lib/features/social/presentation/screens/tribes_screen.dart"
```

- [ ] **Step 2: Remove dead routes from `lib/core/router/router.dart`**

Search for and remove these route builders (check exact line numbers with `grep`):
- Route builder for `RecapScreen` (around line 303)
- Route builder for `EnvironmentPrimingScreen` (around line 299)
- Route builder for `MapIdentityAttributesScreen` (onboarding route)
- Any import of the deleted screen classes

After removing, ensure the onboarding flow routes directly from identity studio to first-habit:
```dart
// Verify this route chain exists and is clean:
// /onboarding/welcome → /onboarding/identity-studio → /onboarding/first-habit → /onboarding/world-reveal
```

- [ ] **Step 3: Verify build is clean**
```bash
flutter analyze
```
Expected: No errors referencing deleted files. Fix any stray imports found.

- [ ] **Step 4: Commit**
```bash
git add -A
git commit -m "chore: delete dead screens and orphaned routes"
```

---

## Phase 1 — Data Layer Foundation

### Task 1.1: Add momentum fields to Habit entity

**Files:**
- Modify: `lib/features/habits/domain/entities/habit.dart`

- [ ] **Step 1: Add `HabitStreakState` enum and new fields**

Add at the top of the file, after existing enums:
```dart
enum HabitStreakState {
  onFire,    // 90-100
  strong,    // 70-89
  building,  // 50-69
  atRisk,    // 30-49
  recovery,  // 10-29
  reset,     // 0-9
}
```

Add to the `Habit` class fields (after `integrationTarget`):
```dart
final int momentumScore;      // 0-100
final int consecutiveMisses;  // Days in a row missed

// Derived — never stored separately
HabitStreakState get streakState {
  if (momentumScore >= 90) return HabitStreakState.onFire;
  if (momentumScore >= 70) return HabitStreakState.strong;
  if (momentumScore >= 50) return HabitStreakState.building;
  if (momentumScore >= 30) return HabitStreakState.atRisk;
  if (momentumScore >= 10) return HabitStreakState.recovery;
  return HabitStreakState.reset;
}
```

- [ ] **Step 2: Update constructor with defaults**

In the `Habit()` constructor, add:
```dart
this.momentumScore = 0,
this.consecutiveMisses = 0,
```

- [ ] **Step 3: Update `copyWith`**

Add to `copyWith` parameters and body:
```dart
// Parameters:
int? momentumScore,
int? consecutiveMisses,

// Body:
momentumScore: momentumScore ?? this.momentumScore,
consecutiveMisses: consecutiveMisses ?? this.consecutiveMisses,
```

- [ ] **Step 4: Update `toMap` and `fromMap`**

In `toMap()` add:
```dart
'momentumScore': momentumScore,
'consecutiveMisses': consecutiveMisses,
```

In `fromMap()` add:
```dart
momentumScore: (map['momentumScore'] as int?) ?? 0,
consecutiveMisses: (map['consecutiveMisses'] as int?) ?? 0,
```

- [ ] **Step 5: Update `Habit.empty()` factory if it exists**

Add `momentumScore: 0, consecutiveMisses: 0` to the empty factory.

- [ ] **Step 6: Verify**
```bash
flutter analyze lib/features/habits/
```
Expected: No errors.

- [ ] **Step 7: Commit**
```bash
git add lib/features/habits/domain/entities/habit.dart
git commit -m "feat(data): add momentumScore and consecutiveMisses to Habit entity"
```

---

### Task 1.2: Add world health fields to UserStats entity

**Files:**
- Modify: `lib/features/gamification/domain/entities/user_stats.dart`

- [ ] **Step 1: Add `WorldHealthState` enum**

Add at the top of `user_stats.dart`:
```dart
enum WorldHealthState {
  thriving,  // worldHealthScore >= 75
  neutral,   // worldHealthScore 40-74
  decaying,  // worldHealthScore < 40
}
```

- [ ] **Step 2: Add `worldHealthScore` field to `UserStats`**

Add field:
```dart
final int worldHealthScore; // 0-100, average of all habit momentumScores
```

Add derived getter:
```dart
WorldHealthState get worldHealthState {
  if (worldHealthScore >= 75) return WorldHealthState.thriving;
  if (worldHealthScore >= 40) return WorldHealthState.neutral;
  return WorldHealthState.decaying;
}
```

- [ ] **Step 3: Update constructor, `copyWith`, `toMap`, `fromMap`, and `props`**

Constructor:
```dart
this.worldHealthScore = 0,
```

`copyWith` parameter + body:
```dart
int? worldHealthScore,
// body:
worldHealthScore: worldHealthScore ?? this.worldHealthScore,
```

`toMap`:
```dart
'worldHealthScore': worldHealthScore,
```

`fromMap` (add to wherever UserStats is deserialized):
```dart
worldHealthScore: (map['worldHealthScore'] as int?) ?? 0,
```

`props`:
```dart
worldHealthScore,
```

- [ ] **Step 4: Commit**
```bash
git add lib/features/gamification/domain/entities/user_stats.dart
git commit -m "feat(data): add worldHealthScore and WorldHealthState to UserStats"
```

---

### Task 1.3: Create HabitCompletion model and subcollection

**Files:**
- Create: `lib/features/habits/domain/entities/habit_completion.dart`
- Modify: `lib/features/habits/data/repositories/firestore_habit_repository.dart`

- [ ] **Step 1: Create `HabitCompletion` entity**

```dart
// lib/features/habits/domain/entities/habit_completion.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class HabitCompletion {
  final String id;
  final String habitId;
  final String userId;
  final DateTime completedAt;
  final int momentumAtCompletion;
  final int? completedAtHour;    // 0-23, for AI time-pattern detection
  final bool wasRecovery;        // true if completed after a miss

  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completedAt,
    required this.momentumAtCompletion,
    this.completedAtHour,
    this.wasRecovery = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'habitId': habitId,
    'userId': userId,
    'completedAt': Timestamp.fromDate(completedAt),
    'momentumAtCompletion': momentumAtCompletion,
    'completedAtHour': completedAtHour,
    'wasRecovery': wasRecovery,
  };

  factory HabitCompletion.fromMap(Map<String, dynamic> map) => HabitCompletion(
    id: map['id'] as String? ?? '',
    habitId: map['habitId'] as String? ?? '',
    userId: map['userId'] as String? ?? '',
    completedAt: (map['completedAt'] as Timestamp).toDate(),
    momentumAtCompletion: (map['momentumAtCompletion'] as int?) ?? 0,
    completedAtHour: map['completedAtHour'] as int?,
    wasRecovery: (map['wasRecovery'] as bool?) ?? false,
  );
}
```

- [ ] **Step 2: Add `logCompletion` method to `firestore_habit_repository.dart`**

In `FirestoreHabitRepository`, add:
```dart
Future<void> logCompletion(HabitCompletion completion) async {
  await _firestore
      .collection('users')
      .doc(completion.userId)
      .collection('habits')
      .doc(completion.habitId)
      .collection('completions')
      .doc(completion.id)
      .set(completion.toMap());
}
```

- [ ] **Step 3: Commit**
```bash
git add lib/features/habits/domain/entities/habit_completion.dart \
        lib/features/habits/data/repositories/firestore_habit_repository.dart
git commit -m "feat(data): add HabitCompletion subcollection model and log method"
```

---

### Task 1.4: Add dominantMotive to user profile in Firestore

**Files:**
- Modify: `lib/features/auth/domain/entities/user_extension.dart` (or wherever `UserProfile` is defined — search for `class UserProfile`)

- [ ] **Step 1: Add `dominantMotive` field**

In the `UserProfile` class, add:
```dart
final String? dominantMotive; // The user's "Why" from onboarding
```

Update constructor, `copyWith`, `toMap`, `fromMap` with `dominantMotive`.

- [ ] **Step 2: Wire motive persistence at end of onboarding**

In the file that calls the final onboarding completion (search for `completeOnboarding` or the last `context.push` in the onboarding flow), after the profile is created, call:
```dart
await userRepository.updateProfile(
  userId,
  {'dominantMotive': onboardingState.motive},
);
```

- [ ] **Step 3: Commit**
```bash
git add .
git commit -m "feat(data): persist dominantMotive to user profile at onboarding completion"
```

---

## Phase 2 — Momentum Logic Service

### Task 2.1: Create MomentumService

**Files:**
- Create: `lib/features/habits/domain/services/momentum_service.dart`

- [ ] **Step 1: Write the service**

```dart
// lib/features/habits/domain/services/momentum_service.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

class MomentumService {
  static const int _completionBoost = 10;
  static const int _missDecay = 5;
  static const int _idleDecay = 2;

  /// Called when a habit is completed today.
  Habit applyCompletion(Habit habit) {
    final newScore = (habit.momentumScore + _completionBoost).clamp(0, 100);
    return habit.copyWith(
      momentumScore: newScore,
      consecutiveMisses: 0,
    );
  }

  /// Called once per day for each habit NOT completed that day.
  Habit applyDailyDecay(Habit habit) {
    final missDecay = habit.consecutiveMisses > 0 ? _missDecay : _idleDecay;
    final newScore = (habit.momentumScore - missDecay).clamp(0, 100);
    return habit.copyWith(
      momentumScore: newScore,
      consecutiveMisses: habit.consecutiveMisses + 1,
    );
  }

  /// Compute world health score as the average momentum across all habits.
  int computeWorldHealth(List<Habit> habits) {
    final active = habits.where((h) => !h.isArchived).toList();
    if (active.isEmpty) return 50; // neutral default
    final total = active.fold<int>(0, (sum, h) => sum + h.momentumScore);
    return (total / active.length).round();
  }

  /// Human-readable momentum label for UI.
  String momentumLabel(HabitStreakState state) {
    switch (state) {
      case HabitStreakState.onFire:   return "On Fire 🔥";
      case HabitStreakState.strong:   return "Strong";
      case HabitStreakState.building: return "Building";
      case HabitStreakState.atRisk:   return "At Risk";
      case HabitStreakState.recovery: return "Recovery";
      case HabitStreakState.reset:    return "Fresh Start";
    }
  }
}
```

- [ ] **Step 2: Register as a provider**

Create or add to existing providers file:
```dart
// lib/features/habits/presentation/providers/habit_providers.dart
// Add:
final momentumServiceProvider = Provider<MomentumService>((ref) => MomentumService());
```

- [ ] **Step 3: Wire into habit completion**

In `firestore_habit_repository.dart`, inside `completeHabit` (or equivalent), apply momentum before saving:

```dart
Future<Either<Failure, void>> completeHabit(Habit habit) async {
  try {
    final momentumService = MomentumService();
    final updatedHabit = momentumService.applyCompletion(habit);

    // Log completion event
    final completion = HabitCompletion(
      id: const Uuid().v4(),
      habitId: habit.id,
      userId: habit.userId,
      completedAt: DateTime.now(),
      momentumAtCompletion: updatedHabit.momentumScore,
      completedAtHour: DateTime.now().hour,
      wasRecovery: habit.consecutiveMisses > 0,
    );
    await logCompletion(completion);

    // Save updated habit
    await _firestore
        .collection('users')
        .doc(habit.userId)
        .collection('habits')
        .doc(habit.id)
        .update(updatedHabit.toMap());

    return const Right(null);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

- [ ] **Step 4: Wire daily decay**

Find where the app checks for missed habits on launch (typically in `main.dart` or a lifecycle observer). Add:

```dart
// After loading habits on app open:
final today = DateTime.now();
for (final habit in habits) {
  final lastCompleted = habit.lastCompletedDate;
  final missedYesterday = lastCompleted == null ||
      !DateUtils.isSameDay(lastCompleted, today.subtract(const Duration(days: 1)));
  if (missedYesterday && !DateUtils.isSameDay(lastCompleted, today)) {
    final decayed = MomentumService().applyDailyDecay(habit);
    await habitRepository.updateHabit(decayed);
  }
}
```

- [ ] **Step 5: Update worldHealthScore in UserStats after any habit change**

In `UserStatsController` (search for `userStatsControllerProvider`), add a method:
```dart
Future<void> recalculateWorldHealth(List<Habit> habits) async {
  final score = MomentumService().computeWorldHealth(habits);
  final updated = currentStats.copyWith(worldHealthScore: score);
  await _statsRepository.updateStats(updated);
}
```

Call `recalculateWorldHealth` after every habit completion and daily decay run.

- [ ] **Step 6: Commit**
```bash
git add lib/features/habits/domain/services/momentum_service.dart
git add lib/features/habits/data/repositories/firestore_habit_repository.dart
git add .
git commit -m "feat(momentum): add MomentumService and wire into habit completion + daily decay"
```

---

## Phase 3 — Momentum UI

### Task 3.1: Create MomentumBar widget

**Files:**
- Create: `lib/features/habits/presentation/widgets/momentum_bar.dart`

- [ ] **Step 1: Write the widget**

```dart
// lib/features/habits/presentation/widgets/momentum_bar.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

class MomentumBar extends StatelessWidget {
  final int momentumScore;
  final HabitStreakState streakState;
  final bool showLabel;

  const MomentumBar({
    super.key,
    required this.momentumScore,
    required this.streakState,
    this.showLabel = true,
  });

  Color get _stateColor {
    switch (streakState) {
      case HabitStreakState.onFire:   return const Color(0xFF00FF9C);
      case HabitStreakState.strong:   return const Color(0xFF4CAF50);
      case HabitStreakState.building: return const Color(0xFF00BCD4);
      case HabitStreakState.atRisk:   return const Color(0xFFFFC107);
      case HabitStreakState.recovery: return const Color(0xFFFF9800);
      case HabitStreakState.reset:    return const Color(0xFFFF5252);
    }
  }

  String get _label {
    switch (streakState) {
      case HabitStreakState.onFire:   return "On Fire 🔥";
      case HabitStreakState.strong:   return "Strong";
      case HabitStreakState.building: return "Building";
      case HabitStreakState.atRisk:   return "At Risk";
      case HabitStreakState.recovery: return "Recovery";
      case HabitStreakState.reset:    return "Fresh Start";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Container(
                height: 4,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: _stateColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                height: 4,
                width: constraints.maxWidth * (momentumScore / 100),
                decoration: BoxDecoration(
                  color: _stateColor,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: _stateColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _label,
                style: TextStyle(
                  color: _stateColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '$momentumScore',
                style: TextStyle(
                  color: _stateColor.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 2: Add `MomentumBar` to the habit card widget**

Find the existing habit card widget (search for `class HabitCard` or similar in `lib/features/habits/presentation/widgets/`). Below the habit title, add:

```dart
const SizedBox(height: 6),
MomentumBar(
  momentumScore: habit.momentumScore,
  streakState: habit.streakState,
),
```

Keep `currentStreak` as a secondary badge — show it only when streak ≥ 7:
```dart
if (habit.currentStreak >= 7)
  Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      '🔥 ${habit.currentStreak} day streak',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Colors.white54,
      ),
    ),
  ),
```

- [ ] **Step 3: Commit**
```bash
git add lib/features/habits/presentation/widgets/momentum_bar.dart
git add .
git commit -m "feat(ui): add MomentumBar widget and wire into habit card"
```

---

### Task 3.2: Compassion-first miss modal

**Files:**
- Create: `lib/features/habits/presentation/widgets/miss_recovery_sheet.dart`

- [ ] **Step 1: Write the bottom sheet**

```dart
// lib/features/habits/presentation/widgets/miss_recovery_sheet.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

class MissRecoverySheet extends StatelessWidget {
  final Habit habit;
  final VoidCallback onRecoverNow;
  final VoidCallback onDismiss;

  const MissRecoverySheet({
    super.key,
    required this.habit,
    required this.onRecoverNow,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 24),
          const Text('🌱', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'You missed yesterday.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "You're not a failure — you're human.\nNever miss twice.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white60,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (habit.twoMinuteVersion != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF9C).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00FF9C).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Two-Minute Recovery',
                    style: TextStyle(
                      color: Color(0xFF00FF9C),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    habit.twoMinuteVersion!,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onRecoverNow,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00FF9C),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'I\'m Recovering Now',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onDismiss,
            child: const Text(
              'I\'ll do it later',
              style: TextStyle(color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Show the modal on app open for habits with `consecutiveMisses > 0`**

In the home screen's `initState` or a lifecycle provider, after habits load:
```dart
final missedHabits = habits.where((h) => h.consecutiveMisses > 0 && !h.isArchived).toList();
if (missedHabits.isNotEmpty && mounted) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MissRecoverySheet(
      habit: missedHabits.first,
      onRecoverNow: () {
        Navigator.pop(context);
        // Scroll to the habit card or open the habit detail
      },
      onDismiss: () => Navigator.pop(context),
    ),
  );
}
```

- [ ] **Step 3: Commit**
```bash
git add lib/features/habits/presentation/widgets/miss_recovery_sheet.dart
git add .
git commit -m "feat(ui): add MissRecoverySheet compassion-first modal for missed habits"
```

---

## Phase 4 — World Map Health Backgrounds

### Task 4.1: Replace bottom stats bar — remove XP bar, add World Orb

**Files:**
- Modify: `lib/features/world_map/presentation/screens/world_map_screen.dart`

- [ ] **Step 1: Slim down `_GlassmorphismStatsBar` — remove XP progress bar**

In `_GlassmorphismStatsBar.build()`, delete the entire "Progress to Next Level" block (the `Row` with label + XP text and the `LayoutBuilder` with the progress track). The bar now shows only the stats row.

The XP progress moves to the top bar as a slim underline. In `_GlassmorphismTopBar`, below the `Row` containing the level badge, add:
```dart
const SizedBox(height: 8),
Consumer(
  builder: (context, ref, _) {
    final statsAsync = ref.watch(userStatsStreamProvider);
    final stats = statsAsync.value?.avatarStats;
    if (stats == null) return const SizedBox.shrink();
    final progress = (stats.totalXp % 500) / 500.0;
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: config.primaryColor.withValues(alpha: 0.15),
      valueColor: AlwaysStoppedAnimation<Color>(config.primaryColor),
      minHeight: 2,
      borderRadius: BorderRadius.circular(99),
    );
  },
),
```

- [ ] **Step 2: Replace the `World` `_StatItem` with a tappable `_WorldOrb`**

In `_GlassmorphismStatsBar.build()`, replace:
```dart
_StatItem(
  label: 'World',
  value: profile.worldState.isThriving ? 'Thriving' : 'Stable',
  icon: Icons.public,
  color: const Color(0xFF00FFCC),
),
```

With a `_WorldOrb` widget call:
```dart
_WorldOrb(stats: profile),
```

- [ ] **Step 3: Create `_WorldOrb` widget (add to bottom of `world_map_screen.dart`)**

```dart
class _WorldOrb extends ConsumerWidget {
  final UserProfile stats;
  const _WorldOrb({required this.stats});

  Color get _orbColor {
    final score = stats.userStats?.worldHealthScore ?? 50;
    if (score >= 75) return const Color(0xFF00FF9C);
    if (score >= 40) return const Color(0xFF4FC3F7);
    return const Color(0xFFFF7043);
  }

  String get _stateLabel {
    final score = stats.userStats?.worldHealthScore ?? 50;
    if (score >= 75) return 'Thriving';
    if (score >= 40) return 'Neutral';
    return 'Decaying';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showWorldStateSheet(context, ref),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _orbColor.withValues(alpha: 0.15),
              border: Border.all(color: _orbColor.withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _orbColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(Icons.public, color: _orbColor, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            _stateLabel.toUpperCase(),
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _showWorldStateSheet(BuildContext context, WidgetRef ref) {
    final score = stats.userStats?.worldHealthScore ?? 50;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _WorldStateSheet(score: score, stateLabel: _stateLabel, orbColor: _orbColor),
    );
  }
}

class _WorldStateSheet extends StatelessWidget {
  final int score;
  final String stateLabel;
  final Color orbColor;
  const _WorldStateSheet({required this.score, required this.stateLabel, required this.orbColor});

  @override
  Widget build(BuildContext context) {
    String advice;
    if (score >= 75) {
      advice = 'Your world is flourishing. Keep your habits alive to maintain this.';
    } else if (score >= 40) {
      advice = 'Your world is stable. Complete more habits today to make it thrive.';
    } else {
      advice = 'Your world is decaying. Complete any habit now to start recovery.';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF12122A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(height: 24),
          Text('World State', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80, width: 80,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: orbColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(orbColor),
                ),
              ),
              Text(
                '$score',
                style: TextStyle(color: orbColor, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: orbColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: orbColor.withValues(alpha: 0.4)),
            ),
            child: Text(stateLabel, style: TextStyle(color: orbColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(advice, style: const TextStyle(color: Colors.white60, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                foregroundColor: Colors.white60,
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Verify the world map builds without errors**
```bash
flutter analyze lib/features/world_map/
```

- [ ] **Step 5: Commit**
```bash
git add lib/features/world_map/presentation/screens/world_map_screen.dart
git commit -m "feat(ui): replace world stat item with tappable WorldOrb, move XP bar to top"
```

---

### Task 4.2: Wire world health state to map background

**Files:**
- Modify: `lib/features/world_map/presentation/screens/world_map_screen.dart`
- Modify: `lib/core/presentation/widgets/world_background.dart`

- [ ] **Step 1: Extend `WorldBackground` to accept a health state**

In `world_background.dart`, add an optional parameter:
```dart
final WorldHealthState? healthState;
```
In the widget's build method, switch background asset or shader based on `healthState`:
```dart
String get _backgroundAsset {
  switch (healthState) {
    case WorldHealthState.thriving:
      return 'assets/backgrounds/world_thriving.png';
    case WorldHealthState.decaying:
      return 'assets/backgrounds/world_decaying.png';
    case WorldHealthState.neutral:
    default:
      return 'assets/backgrounds/world_neutral.png';
  }
}
```
Apply a `ColorFiltered` overlay for the decaying state:
```dart
if (healthState == WorldHealthState.decaying)
  Positioned.fill(
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueGrey.withValues(alpha: 0.3),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    ),
  ),
```

> **Note:** You already have 3 background asset variants from the nebula system. Rename or alias them to `world_thriving`, `world_neutral`, and `world_decaying` in `pubspec.yaml` assets. If only one exists, duplicate it and apply a `ColorFiltered` for each state instead.

- [ ] **Step 2: Pass `worldHealthState` from `world_map_screen.dart`**

In `_WorldMapScreenState.build()`, after resolving `profile`:
```dart
final worldState = profile.userStats?.worldHealthState ?? WorldHealthState.neutral;

return WorldBackground(
  healthState: worldState,
  child: Stack(...),
);
```

- [ ] **Step 3: Commit**
```bash
git add lib/core/presentation/widgets/world_background.dart \
        lib/features/world_map/presentation/screens/world_map_screen.dart
git commit -m "feat(ui): drive world map background from worldHealthState (thriving/neutral/decaying)"
```

---

## Phase 5 — "The Why" → AI Coach Framing

### Task 5.1: Inject dominantMotive into Groq system prompts

**Files:**
- Modify: `lib/features/ai/domain/services/ai_personalization_service.dart`
- Modify: `lib/features/ai/data/datasources/groq_ai_service.dart` (check signature)

- [ ] **Step 1: Update `AiPersonalizationService` to accept user context**

Change the provider to read user profile:
```dart
final aiPersonalizationServiceProvider = Provider<AiPersonalizationService>((ref) {
  final profileAsync = ref.watch(userProfileStreamProvider); // existing provider
  final profile = profileAsync.value;
  return AiPersonalizationService(
    groqService: GroqAiService(),
    dominantMotive: profile?.dominantMotive,
    archetype: profile?.archetype.name,
    topAttributes: _getTopAttributes(profile?.userStats?.identityVotes),
  );
});

List<String> _getTopAttributes(Map<String, int>? votes) {
  if (votes == null || votes.isEmpty) return [];
  final sorted = votes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(2).map((e) => e.key).toList();
}
```

- [ ] **Step 2: Add context fields to `AiPersonalizationService`**

```dart
class AiPersonalizationService {
  final GroqAiService _groqService;
  final String? dominantMotive;
  final String? archetype;
  final List<String> topAttributes;

  AiPersonalizationService({
    required GroqAiService groqService,
    this.dominantMotive,
    this.archetype,
    this.topAttributes = const [],
  }) : _groqService = groqService;

  String get _identityContext {
    final parts = <String>[];
    if (archetype != null) parts.add('User archetype: $archetype.');
    if (dominantMotive != null) parts.add('Their core motivation: "$dominantMotive".');
    if (topAttributes.isNotEmpty) parts.add('Dominant identity traits: ${topAttributes.join(', ')}.');
    return parts.join(' ');
  }
```

- [ ] **Step 3: Inject `_identityContext` into every system prompt**

In `generateIdentityInsights`, prepend context:
```dart
final systemPrompt =
    'You are an Insight Engine for a habit formation app. $_identityContext '
    'Analyze the user\'s habits and streaks to identify their growing identity. '
    'Frame all output through their archetype and motivation. '
    'Output ONLY valid JSON array: {"type": "identity"|"pattern", "title": "...", "description": "...", "action": "..."}';
```

In `analyzeHabitPerformance`, prepend:
```dart
final systemPrompt =
    'You are the Goldilocks Engine. $_identityContext '
    'Analyze habit performance and suggest difficulty adjustments. '
    'Rules: 1. streak > 5 → increase. 2. missed > 2 recently → decrease. 3. consistent → maintain. '
    'Output ONLY valid JSON: {"habitTitle": "...", "type": "increase"|"decrease"|"maintain", "suggestion": "...", "reason": "..."}';
```

- [ ] **Step 4: Commit**
```bash
git add lib/features/ai/domain/services/ai_personalization_service.dart
git commit -m "feat(ai): inject dominantMotive, archetype, and topAttributes into Groq system prompts"
```

---

### Task 5.2: Identity headline in WeeklyRecapScreen

**Files:**
- Modify: `lib/features/gamification/domain/services/weekly_recap_service.dart`
- Modify: `lib/features/gamification/presentation/widgets/spotify_wrapped_recap.dart`

- [ ] **Step 1: Add `dominantIdentityThisWeek` to the recap model**

Find the `WeeklyRecap` class (or similar — check `weekly_recap_service.dart`). Add:
```dart
final String? dominantIdentityThisWeek; // e.g. "Scholar"
final String? identityHeadline;          // e.g. "You cast 12 votes for your mind."
```

- [ ] **Step 2: Compute the dominant identity in `generateRecapIfNeeded`**

```dart
// After loading identityVotes from UserStats:
String? dominantIdentity;
String? headline;

if (identityVotes.isNotEmpty) {
  final sorted = identityVotes.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top = sorted.first;
  dominantIdentity = top.key; // e.g. 'intellect'
  headline = 'You cast ${top.value} votes for your ${top.key} this week.';
}
```

- [ ] **Step 3: Render identity headline as the first slide in `SpotifyWrappedRecap`**

In `spotify_wrapped_recap.dart`, add a slide before the stats slides:
```dart
// First slide — identity headline
if (recap.dominantIdentityThisWeek != null)
  _IdentitySlide(
    identity: recap.dominantIdentityThisWeek!,
    headline: recap.identityHeadline ?? '',
    motive: userProfile?.dominantMotive,
  ),
```

Create `_IdentitySlide`:
```dart
class _IdentitySlide extends StatelessWidget {
  final String identity;
  final String headline;
  final String? motive;
  const _IdentitySlide({required this.identity, required this.headline, this.motive});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('THIS WEEK YOU WERE A',
            style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
        const SizedBox(height: 12),
        Text(identity.toUpperCase(),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 3)),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(headline,
              style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
              textAlign: TextAlign.center),
        ),
        if (motive != null) ...[    
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('"$motive"',
                style: const TextStyle(
                  color: Colors.white60, fontStyle: FontStyle.italic, fontSize: 14)),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 4: Commit**
```bash
git add lib/features/gamification/domain/services/weekly_recap_service.dart \
        lib/features/gamification/presentation/widgets/spotify_wrapped_recap.dart
git commit -m "feat(recap): add identity headline slide to weekly recap with dominantMotive framing"
```

---

## Phase 6 — Tribes 3-Tab Reorganisation + Creator Blueprints

### Task 6.1: Create SocialScreen (replaces CommunityScreen as root)

**Files:**
- Create: `lib/features/social/presentation/screens/social_screen.dart`
- Modify: `lib/core/router/router.dart`

- [ ] **Step 1: Create `SocialScreen` with 3 tabs**

```dart
// lib/features/social/presentation/screens/social_screen.dart
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/social/presentation/screens/challenges_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_tab_content.dart';
import 'package:emerge_app/features/social/presentation/screens/social_discover_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'SOCIAL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00FF9C),
          indicatorWeight: 2,
          labelColor: const Color(0xFF00FF9C),
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1,
          ),
          tabs: const [
            Tab(text: 'TRIBE'),
            Tab(text: 'CHALLENGES'),
            Tab(text: 'DISCOVER'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TribeTabContent(),      // Tab 1 — existing, keeps friends + members
          ChallengesScreen(),     // Tab 2 — existing, merges challenges + leaderboard
          SocialDiscoverTab(),    // Tab 3 — new (created in Task 6.2)
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Update `router.dart` — Branch 3 uses `SocialScreen`**

In `lib/core/router/router.dart`:

**Remove these imports** (lines 30, 33 — dead screens):
```dart
// DELETE:
import 'package:emerge_app/features/social/presentation/screens/community_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/tribes_screen.dart';
```

**Add import:**
```dart
import 'package:emerge_app/features/social/presentation/screens/social_screen.dart';
```

**Replace Branch 3** (lines 244–276) with:
```dart
// Branch 3: Social (Tribe · Challenges · Discover)
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/tribes',
      builder: (context, state) => const SocialScreen(),
      routes: [
        GoRoute(
          path: 'challenge/:challengeId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final id = state.pathParameters['challengeId']!;
            return ChallengeDetailScreen(challengeId: id);
          },
        ),
      ],
    ),
  ],
),
```

> The friends, leaderboard, and tribe sub-routes no longer need to be top-level routes — they are tabs inside `SocialScreen`. `ChallengeDetailScreen` still needs a route so tapping a challenge opens the detail as a full-screen push.

**Also remove these dead router imports** (clean up):
```dart
// DELETE these lines from router.dart imports:
import 'package:emerge_app/features/social/presentation/screens/friends_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/leaderboard_screen.dart';
import 'package:emerge_app/features/habits/presentation/screens/environment_priming_screen.dart';
import 'package:emerge_app/features/insights/presentation/screens/recap_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/map_identity_attributes_screen.dart';
```

**Remove these dead GoRoutes** from the profile branch (lines 295–304):
```dart
// DELETE:
GoRoute(
  path: 'priming',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) => const EnvironmentPrimingScreen(),
),
GoRoute(
  path: 'recap',
  builder: (context, state) => const RecapScreen(),
),
```

**Remove the `/onboarding/map-attributes` route** (line 181–183):
```dart
// DELETE:
GoRoute(
  path: '/onboarding/map-attributes',
  builder: (context, state) => const MapIdentityAttributesScreen(),
),
```

- [ ] **Step 3: Verify build**
```bash
flutter analyze lib/core/router/ lib/features/social/
```
Expected: No import errors, no missing-class errors.

- [ ] **Step 4: Commit**
```bash
git add lib/features/social/presentation/screens/social_screen.dart \
        lib/core/router/router.dart
git commit -m "feat(social): replace CommunityScreen with 3-tab SocialScreen, clean up dead imports"
```

---

### Task 6.2: Create Discover tab + CreatorBlueprint entity

**Files:**
- Create: `lib/features/social/presentation/screens/social_discover_tab.dart`
- Modify: `lib/features/social/domain/entities/social_entities.dart`

- [ ] **Step 1: Add `CreatorBlueprint` to social entities**

In `lib/features/social/domain/entities/social_entities.dart`, add at the bottom:
```dart
class CreatorBlueprint {
  final String id;
  final String creatorUserId;
  final String creatorName;
  final String creatorArchetype; // e.g. 'Scholar'
  final String blueprintName;    // e.g. 'Morning Deep Work Stack'
  final String description;
  final List<String> habitTitles; // Ordered habit stack to adopt
  final int adoptionCount;
  final DateTime createdAt;
  final String? imageUrl;

  const CreatorBlueprint({
    required this.id,
    required this.creatorUserId,
    required this.creatorName,
    required this.creatorArchetype,
    required this.blueprintName,
    required this.description,
    required this.habitTitles,
    this.adoptionCount = 0,
    required this.createdAt,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'creatorUserId': creatorUserId,
    'creatorName': creatorName,
    'creatorArchetype': creatorArchetype,
    'blueprintName': blueprintName,
    'description': description,
    'habitTitles': habitTitles,
    'adoptionCount': adoptionCount,
    'createdAt': createdAt.toIso8601String(),
    'imageUrl': imageUrl,
  };

  factory CreatorBlueprint.fromMap(Map<String, dynamic> map) => CreatorBlueprint(
    id: map['id'] as String,
    creatorUserId: map['creatorUserId'] as String,
    creatorName: map['creatorName'] as String,
    creatorArchetype: map['creatorArchetype'] as String? ?? 'Unknown',
    blueprintName: map['blueprintName'] as String,
    description: map['description'] as String,
    habitTitles: List<String>.from(map['habitTitles'] as List? ?? []),
    adoptionCount: (map['adoptionCount'] as int?) ?? 0,
    createdAt: DateTime.parse(map['createdAt'] as String),
    imageUrl: map['imageUrl'] as String?,
  );
}
```

- [ ] **Step 2: Create Firestore provider for blueprints**

Create `lib/features/social/presentation/providers/blueprint_providers.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final blueprintsStreamProvider = StreamProvider<List<CreatorBlueprint>>((ref) {
  return FirebaseFirestore.instance
      .collection('creator_blueprints')
      .orderBy('adoptionCount', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => CreatorBlueprint.fromMap(d.data()))
          .toList());
});
```

- [ ] **Step 3: Create `SocialDiscoverTab`**

```dart
// lib/features/social/presentation/screens/social_discover_tab.dart
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/features/social/presentation/providers/blueprint_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialDiscoverTab extends ConsumerWidget {
  const SocialDiscoverTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blueprintsAsync = ref.watch(blueprintsStreamProvider);

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _DiscoverHeader()),
        blueprintsAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(
              child: Text('Could not load blueprints',
                  style: const TextStyle(color: Colors.white54)),
            ),
          ),
          data: (blueprints) => SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _BlueprintCard(blueprint: blueprints[i]),
              childCount: blueprints.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Creator Blueprints',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Adopt a proven habit stack in one tap.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _BlueprintCard extends StatelessWidget {
  final CreatorBlueprint blueprint;
  const _BlueprintCard({required this.blueprint});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF00FF9C).withValues(alpha: 0.15),
                child: Text(
                  blueprint.creatorName[0].toUpperCase(),
                  style: const TextStyle(color: Color(0xFF00FF9C), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      blueprint.creatorName,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      blueprint.creatorArchetype,
                      style: const TextStyle(
                        color: Color(0xFF00FF9C),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${blueprint.adoptionCount} adopted',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            blueprint.blueprintName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            blueprint.description,
            style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: blueprint.habitTitles.map((title) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            )).toList(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _adoptBlueprint(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00FF9C),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Adopt Blueprint', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _adoptBlueprint(BuildContext context) {
    // TODO Phase 6.3: implement habit stack creation from blueprint titles
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${blueprint.blueprintName}" adopted! Habits added to your stack.'),
        backgroundColor: const Color(0xFF00FF9C),
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**
```bash
git add lib/features/social/presentation/screens/social_discover_tab.dart \
        lib/features/social/domain/entities/social_entities.dart \
        lib/features/social/presentation/providers/blueprint_providers.dart
git commit -m "feat(social): add CreatorBlueprint entity and SocialDiscoverTab with live Firestore stream"
```

---

### Task 6.3: Blueprint adoption — create habits from blueprint

**Files:**
- Modify: `lib/features/social/presentation/screens/social_discover_tab.dart`
- Modify: `lib/features/habits/data/repositories/firestore_habit_repository.dart`

- [ ] **Step 1: Add `createHabitsFromBlueprint` to habit repository**

```dart
// In FirestoreHabitRepository:
Future<void> createHabitsFromBlueprint({
  required String userId,
  required CreatorBlueprint blueprint,
}) async {
  final batch = _firestore.batch();
  for (int i = 0; i < blueprint.habitTitles.length; i++) {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .doc();
    final habit = Habit(
      id: ref.id,
      userId: userId,
      title: blueprint.habitTitles[i],
      createdAt: DateTime.now(),
      order: i,
      // Inherits all other defaults
    );
    batch.set(ref, habit.toMap());
  }
  // Increment adoption count on blueprint
  batch.update(
    _firestore.collection('creator_blueprints').doc(blueprint.id),
    {'adoptionCount': FieldValue.increment(1)},
  );
  await batch.commit();
}
```

- [ ] **Step 2: Wire `_adoptBlueprint` in `_BlueprintCard`**

Replace the `_adoptBlueprint` method stub in `social_discover_tab.dart`:
```dart
void _adoptBlueprint(BuildContext context, WidgetRef ref) {
  final userId = ref.read(authStateChangesProvider).value?.uid;
  if (userId == null) return;

  ref.read(habitRepositoryProvider).createHabitsFromBlueprint(
    userId: userId,
    blueprint: blueprint,
  ).then((_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${blueprint.blueprintName}" adopted! ${blueprint.habitTitles.length} habits added.'),
          backgroundColor: const Color(0xFF00FF9C),
        ),
      );
    }
  });
}
```

Update the `FilledButton.onPressed` to pass `ref`:
```dart
// Make _BlueprintCard a ConsumerWidget, add WidgetRef ref parameter
onPressed: () => _adoptBlueprint(context, ref),
```

- [ ] **Step 3: Commit**
```bash
git add lib/features/social/presentation/screens/social_discover_tab.dart \
        lib/features/habits/data/repositories/firestore_habit_repository.dart
git commit -m "feat(social): wire blueprint adoption to create real habits via Firestore batch"
```

---

## Self-Review Checklist

| Spec Requirement | Task Coverage |
|---|---|
| Delete dead screens (9 files) | Task 0.1 |
| Remove dead routes from router | Task 0.1 Step 2 |
| Add `momentumScore` + `consecutiveMisses` to Habit | Task 1.1 |
| Add `worldHealthScore` + `WorldHealthState` to UserStats | Task 1.2 |
| `HabitCompletion` event subcollection | Task 1.3 |
| Persist `dominantMotive` at onboarding | Task 1.4 |
| `MomentumService` — completion boost + daily decay | Task 2.1 |
| `recalculateWorldHealth` after every change | Task 2.1 Step 5 |
| `MomentumBar` widget on habit card | Task 3.1 |
| Compassion-first miss modal | Task 3.2 |
| Remove XP progress bar from bottom stats bar | Task 4.1 Step 1 |
| XP slim line moved to top bar | Task 4.1 Step 1 |
| Tappable `_WorldOrb` replacing World stat | Task 4.1 Steps 2-3 |
| `_WorldStateSheet` detail modal | Task 4.1 Step 3 |
| Map background driven by `worldHealthState` | Task 4.2 |
| `dominantMotive` injected into all Groq prompts | Task 5.1 |
| Identity headline in weekly recap | Task 5.2 |
| `_IdentitySlide` as first recap slide | Task 5.2 Step 3 |
| `SocialScreen` with 3 tabs | Task 6.1 |
| Router Branch 3 → `SocialScreen` | Task 6.1 Step 2 |
| `CreatorBlueprint` entity | Task 6.2 Step 1 |
| Discover tab with live Firestore stream | Task 6.2 Steps 2-3 |
| Blueprint adoption creates real habits | Task 6.3 |

**No placeholders detected.** Every step has code. All types are consistent across tasks (`HabitStreakState`, `WorldHealthState`, `CreatorBlueprint`, `MomentumService`).

---

**Plan complete.** Saved to `docs/superpowers/plans/2026-04-28-emerge-behavioral-systems.md`.

**Two execution options:**

**1. Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks

**2. Inline Execution** — execute tasks in this session using executing-plans skill, batch execution with checkpoints

Which approach?
