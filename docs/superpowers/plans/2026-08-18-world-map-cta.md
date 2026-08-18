# World Map Flamekeeper Call-to-Action Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Transform the World Map from a passive visualization into an active identity engine by introducing the Flamekeeper's Stoking Call-to-Action dock (Next Best Action queue), living archetype node status badges, and kinetic flame-stoking feedback.

**Architecture:** Domain service layer evaluates uncompleted habits, decaying attributes, and contextual factors (NextIdentityVoteService, ArchetypeStatusService). Riverpod streams/providers feed the UI. Presentation layer features WorldStokingDock, updated WorldTypeNode, and kinetic WorldSparkBurst particle stream on WorldMapScreen.

**Tech Stack:** Flutter, Dart 3.5+, flutter_riverpod, go_router, Drift SQLite.

---

## File Structure

`
lib/features/world_map/
├── domain/
│   ├── models/
│   │   ├── archetype_node_state.dart          # [NEW] Enum/model representing node status (complete, pending, decaying)
│   │   └── next_identity_vote.dart             # [NEW] Data model for queued Next Best Action
│   └── services/
│       ├── next_identity_vote_service.dart     # [NEW] Pure prioritization logic for NBA
│       └── archetype_status_service.dart       # [NEW] Evaluates per-archetype daily status
├── presentation/
│   ├── providers/
│   │   ├── next_identity_vote_provider.dart    # [NEW] Riverpod provider for active NBA
│   │   └── archetype_node_states_provider.dart # [NEW] Riverpod provider for archetype states
│   ├── screens/
│   │   └── world_map_screen.dart               # [MODIFY] Integrates dock and spark burst overlay
│   └── widgets/
│       ├── world_stoking_dock.dart             # [NEW] Floating glassmorphism CTA card
│       ├── world_type_node.dart                # [MODIFY] Adds status badges
│       └── world_spark_burst.dart              # [NEW] Kinetic particle burst animation
test/features/world_map/
├── domain/
│   ├── services/
│   │   ├── next_identity_vote_service_test.dart# [NEW] Unit tests for NBA prioritization
│   │   └── archetype_status_service_test.dart  # [NEW] Unit tests for archetype status calculation
├── presentation/
│   ├── providers/
│   │   ├── next_identity_vote_provider_test.dart # [NEW] Unit tests for vote provider
│   │   └── archetype_node_states_provider_test.dart # [NEW] Unit tests for node states provider
│   ├── widgets/
│   │   ├── world_stoking_dock_test.dart        # [NEW] Widget tests for Stoking Dock
│   │   └── world_type_node_test.dart           # [MODIFY] Widget tests for node badges
│   └── screens/
│       └── world_map_screen_test.dart          # [MODIFY] Screen integration tests
`

---

## Tasks

### Task 1: Domain Models (ArchetypeNodeState & NextIdentityVote)

**Files:**
- Create: lib/features/world_map/domain/models/archetype_node_state.dart
- Create: lib/features/world_map/domain/models/next_identity_vote.dart
- Create: 	est/features/world_map/domain/models/archetype_node_state_test.dart
- Create: 	est/features/world_map/domain/models/next_identity_vote_test.dart

- [ ] **Step 1: Write the failing tests for models**

`dart
// test/features/world_map/domain/models/archetype_node_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_node_state.dart';

void main() {
  test('ArchetypeNodeState has correct properties', () {
    const state = ArchetypeNodeState(
      status: NodeHealthStatus.pending,
      pendingCount: 2,
      completedCount: 1,
      hasDecay: false,
    );
    expect(state.status, NodeHealthStatus.pending);
    expect(state.pendingCount, 2);
    expect(state.isComplete, false);
  });
}
`

`dart
// test/features/world_map/domain/models/next_identity_vote_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/next_identity_vote.dart';

void main() {
  test('NextIdentityVote.actionable creates correct model', () {
    final habit = Habit(
      id: 'h1',
      title: 'Deep Work',
      attribute: HabitAttribute.craft,
      frequency: HabitFrequency.daily,
      streak: 5,
      completedToday: false,
      userId: 'u1',
    );
    final vote = NextIdentityVote.actionable(
      habit: habit,
      attribute: HabitAttribute.craft,
      vitalityImpactPercent: 14,
      isRecovery: false,
    );
    expect(vote.isActionable, true);
    expect(vote.habit?.title, 'Deep Work');
    expect(vote.vitalityImpactPercent, 14);
  });
}
`

- [ ] **Step 2: Run tests to verify they fail**

Run: lutter test test/features/world_map/domain/models/ --timeout 60s
Expected: FAIL (types not found)

- [ ] **Step 3: Implement domain models**

`dart
// lib/features/world_map/domain/models/archetype_node_state.dart
enum NodeHealthStatus {
  complete,
  pending,
  decaying,
  idle,
}

class ArchetypeNodeState {
  final NodeHealthStatus status;
  final int pendingCount;
  final int completedCount;
  final bool hasDecay;

  const ArchetypeNodeState({
    required this.status,
    this.pendingCount = 0,
    this.completedCount = 0,
    this.hasDecay = false,
  });

  bool get isComplete => status == NodeHealthStatus.complete;
}
`

`dart
// lib/features/world_map/domain/models/next_identity_vote.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

enum NextVoteType {
  actionable,
  harmonized,
  empty,
}

class NextIdentityVote {
  final NextVoteType type;
  final Habit? habit;
  final HabitAttribute? attribute;
  final int vitalityImpactPercent;
  final bool isRecovery;

  const NextIdentityVote._({
    required this.type,
    this.habit,
    this.attribute,
    this.vitalityImpactPercent = 0,
    this.isRecovery = false,
  });

  factory NextIdentityVote.actionable({
    required Habit habit,
    required HabitAttribute attribute,
    required int vitalityImpactPercent,
    bool isRecovery = false,
  }) => NextIdentityVote._(
    type: NextVoteType.actionable,
    habit: habit,
    attribute: attribute,
    vitalityImpactPercent: vitalityImpactPercent,
    isRecovery: isRecovery,
  );

  factory NextIdentityVote.harmonized() => const NextIdentityVote._(
    type: NextVoteType.harmonized,
  );

  factory NextIdentityVote.empty() => const NextIdentityVote._(
    type: NextVoteType.empty,
  );

  bool get isActionable => type == NextVoteType.actionable && habit != null;
  bool get isHarmonized => type == NextVoteType.harmonized;
  bool get isEmpty => type == NextVoteType.empty;
}
`

- [ ] **Step 4: Run tests to verify they pass**

Run: lutter test test/features/world_map/domain/models/ --timeout 60s
Expected: PASS

- [ ] **Step 5: Commit**

`ash
git add lib/features/world_map/domain/models/ test/features/world_map/domain/models/
git commit -m feat(world_map): add ArchetypeNodeState and NextIdentityVote models
`

---

### Task 2: Pure Domain Services (NextIdentityVoteService & ArchetypeStatusService)

**Files:**
- Create: lib/features/world_map/domain/services/next_identity_vote_service.dart
- Create: lib/features/world_map/domain/services/archetype_status_service.dart
- Create: 	est/features/world_map/domain/services/next_identity_vote_service_test.dart
- Create: 	est/features/world_map/domain/services/archetype_status_service_test.dart

- [ ] **Step 1: Write failing tests for domain services**

`dart
// test/features/world_map/domain/services/next_identity_vote_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/services/next_identity_vote_service.dart';

void main() {
  final service = NextIdentityVoteService();

  test('returns empty when no habits exist', () {
    final vote = service.calculateNextVote(
      habits: [],
      entropy: 0.0,
    );
    expect(vote.isEmpty, true);
  });

  test('returns harmonized when all habits completed today', () {
    final habits = [
      Habit(id: '1', title: 'A', attribute: HabitAttribute.mind, frequency: HabitFrequency.daily, streak: 1, completedToday: true, userId: 'u1'),
    ];
    final vote = service.calculateNextVote(
      habits: habits,
      entropy: 0.0,
    );
    expect(vote.isHarmonized, true);
  });

  test('prioritizes recovery when entropy > 0', () {
    final habits = [
      Habit(id: '1', title: 'Meditate', attribute: HabitAttribute.spirit, frequency: HabitFrequency.daily, streak: 0, completedToday: false, userId: 'u1'),
      Habit(id: '2', title: 'Workout', attribute: HabitAttribute.body, frequency: HabitFrequency.daily, streak: 5, completedToday: false, userId: 'u1'),
    ];
    final vote = service.calculateNextVote(
      habits: habits,
      entropy: 0.3,
    );
    expect(vote.isActionable, true);
    expect(vote.isRecovery, true);
  });
}
`

- [ ] **Step 2: Run tests to verify failure**

Run: lutter test test/features/world_map/domain/services/next_identity_vote_service_test.dart --timeout 60s
Expected: FAIL

- [ ] **Step 3: Implement domain services**

`dart
// lib/features/world_map/domain/services/next_identity_vote_service.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/next_identity_vote.dart';

class NextIdentityVoteService {
  NextIdentityVote calculateNextVote({
    required List<Habit> habits,
    required double entropy,
  }) {
    if (habits.isEmpty) {
      return NextIdentityVote.empty();
    }

    final uncompleted = habits.where((h) => !h.completedToday).toList();
    if (uncompleted.isEmpty) {
      return NextIdentityVote.harmonized();
    }

    // If entropy > 0, prioritize recovery habit
    final isRecovery = entropy > 0.05;

    // Prioritize habits with lowest streak or first uncompleted
    uncompleted.sort((a, b) {
      if (isRecovery) {
        return a.streak.compareTo(b.streak);
      }
      return b.streak.compareTo(a.streak);
    });

    final selectedHabit = uncompleted.first;
    final totalHabits = habits.length;
    final impact = ((1.0 / totalHabits) * 100).round().clamp(10, 35);

    return NextIdentityVote.actionable(
      habit: selectedHabit,
      attribute: selectedHabit.attribute,
      vitalityImpactPercent: impact,
      isRecovery: isRecovery,
    );
  }
}
`

`dart
// lib/features/world_map/domain/services/archetype_status_service.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_node_state.dart';

class ArchetypeStatusService {
  Map<HabitAttribute, ArchetypeNodeState> calculateNodeStates({
    required List<Habit> habits,
    required double entropy,
  }) {
    final result = <HabitAttribute, ArchetypeNodeState>{};

    for (final attr in HabitAttribute.values) {
      final attrHabits = habits.where((h) => h.attribute == attr).toList();
      if (attrHabits.isEmpty) {
        result[attr] = const ArchetypeNodeState(status: NodeHealthStatus.idle);
        continue;
      }

      final completed = attrHabits.where((h) => h.completedToday).length;
      final pending = attrHabits.length - completed;

      if (pending == 0) {
        result[attr] = ArchetypeNodeState(
          status: NodeHealthStatus.complete,
          completedCount: completed,
        );
      } else if (entropy > 0.1 && completed == 0) {
        result[attr] = ArchetypeNodeState(
          status: NodeHealthStatus.decaying,
          pendingCount: pending,
          completedCount: completed,
          hasDecay: true,
        );
      } else {
        result[attr] = ArchetypeNodeState(
          status: NodeHealthStatus.pending,
          pendingCount: pending,
          completedCount: completed,
        );
      }
    }

    return result;
  }
}
`

- [ ] **Step 4: Run tests to verify pass**

Run: lutter test test/features/world_map/domain/services/ --timeout 60s
Expected: PASS

- [ ] **Step 5: Commit**

`ash
git add lib/features/world_map/domain/services/ test/features/world_map/domain/services/
git commit -m feat(world_map): add NextIdentityVoteService and ArchetypeStatusService
`

---

### Task 3: Riverpod Providers (
extIdentityVoteProvider & rchetypeNodeStatesProvider)

**Files:**
- Create: lib/features/world_map/presentation/providers/next_identity_vote_provider.dart
- Create: lib/features/world_map/presentation/providers/archetype_node_states_provider.dart
- Create: 	est/features/world_map/presentation/providers/next_identity_vote_provider_test.dart

- [ ] **Step 1: Write the failing tests**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Implement Riverpod providers with codegen**
- [ ] **Step 4: Run build_runner and verify tests pass**
- [ ] **Step 5: Commit**

---

### Task 4: UI Components (WorldStokingDock & WorldTypeNode Badges)

**Files:**
- Create: lib/features/world_map/presentation/widgets/world_stoking_dock.dart
- Modify: lib/features/world_map/presentation/widgets/world_type_node.dart
- Create: 	est/features/world_map/presentation/widgets/world_stoking_dock_test.dart
- Modify: 	est/features/world_map/presentation/widgets/world_type_node_test.dart

- [ ] **Step 1: Write failing widget tests for WorldStokingDock and WorldTypeNode**
- [ ] **Step 2: Run tests to verify failure**
- [ ] **Step 3: Implement WorldStokingDock with glassmorphic styling, attribute colors, and 1-tap callback**
- [ ] **Step 4: Update WorldTypeNode with status badges (complete, pending, decaying)**
- [ ] **Step 5: Run widget tests to verify pass**
- [ ] **Step 6: Commit**

---

### Task 5: Screen Integration & Particle Burst Animation (WorldMapScreen)

**Files:**
- Create: lib/features/world_map/presentation/widgets/world_spark_burst.dart
- Modify: lib/features/world_map/presentation/screens/world_map_screen.dart
- Modify: 	est/features/world_map/presentation/screens/world_map_screen_test.dart

- [ ] **Step 1: Write integration tests verifying WorldStokingDock and WorldTypeNode badges render on WorldMapScreen**
- [ ] **Step 2: Run tests to verify failure**
- [ ] **Step 3: Implement WorldSparkBurst and connect WorldStokingDock on WorldMapScreen**
- [ ] **Step 4: Run screen tests and dart analyze to verify clean build**
- [ ] **Step 5: Commit**

---

## Verification Plan

### Automated Tests
`ash
flutter test test/features/world_map/domain/ --timeout 60s
flutter test test/features/world_map/presentation/ --timeout 60s
dart analyze lib/features/world_map/ test/features/world_map/
`
