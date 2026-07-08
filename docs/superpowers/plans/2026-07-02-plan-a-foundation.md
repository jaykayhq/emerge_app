# Habitual Engagement — Plan A: Foundation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cut habit completion friction from 8–12s to <3s by restructuring navigation, replacing the confirmation-modal completion flow with one-tap + particle animation, and adding a momentum score to the Habit model.

**Architecture:** Timeline becomes the app's home tab (index 0). A new `HabitCompletionService` becomes the single entry point for all completion paths (in-app, widget, notification). The `Habit` entity gains `momentumScore`, `streakState`, and `consecutiveMisses` fields replacing the current binary streak-reset behaviour.

**Tech Stack:** Flutter, Dart, Riverpod 3 (codegen), Drift (local SQLite), fpdart `Either`, Firestore, `flutter_test` + `mocktail`

---

## Context You Must Read First

Before touching any file, read these. They give you the mental model for this codebase.

- `lib/core/router/router.dart` — understand the `StatefulShellRoute` branch order
- `lib/core/presentation/widgets/scaffold_with_nav_bar.dart` — how tabs are rendered
- `lib/features/habits/domain/entities/habit.dart` — current Habit model fields
- `lib/features/habits/data/repositories/` — how habits are persisted
- `lib/features/timeline/presentation/screens/timeline_screen.dart` — what lives in the timeline; note the `_toggleHabitCompletion` method and `completeHabitProvider` call
- `lib/features/habits/presentation/widgets/` — find the existing habit card widget(s)

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| MODIFY | `lib/core/router/router.dart` | Swap branch 0 (WorldMap) ↔ branch 1 (Timeline) |
| MODIFY | `lib/core/presentation/widgets/scaffold_with_nav_bar.dart` | Reorder nav icons, remove center FAB |
| MODIFY | `lib/features/habits/domain/entities/habit.dart` | Add `momentumScore`, `streakState`, `consecutiveMisses` |
| MODIFY | `lib/features/habits/data/repositories/habit_repository_impl.dart` (or equivalent) | Map new fields to/from Firestore + Drift |
| CREATE | `lib/features/habits/data/services/habit_completion_service.dart` | Unified completion logic, offline-first |
| CREATE | `lib/features/habits/domain/models/completion_result.dart` | Return type for completion |
| MODIFY | `lib/features/habits/presentation/widgets/<habit_card_widget>.dart` | Add one-tap `CompletionZone`, remove confirmation modal |
| CREATE | `lib/core/presentation/widgets/completion_particles.dart` | CustomPainter particle burst |
| CREATE | `lib/core/presentation/widgets/one_tap_completion_zone.dart` | Reusable 48×48 circle button |
| MODIFY | `lib/features/timeline/presentation/screens/timeline_screen.dart` | Wire up `HabitCompletionService`, remove old `_toggleHabitCompletion` path |
| CREATE | `test/features/habits/data/services/habit_completion_service_test.dart` | Unit tests |
| CREATE | `test/core/presentation/widgets/completion_particles_test.dart` | Widget test |

---

## Task 1: Add momentum fields to `Habit` entity

**Files:**
- Modify: `lib/features/habits/domain/entities/habit.dart`
- Modify: `lib/features/habits/data/repositories/habit_repository_impl.dart` (or wherever `toJson`/`fromJson` lives)
- Test: `test/features/habits/domain/entities/habit_test.dart` (create if missing)

### Background
The current `Habit` model has a `currentStreak` integer that resets to 0 on any miss. This creates an all-or-nothing shame loop. We are replacing this with:
- `momentumScore` (int 0–100): increases +10 on completion (cap 100), decreases –15 on miss (floor 0)
- `streakState` (enum): derived from `momentumScore` — `onFire` (≥90), `strong` (≥70), `building` (≥40), `atRisk` (≥20), `recovery` (≥5), `reset` (<5)
- `consecutiveMisses` (int): resets to 0 on any completion, increments +1 on each miss

- [ ] **Step 1.1: Write failing test for momentum fields**

Create `test/features/habits/domain/entities/habit_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

void main() {
  group('Habit momentum fields', () {
    test('Habit has momentumScore defaulting to 0', () {
      // Read the existing Habit constructor carefully first.
      // Copy a minimal valid Habit construction from the existing test or
      // from a factory method in the codebase, then assert:
      final habit = _makeHabit();
      expect(habit.momentumScore, 0);
    });

    test('Habit has consecutiveMisses defaulting to 0', () {
      final habit = _makeHabit();
      expect(habit.consecutiveMisses, 0);
    });

    test('streakState is onFire when momentumScore >= 90', () {
      final habit = _makeHabit(momentumScore: 90);
      expect(habit.streakState, HabitStreakState.onFire);
    });

    test('streakState is strong when momentumScore is 70–89', () {
      final habit = _makeHabit(momentumScore: 75);
      expect(habit.streakState, HabitStreakState.strong);
    });

    test('streakState is building when momentumScore is 40–69', () {
      final habit = _makeHabit(momentumScore: 50);
      expect(habit.streakState, HabitStreakState.building);
    });

    test('streakState is atRisk when momentumScore is 20–39', () {
      final habit = _makeHabit(momentumScore: 25);
      expect(habit.streakState, HabitStreakState.atRisk);
    });

    test('streakState is recovery when momentumScore is 5–19', () {
      final habit = _makeHabit(momentumScore: 10);
      expect(habit.streakState, HabitStreakState.recovery);
    });

    test('streakState is reset when momentumScore < 5', () {
      final habit = _makeHabit(momentumScore: 0);
      expect(habit.streakState, HabitStreakState.reset);
    });
  });
}

Habit _makeHabit({int momentumScore = 0, int consecutiveMisses = 0}) {
  // IMPORTANT: copy the constructor pattern from the existing Habit class.
  // Only add the new fields — do not change existing required fields.
  return Habit(
    id: 'test-id',
    userId: 'user-1',
    title: 'Test Habit',
    momentumScore: momentumScore,
    consecutiveMisses: consecutiveMisses,
    // ... copy all other required fields from the real Habit constructor
  );
}
```

- [ ] **Step 1.2: Run test — expect compile error (fields don't exist yet)**

```bash
flutter test test/features/habits/domain/entities/habit_test.dart
```
Expected: compile error or `NoSuchMethodError` — that's the red phase.

- [ ] **Step 1.3: Add `HabitStreakState` enum**

At the top of `lib/features/habits/domain/entities/habit.dart`, before the `Habit` class, add:

```dart
enum HabitStreakState {
  onFire,    // momentumScore >= 90
  strong,    // >= 70
  building,  // >= 40
  atRisk,    // >= 20
  recovery,  // >= 5
  reset,     // < 5
}
```

- [ ] **Step 1.4: Add fields to `Habit`**

In `lib/features/habits/domain/entities/habit.dart`, add three fields to the existing class. If the class uses `freezed`, add them to the `factory` constructor. If it's a plain class, add them as `final` fields with defaults.

```dart
// Add these three fields (with defaults so existing code doesn't break):
final int momentumScore;      // 0–100, default 0
final int consecutiveMisses;  // default 0

// Add this computed getter (NOT a stored field — derived from momentumScore):
HabitStreakState get streakState {
  if (momentumScore >= 90) return HabitStreakState.onFire;
  if (momentumScore >= 70) return HabitStreakState.strong;
  if (momentumScore >= 40) return HabitStreakState.building;
  if (momentumScore >= 20) return HabitStreakState.atRisk;
  if (momentumScore >= 5)  return HabitStreakState.recovery;
  return HabitStreakState.reset;
}
```

If the class uses `freezed`, run `dart run build_runner build --delete-conflicting-outputs` after this step.

- [ ] **Step 1.5: Add fields to Firestore mapping**

In the repository `fromJson`/`toJson` (wherever Firestore documents are read/written):

```dart
// In fromJson / fromFirestore:
momentumScore: (data['momentumScore'] as int?) ?? 0,
consecutiveMisses: (data['consecutiveMisses'] as int?) ?? 0,

// In toJson / toMap:
'momentumScore': habit.momentumScore,
'consecutiveMisses': habit.consecutiveMisses,
```

Also update the Drift local datasource if Habit is also stored locally in a Drift table. Add columns:

```dart
// In the Drift table definition (app_database.dart):
IntColumn get momentumScore => integer().withDefault(const Constant(0))();
IntColumn get consecutiveMisses => integer().withDefault(const Constant(0))();
```

Then run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 1.6: Run test — expect green**

```bash
flutter test test/features/habits/domain/entities/habit_test.dart
```
Expected: All 8 tests PASS.

- [ ] **Step 1.7: Commit**

```bash
git add lib/features/habits/domain/entities/habit.dart
git add lib/features/habits/data/
git add test/features/habits/domain/entities/habit_test.dart
git commit -m "feat(habits): add momentumScore, consecutiveMisses, streakState to Habit"
```

---

## Task 2: Create `CompletionResult` model

**Files:**
- Create: `lib/features/habits/domain/models/completion_result.dart`
- Test: `test/features/habits/domain/models/completion_result_test.dart`

- [ ] **Step 2.1: Write failing test**

```dart
// test/features/habits/domain/models/completion_result_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/models/completion_result.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

void main() {
  test('CompletionResult holds all required fields', () {
    final result = CompletionResult(
      habitId: 'h1',
      xpEarned: 25,
      newStreakState: HabitStreakState.building,
      newMomentumScore: 50,
      newWorldHealthDelta: 2,
      narratorTrigger: null,
    );
    expect(result.habitId, 'h1');
    expect(result.xpEarned, 25);
    expect(result.newMomentumScore, 50);
    expect(result.narratorTrigger, isNull);
  });
}
```

- [ ] **Step 2.2: Run — expect compile error**

```bash
flutter test test/features/habits/domain/models/completion_result_test.dart
```

- [ ] **Step 2.3: Create `CompletionResult`**

```dart
// lib/features/habits/domain/models/completion_result.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

class CompletionResult {
  final String habitId;
  final int xpEarned;
  final HabitStreakState newStreakState;
  final int newMomentumScore;
  final int newWorldHealthDelta;
  /// If non-null, the Narrator should be triggered with this key after completion.
  /// Values match NarratorTrigger enum names (e.g., 'onFireState', 'streakBreakFirstMiss').
  final String? narratorTrigger;

  const CompletionResult({
    required this.habitId,
    required this.xpEarned,
    required this.newStreakState,
    required this.newMomentumScore,
    required this.newWorldHealthDelta,
    this.narratorTrigger,
  });
}
```

- [ ] **Step 2.4: Run — expect green**

```bash
flutter test test/features/habits/domain/models/completion_result_test.dart
```

- [ ] **Step 2.5: Commit**

```bash
git add lib/features/habits/domain/models/completion_result.dart
git add test/features/habits/domain/models/completion_result_test.dart
git commit -m "feat(habits): add CompletionResult model"
```

---

## Task 3: Create `HabitCompletionService`

**Files:**
- Create: `lib/features/habits/data/services/habit_completion_service.dart`
- Test: `test/features/habits/data/services/habit_completion_service_test.dart`

### Background
This service is the **single source of truth** for marking a habit complete. All completion paths (Timeline tap, home screen widget, notification action) call this one service. It must work **fully offline**: write to Drift first, enqueue Firestore sync.

- [ ] **Step 3.1: Define `CompletionSource` enum**

Add to the bottom of `lib/features/habits/domain/models/completion_result.dart`:

```dart
enum CompletionSource {
  timeline,      // Tapped inside the app on Timeline tab
  widget,        // Tapped on a home screen widget
  notification,  // Tapped "Complete" on a notification action button
  healthSync,    // Auto-completed via health data (future)
  voice,         // Voice command (future)
}
```

- [ ] **Step 3.2: Write failing tests**

```dart
// test/features/habits/data/services/habit_completion_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/habits/data/services/habit_completion_service.dart';
import 'package:emerge_app/features/habits/domain/models/completion_result.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

// You will need to mock whatever repository/datasource the service depends on.
// Find the habit repository interface in lib/features/habits/domain/repositories/
// and create a mock for it here.
class MockHabitRepository extends Mock implements HabitRepository {}

void main() {
  late HabitCompletionService sut;
  late MockHabitRepository mockRepo;

  setUp(() {
    mockRepo = MockHabitRepository();
    sut = HabitCompletionService(habitRepository: mockRepo);
  });

  group('markComplete', () {
    test('returns CompletionResult with xpEarned > 0 on first completion', () async {
      // Arrange: stub the repo to return a habit with momentumScore = 0
      final habit = _makeHabit(momentumScore: 0, consecutiveMisses: 0);
      when(() => mockRepo.getHabitById('h1'))
          .thenAnswer((_) async => Right(habit));
      when(() => mockRepo.updateHabit(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await sut.markComplete(
        'h1',
        source: CompletionSource.timeline,
      );

      // Assert
      expect(result.xpEarned, greaterThan(0));
      expect(result.habitId, 'h1');
    });

    test('momentumScore increases by 10 on completion (capped at 100)', () async {
      final habit = _makeHabit(momentumScore: 95);
      when(() => mockRepo.getHabitById('h1'))
          .thenAnswer((_) async => Right(habit));
      when(() => mockRepo.updateHabit(any()))
          .thenAnswer((_) async => const Right(null));

      final result = await sut.markComplete('h1', source: CompletionSource.timeline);

      // 95 + 10 = 105, capped to 100
      expect(result.newMomentumScore, 100);
    });

    test('consecutiveMisses resets to 0 on completion', () async {
      final habit = _makeHabit(momentumScore: 30, consecutiveMisses: 2);
      when(() => mockRepo.getHabitById('h1'))
          .thenAnswer((_) async => Right(habit));
      when(() => mockRepo.updateHabit(any()))
          .thenAnswer((_) async => const Right(null));

      final result = await sut.markComplete('h1', source: CompletionSource.timeline);

      // Verify the repo was called with consecutiveMisses == 0
      final captured = verify(() => mockRepo.updateHabit(captureAny())).captured;
      final updatedHabit = captured.first as Habit;
      expect(updatedHabit.consecutiveMisses, 0);
    });

    test('narratorTrigger is onFireState when momentum reaches >= 90', () async {
      // Going from 80 → 90 should flag onFireState
      final habit = _makeHabit(momentumScore: 80);
      when(() => mockRepo.getHabitById('h1'))
          .thenAnswer((_) async => Right(habit));
      when(() => mockRepo.updateHabit(any()))
          .thenAnswer((_) async => const Right(null));

      final result = await sut.markComplete('h1', source: CompletionSource.timeline);

      expect(result.newMomentumScore, 90);
      expect(result.narratorTrigger, 'onFireState');
    });
  });
}

Habit _makeHabit({int momentumScore = 0, int consecutiveMisses = 0}) {
  // Copy a minimal valid Habit from the codebase (check existing tests for examples)
  return Habit(
    id: 'h1',
    userId: 'user-1',
    title: 'Test Habit',
    momentumScore: momentumScore,
    consecutiveMisses: consecutiveMisses,
    // ... all other required fields
  );
}
```

- [ ] **Step 3.3: Run — expect compile error**

```bash
flutter test test/features/habits/data/services/habit_completion_service_test.dart
```

- [ ] **Step 3.4: Implement `HabitCompletionService`**

```dart
// lib/features/habits/data/services/habit_completion_service.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/completion_result.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';

class HabitCompletionService {
  final HabitRepository habitRepository;

  const HabitCompletionService({required this.habitRepository});

  Future<CompletionResult> markComplete(
    String habitId, {
    required CompletionSource source,
    DateTime? completedAt,
  }) async {
    final habitResult = await habitRepository.getHabitById(habitId);

    return habitResult.fold(
      (failure) => throw Exception('Habit not found: ${failure.message}'),
      (habit) async {
        final now = completedAt ?? DateTime.now();

        // Calculate new momentum (cap at 100)
        final newMomentum = (habit.momentumScore + 10).clamp(0, 100);
        final oldState = habit.streakState;

        // Compute new streak state from new momentum
        final newState = _stateFromScore(newMomentum);

        // Determine if Narrator should fire
        String? narratorTrigger;
        if (oldState != HabitStreakState.onFire &&
            newState == HabitStreakState.onFire) {
          narratorTrigger = 'onFireState';
        }

        // XP: base 25, bonus 10 if coming back from a miss
        final xp = 25 + (habit.consecutiveMisses > 0 ? 10 : 0);

        final updatedHabit = habit.copyWith(
          momentumScore: newMomentum,
          consecutiveMisses: 0,
          lastCompletedDate: now,
          // Keep existing streak fields for backward compat:
          currentStreak: habit.currentStreak + 1,
        );

        await habitRepository.updateHabit(updatedHabit);

        return CompletionResult(
          habitId: habitId,
          xpEarned: xp,
          newStreakState: newState,
          newMomentumScore: newMomentum,
          newWorldHealthDelta: 2,
          narratorTrigger: narratorTrigger,
        );
      },
    );
  }

  HabitStreakState _stateFromScore(int score) {
    if (score >= 90) return HabitStreakState.onFire;
    if (score >= 70) return HabitStreakState.strong;
    if (score >= 40) return HabitStreakState.building;
    if (score >= 20) return HabitStreakState.atRisk;
    if (score >= 5)  return HabitStreakState.recovery;
    return HabitStreakState.reset;
  }
}
```

> **Note on `copyWith`:** If `Habit` uses `freezed`, `copyWith` is auto-generated. If it's a plain class, you may need to add a `copyWith` method manually. Check the existing class.

- [ ] **Step 3.5: Run — expect green**

```bash
flutter test test/features/habits/data/services/habit_completion_service_test.dart
```

- [ ] **Step 3.6: Commit**

```bash
git add lib/features/habits/data/services/habit_completion_service.dart
git add lib/features/habits/domain/models/completion_result.dart
git add test/features/habits/data/services/habit_completion_service_test.dart
git commit -m "feat(habits): add HabitCompletionService with momentum logic"
```

---

## Task 4: Completion particles widget

**Files:**
- Create: `lib/core/presentation/widgets/completion_particles.dart`
- Create: `lib/core/presentation/widgets/one_tap_completion_zone.dart`
- Test: `test/core/presentation/widgets/completion_particles_test.dart`

- [ ] **Step 4.1: Write widget test**

```dart
// test/core/presentation/widgets/completion_particles_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/presentation/widgets/completion_particles.dart';

void main() {
  testWidgets('CompletionParticles renders without error', (tester) async {
    bool completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompletionParticles(
            color: Colors.teal,
            onAnimationComplete: () => completed = true,
          ),
        ),
      ),
    );
    // Let the animation run for 1 second (it completes in 800ms)
    await tester.pump(const Duration(milliseconds: 900));
    expect(completed, isTrue);
  });

  testWidgets('OneTapCompletionZone fires callback on tap', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OneTapCompletionZone(
            isCompleted: false,
            archetypeColor: Colors.teal,
            onComplete: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(OneTapCompletionZone));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 4.2: Run — expect compile error**

```bash
flutter test test/core/presentation/widgets/completion_particles_test.dart
```

- [ ] **Step 4.3: Create `CompletionParticles`**

```dart
// lib/core/presentation/widgets/completion_particles.dart
import 'dart:math';
import 'package:flutter/material.dart';

class _Particle {
  Offset position;
  Offset velocity;
  double opacity;
  final double size;
  _Particle({
    required this.position,
    required this.velocity,
    required this.opacity,
    required this.size,
  });
}

class CompletionParticles extends StatefulWidget {
  final Color color;
  final VoidCallback? onAnimationComplete;

  const CompletionParticles({
    super.key,
    required this.color,
    this.onAnimationComplete,
  });

  @override
  State<CompletionParticles> createState() => _CompletionParticlesState();
}

class _CompletionParticlesState extends State<CompletionParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(35, (_) => _Particle(
      position: const Offset(0, 0),
      velocity: Offset(
        (_random.nextDouble() - 0.5) * 6,
        -(_random.nextDouble() * 5 + 2),
      ),
      opacity: 1.0,
      size: _random.nextDouble() * 6 + 3,
    ));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() {
        setState(() {
          for (final p in _particles) {
            p.position += p.velocity;
            p.velocity += const Offset(0, 0.3); // gravity
            p.opacity = (1.0 - _controller.value).clamp(0.0, 1.0);
          }
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationComplete?.call();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(_particles, widget.color),
      size: const Size(80, 80),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  _ParticlePainter(this.particles, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final p in particles) {
      final paint = Paint()
        ..color = color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center + p.position, p.size / 2, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
```

- [ ] **Step 4.4: Create `OneTapCompletionZone`**

```dart
// lib/core/presentation/widgets/one_tap_completion_zone.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OneTapCompletionZone extends StatefulWidget {
  final bool isCompleted;
  final Color archetypeColor;
  final VoidCallback onComplete;

  const OneTapCompletionZone({
    super.key,
    required this.isCompleted,
    required this.archetypeColor,
    required this.onComplete,
  });

  @override
  State<OneTapCompletionZone> createState() => _OneTapCompletionZoneState();
}

class _OneTapCompletionZoneState extends State<OneTapCompletionZone>
    with SingleTickerProviderStateMixin {
  late AnimationController _fillController;
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    if (widget.isCompleted) _fillController.value = 1.0;
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isCompleted) return;
    HapticFeedback.lightImpact();
    _fillController.forward();
    setState(() => _showParticles = true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _fillController,
              builder: (_, __) => Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.archetypeColor
                      .withValues(alpha: _fillController.value),
                  border: Border.all(
                    color: widget.archetypeColor,
                    width: 2,
                  ),
                ),
                child: _fillController.value >= 1.0
                    ? Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
            if (_showParticles)
              CompletionParticles(
                color: widget.archetypeColor,
                onAnimationComplete: () =>
                    setState(() => _showParticles = false),
              ),
          ],
        ),
      ),
    );
  }
}
```

> **Note:** Add `import 'package:emerge_app/core/presentation/widgets/completion_particles.dart';` at the top of `one_tap_completion_zone.dart`.

- [ ] **Step 4.5: Run — expect green**

```bash
flutter test test/core/presentation/widgets/completion_particles_test.dart
```

- [ ] **Step 4.6: Commit**

```bash
git add lib/core/presentation/widgets/completion_particles.dart
git add lib/core/presentation/widgets/one_tap_completion_zone.dart
git add test/core/presentation/widgets/completion_particles_test.dart
git commit -m "feat(ui): add CompletionParticles and OneTapCompletionZone widgets"
```

---

## Task 5: Wire up `OneTapCompletionZone` in the habit card

**Files:**
- Modify: the existing habit card widget (find it at `lib/features/habits/presentation/widgets/` — it's the widget used by `HierarchicalHabitTimeline`)

- [ ] **Step 5.1: Identify the habit card widget**

Read `lib/features/timeline/presentation/widgets/habit_timeline_section.dart`. Find what widget renders individual habit rows. Note its file path.

- [ ] **Step 5.2: Delete the confirmation modal**

Find any `showDialog` or `showModalBottomSheet` call that asks "Are you sure?" before completing a habit. Delete it entirely. Trust the user.

- [ ] **Step 5.3: Add `OneTapCompletionZone` to the card**

In the habit card widget, replace the existing completion button/tap handler with:

```dart
// Import at top:
import 'package:emerge_app/core/presentation/widgets/one_tap_completion_zone.dart';

// In the card's Row/Stack where the checkmark lives:
OneTapCompletionZone(
  isCompleted: habit.isCompletedToday, // use whatever field tracks today's completion
  archetypeColor: archetypeColor,       // pass in from theme or parent
  onComplete: () => onHabitToggle(habit),
),
```

- [ ] **Step 5.4: Run the app and manually verify**

```bash
flutter run
```

Navigate to Timeline. Tap the completion circle on a habit.
- [ ] Particles burst from the tap point
- [ ] Haptic fires
- [ ] Card dims immediately (no dialog)
- [ ] No navigation away from the screen
- Total time from tap to confirmed: under 3 seconds

- [ ] **Step 5.5: Commit**

```bash
git add lib/features/habits/presentation/widgets/
git commit -m "feat(timeline): one-tap habit completion, remove confirmation modal"
```

---

## Task 6: Restructure navigation (Timeline as Tab 0)

**Files:**
- Modify: `lib/core/router/router.dart`
- Modify: `lib/core/presentation/widgets/scaffold_with_nav_bar.dart`

### Background
Currently: branch 0 = WorldMap (`/`), branch 1 = Timeline (`/timeline`).
After: branch 0 = Timeline (`/timeline`), branch 1 = WorldMap (`/`).
The center FAB (`+`) is removed from the nav bar. A `+` button moves to the Timeline screen's bottom-right corner.

- [ ] **Step 6.1: Swap branch order in `router.dart`**

In the `StatefulShellRoute.indexedStack` call, swap the first two branches so Timeline is first:

```dart
// BEFORE (approximate):
StatefulShellRoute.indexedStack(
  branches: [
    StatefulShellBranch(routes: [/* WorldMap */]),  // index 0
    StatefulShellBranch(routes: [/* Timeline */]),  // index 1
    StatefulShellBranch(routes: [/* Social */]),    // index 2
    StatefulShellBranch(routes: [/* Profile */]),   // index 3
  ],
)

// AFTER:
StatefulShellRoute.indexedStack(
  branches: [
    StatefulShellBranch(routes: [/* Timeline */]),  // index 0 ← HOME
    StatefulShellBranch(routes: [/* WorldMap */]),  // index 1
    StatefulShellBranch(routes: [/* Social */]),    // index 2
    StatefulShellBranch(routes: [/* Profile */]),   // index 3
  ],
)
```

- [ ] **Step 6.2: Update nav bar icons in `scaffold_with_nav_bar.dart`**

Reorder the `BottomNavigationBarItem` list to match the new branch order:

```dart
// New order:
BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Today'),   // Timeline
BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'World'),            // World Map
BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Tribe'),          // Social
BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),             // Profile
```

- [ ] **Step 6.3: Remove the center FAB**

Find where the center `ExtendedFAB` or `FloatingActionButton` is rendered in `scaffold_with_nav_bar.dart`. Delete it. Ensure `floatingActionButton: null` or remove the property entirely.

- [ ] **Step 6.4: Add `+` button to Timeline screen**

In `lib/features/timeline/presentation/screens/timeline_screen.dart`, add a `floatingActionButton` to the `Scaffold` (or equivalent):

```dart
floatingActionButton: FloatingActionButton.small(
  onPressed: () => context.push('/timeline/create-habit'),
  backgroundColor: EmergeColors.teal,
  child: const Icon(Icons.add, color: Colors.black),
),
floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
```

- [ ] **Step 6.5: Run the app and verify**

```bash
flutter run
```
- [ ] App opens to Timeline (not World Map)
- [ ] Bottom nav shows Today/World/Tribe/Me (in that order)
- [ ] No center FAB
- [ ] Small `+` button appears bottom-right of Timeline
- [ ] Tapping `+` navigates to habit creation

- [ ] **Step 6.6: Commit**

```bash
git add lib/core/router/router.dart
git add lib/core/presentation/widgets/scaffold_with_nav_bar.dart
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "feat(nav): Timeline is home tab (index 0), remove center FAB"
```

---

## Task 7: Wire `HabitCompletionService` into Timeline

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`
- Modify: `lib/features/habits/presentation/providers/habit_providers.dart` (or wherever Riverpod providers live)

- [ ] **Step 7.1: Register `HabitCompletionService` as a Riverpod provider**

Find `lib/features/habits/presentation/providers/habit_providers.dart` (or create if missing):

```dart
// Add to habit providers:
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/features/habits/data/services/habit_completion_service.dart';

part 'habit_providers.g.dart'; // (if using codegen — check existing pattern)

@riverpod
HabitCompletionService habitCompletionService(Ref ref) {
  return HabitCompletionService(
    habitRepository: ref.watch(habitRepositoryProvider),
  );
}
```

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 7.2: Replace `_toggleHabitCompletion` in `timeline_screen.dart`**

The current method calls `ref.read(completeHabitProvider(habit.id))` directly. Replace the body:

```dart
void _toggleHabitCompletion(Habit habit) async {
  final now = DateTime.now();
  final isCompleted = habit.lastCompletedDate != null &&
      habit.lastCompletedDate!.year == now.year &&
      habit.lastCompletedDate!.month == now.month &&
      habit.lastCompletedDate!.day == now.day;

  if (isCompleted) return; // Already done — do nothing (no undo in this version)

  try {
    final service = ref.read(habitCompletionServiceProvider);
    final result = await service.markComplete(
      habit.id,
      source: CompletionSource.timeline,
    );

    // Show XP snackbar (keep existing _showCompletionCelebration for milestones)
    if (result.newStreakState == HabitStreakState.onFire ||
        result.xpEarned >= 35) {
      _showCompletionCelebration(
        xpEarned: result.xpEarned,
        newStreak: habit.currentStreak + 1,
        isMilestone: true,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${habit.title} ✓  +${result.xpEarned} XP'),
          backgroundColor: EmergeColors.teal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not complete habit — try again'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
```

- [ ] **Step 7.3: Run integration test**

```bash
flutter run
```
Complete a habit. Verify:
- [ ] Snackbar shows XP
- [ ] Habit card shows as completed
- [ ] No dialog appeared

- [ ] **Step 7.4: Commit**

```bash
git add lib/features/habits/presentation/providers/
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "feat(timeline): wire HabitCompletionService, replace toggle handler"
```

---

## Verification Checklist (Plan A Complete)

Run this before marking Plan A done:

```bash
flutter test test/features/habits/
flutter test test/core/presentation/widgets/completion_particles_test.dart
dart analyze lib/
```

Manual checks:
- [ ] App opens to Timeline tab
- [ ] Tapping completion circle on habit: particles fire, haptic, no dialog, card dims
- [ ] Total time app-open → habit-completed: under 3 seconds (time it with a stopwatch)
- [ ] World Map is reachable via Tab 1
- [ ] No Dart analysis errors
- [ ] `flutter test` shows 0 failures
