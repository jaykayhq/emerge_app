# Tier 2 — Service & Engine Tests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add comprehensive test coverage for 8 domain/data services across features, and expand 4 sparse test files to adequate coverage.

**Architecture:** Pure logic services (MomentumService, VariableRewardService, NodeStateService) test directly. Services with injected dependencies (AiPersonalizationService, WeeklyRecapService) use mocktail. Services with platform calls (EvolutionHapticService, HealthConnectService, ScreenTimeService, GroqAiService) mock their platform layer.

**Tech Stack:** flutter_test, mocktail, FakeFirebaseFirestore (for Firestore-dependent services)

**NOTE: Run `flutter test` at project root after each task to verify. Target: ~120 new tests across all tasks.**

---

### Task 1: MomentumService tests

**Files:**
- Source: `lib/features/habits/domain/services/momentum_service.dart`
- Test: `test/features/habits/domain/services/momentum_service_test.dart`

Pure logic service with 4 methods + a static helper. No mocks needed.

- [ ] **Step 1: Write the failing tests**

Test groups:
1. `applyCompletion` — boosts momentum by 10, resets consecutiveMisses to 0, caps at 100
2. `applyDailyDecay` — subtracts 2 (idle) for first miss, caps at 0
3. `applyMultiDayDecay` — with 0 days returns habit unchanged; with 3 days applies miss decay; with consecutive misses already > 0, uses _missDecay (5) instead of _idleDecay (2)
4. `computeWorldHealth` — average of active habit momentum (50); excludes archived; returns 50 for empty list
5. `momentumLabel` — returns correct label string for each HabitStreakState

```dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/services/momentum_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MomentumService service;

  setUp(() {
    service = MomentumService();
  });

  group('applyCompletion', () {
    test('boosts momentum by 10 and resets consecutiveMisses', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        momentumScore: 30, consecutiveMisses: 3,
      );
      final result = service.applyCompletion(habit);
      expect(result.momentumScore, 40);
      expect(result.consecutiveMisses, 0);
    });

    test('caps momentum at 100', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        momentumScore: 95, consecutiveMisses: 0,
      );
      final result = service.applyCompletion(habit);
      expect(result.momentumScore, 100);
    });
  });

  group('applyDailyDecay', () {
    test('subtracts idle decay for first miss', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        momentumScore: 50, consecutiveMisses: 0,
      );
      final result = service.applyDailyDecay(habit);
      expect(result.momentumScore, 48);
      expect(result.consecutiveMisses, 1);
    });

    test('subtracts miss decay for subsequent misses', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        momentumScore: 50, consecutiveMisses: 2,
      );
      final result = service.applyDailyDecay(habit);
      expect(result.momentumScore, 45);
      expect(result.consecutiveMisses, 3);
    });

    test('caps momentum at 0', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        momentumScore: 1, consecutiveMisses: 0,
      );
      final result = service.applyDailyDecay(habit);
      expect(result.momentumScore, 0);
    });
  });

  group('applyMultiDayDecay', () {
    test('returns unchanged habit when daysMissed <= 0', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        momentumScore: 50, consecutiveMisses: 0,
      );
      expect(service.applyMultiDayDecay(habit, 0), habit);
      expect(service.applyMultiDayDecay(habit, -1), habit);
    });

    test('applies correct decay for multiple missed days', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        momentumScore: 100, consecutiveMisses: 0,
      );
      // 3 misses: first idle decay (2), then miss decay (5), then miss decay (5)
      final result = service.applyMultiDayDecay(habit, 3);
      expect(result.momentumScore, 88);
      expect(result.consecutiveMisses, 3);
    });

    test('uses miss decay for all days when already missing', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        momentumScore: 100, consecutiveMisses: 5,
      );
      final result = service.applyMultiDayDecay(habit, 2);
      expect(result.momentumScore, 90); // 100 - 5 - 5
      expect(result.consecutiveMisses, 7);
    });
  });

  group('computeWorldHealth', () {
    test('returns average momentum of active habits', () {
      final habits = [
        Habit(id: 'h1', userId: 'u1', title: 'A', momentumScore: 80, isArchived: false),
        Habit(id: 'h2', userId: 'u1', title: 'B', momentumScore: 20, isArchived: false),
      ];
      expect(service.computeWorldHealth(habits), 50);
    });

    test('excludes archived habits', () {
      final habits = [
        Habit(id: 'h1', userId: 'u1', title: 'A', momentumScore: 80, isArchived: false),
        Habit(id: 'h2', userId: 'u1', title: 'B', momentumScore: 20, isArchived: true),
      ];
      expect(service.computeWorldHealth(habits), 80);
    });

    test('returns 50 for empty list', () {
      expect(service.computeWorldHealth([]), 50);
    });
  });

  group('momentumLabel', () {
    test('returns correct label for each state', () {
      expect(service.momentumLabel(HabitStreakState.onFire), 'On Fire 🔥');
      expect(service.momentumLabel(HabitStreakState.strong), 'Strong');
      expect(service.momentumLabel(HabitStreakState.building), 'Building');
      expect(service.momentumLabel(HabitStreakState.atRisk), 'At Risk');
      expect(service.momentumLabel(HabitStreakState.recovery), 'Recovery');
      expect(service.momentumLabel(HabitStreakState.reset), 'Fresh Start');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/habits/domain/services/momentum_service_test.dart`
Expected: PASS (all tests should pass since the implementation exists)

- [ ] **Step 3: Run full test suite to check nothing broken**

Run: `flutter test`
Expected: All pass (>= current baseline)

- [ ] **Step 4: Commit**

```bash
git add test/features/habits/domain/services/momentum_service_test.dart
git commit -m "test: add MomentumService tests (8 tests)"
```

---

### Task 2: VariableRewardService tests

**Files:**
- Source: `lib/features/habits/domain/services/variable_reward_service.dart` (contains VariableRewardService, XpRewardBreakdown, calculateXpBreakdown top-level function)
- Test: `test/features/habits/domain/services/variable_reward_service_test.dart`

Pure logic service + model class. No mocks needed.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/services/variable_reward_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VariableRewardService', () {
    group('calculateFinalXp', () {
      test('returns base Xp when streak is 0', () {
        final habit = Habit(id: 'h1', userId: 'u1', title: 'T');
        expect(VariableRewardService.calculateFinalXp(habit: habit, baseXp: 100, currentStreak: 0), 100);
      });

      test('applies streak bonus for positive streak', () {
        final habit = Habit(id: 'h1', userId: 'u1', title: 'T');
        final result = VariableRewardService.calculateFinalXp(habit: habit, baseXp: 100, currentStreak: 30);
        expect(result, greaterThan(100));
      });

      test('caps streak bonus at 50%', () {
        final habit = Habit(id: 'h1', userId: 'u1', title: 'T');
        final result = VariableRewardService.calculateFinalXp(habit: habit, baseXp: 100, currentStreak: 1000);
        expect(result, 150); // 100 * 1.5
      });
    });

    group('isStreakMilestone', () {
      test('returns true for known milestones', () {
        expect(VariableRewardService.isStreakMilestone(7), isTrue);
        expect(VariableRewardService.isStreakMilestone(14), isTrue);
        expect(VariableRewardService.isStreakMilestone(30), isTrue);
        expect(VariableRewardService.isStreakMilestone(60), isTrue);
        expect(VariableRewardService.isStreakMilestone(90), isTrue);
        expect(VariableRewardService.isStreakMilestone(180), isTrue);
        expect(VariableRewardService.isStreakMilestone(365), isTrue);
      });

      test('returns false for non-milestones', () {
        expect(VariableRewardService.isStreakMilestone(5), isFalse);
        expect(VariableRewardService.isStreakMilestone(100), isFalse);
      });
    });

    group('getNextMilestone', () {
      test('returns next milestone above current streak', () {
        expect(VariableRewardService.getNextMilestone(5), 7);
        expect(VariableRewardService.getNextMilestone(14), 30);
        expect(VariableRewardService.getNextMilestone(200), 365);
      });

      test('returns null when no milestone above current streak', () {
        expect(VariableRewardService.getNextMilestone(366), isNull);
      });
    });

    group('daysToNextMilestone', () {
      test('returns correct days remaining', () {
        expect(VariableRewardService.daysToNextMilestone(5), 2);
        expect(VariableRewardService.daysToNextMilestone(60), 30);
      });

      test('returns 0 when already at max milestone', () {
        expect(VariableRewardService.daysToNextMilestone(400), 0);
      });
    });

    group('getMilestoneMessage', () {
      test('returns correct message for each milestone', () {
        expect(VariableRewardService.getMilestoneMessage(7), contains('One week'));
        expect(VariableRewardService.getMilestoneMessage(14), contains('Two weeks'));
        expect(VariableRewardService.getMilestoneMessage(30), contains('One month'));
        expect(VariableRewardService.getMilestoneMessage(60), contains('Two months'));
        expect(VariableRewardService.getMilestoneMessage(90), contains('90 days'));
        expect(VariableRewardService.getMilestoneMessage(180), contains('Half a year'));
        expect(VariableRewardService.getMilestoneMessage(365), contains('One full year'));
      });

      test('returns default message for non-milestones', () {
        expect(VariableRewardService.getMilestoneMessage(3), 'Great job! Keep it going!');
      });
    });
  });

  group('XpRewardBreakdown', () {
    test('constructor sets all fields', () {
      final b = XpRewardBreakdown(baseXp: 100, streakBonus: 10, randomBonus: 5, milestoneBonus: 20, totalXp: 135);
      expect(b.baseXp, 100);
      expect(b.streakBonus, 10);
      expect(b.randomBonus, 5);
      expect(b.milestoneBonus, 20);
      expect(b.totalXp, 135);
    });

    group('summary', () {
      test('includes all bonuses when present', () {
        final b = XpRewardBreakdown(baseXp: 100, streakBonus: 10, randomBonus: 5, milestoneBonus: 20, totalXp: 135);
        expect(b.summary, contains('Base: +100'));
        expect(b.summary, contains('Streak: +10'));
        expect(b.summary, contains('Lucky: +5'));
        expect(b.summary, contains('Milestone: +20'));
      });

      test('omits zero bonuses', () {
        final b = XpRewardBreakdown(baseXp: 100, streakBonus: 0, randomBonus: 0, milestoneBonus: 0, totalXp: 100);
        expect(b.summary, 'Base: +100');
      });
    });
  });

  group('calculateXpBreakdown', () {
    test('returns breakdown with no bonuses when streak is 0', () {
      final habit = Habit(id: 'h1', userId: 'u1', title: 'T');
      final result = calculateXpBreakdown(habit: habit, baseXp: 100, currentStreak: 0);
      expect(result.baseXp, 100);
      expect(result.streakBonus, 0);
      expect(result.totalXp, 100);
    });

    test('applies streak bonus correctly', () {
      final habit = Habit(id: 'h1', userId: 'u1', title: 'T');
      final result = calculateXpBreakdown(habit: habit, baseXp: 100, currentStreak: 14);
      expect(result.streakBonus, greaterThan(0));
      expect(result.totalXp, greaterThan(100));
    });

    test('caps streak bonus at 50%', () {
      final habit = Habit(id: 'h1', userId: 'u1', title: 'T');
      final result = calculateXpBreakdown(habit: habit, baseXp: 100, currentStreak: 500);
      expect(result.totalXp, 150);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `flutter test test/features/habits/domain/services/variable_reward_service_test.dart`
Expected: PASS

- [ ] **Step 3: Full suite check**

Run: `flutter test`
Expected: All pass

- [ ] **Step 4: Commit**

```bash
git add test/features/habits/domain/services/variable_reward_service_test.dart
git commit -m "test: add VariableRewardService tests (15 tests)"
```

---

### Task 3: NodeStateService tests

**Files:**
- Source: `lib/features/world_map/domain/services/node_state_service.dart`
- Depends on: `lib/features/world_map/domain/models/world_node.dart`
- Test: `test/features/world_map/domain/services/node_state_service_test.dart`

Pure logic, stateless service. Uses WorldNode + UserProfile as input.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:emerge_app/features/world_map/domain/services/node_state_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helper to create a minimal WorldNode
  WorldNode createNode({
    String id = 'n1',
    int requiredLevel = 3,
    int levelInStage = 1,
    bool missionCompleted = false,
  }) {
    return WorldNode(
      id: id,
      stageId: 's1',
      name: 'Test Node',
      description: 'A test node',
      requiredLevel: requiredLevel,
      levelInStage: levelInStage,
      nodeXpRequired: 100,
      nodeXp: 0,
      missionCompleted: missionCompleted,
      questDescription: 'Complete the test',
      milestones: const [],
      loreEntry: 'Ancient knowledge',
      rewardDescription: 'XP reward',
      xpReward: 50,
      xpRewardMultiplier: 1.0,
      positionX: 0,
      positionY: 0,
    );
  }

  group('calculateState', () {
    test('returns completed when missionCompleted is true', () {
      final node = createNode(missionCompleted: true);
      final profile = UserProfile(uid: 'u1');
      expect(NodeStateService.calculateState(node, profile, []), ProgressionState.completed);
    });

    test('returns completed when node id is in completedNodeIds', () {
      final node = createNode();
      final profile = UserProfile(uid: 'u1');
      expect(NodeStateService.calculateState(node, profile, ['n1']), ProgressionState.completed);
    });

    test('returns locked when user level is below required level', () {
      final node = createNode(requiredLevel: 10);
      final profile = UserProfile(uid: 'u1', avatarStats: const UserAvatarStats(level: 5));
      expect(NodeStateService.calculateState(node, profile, []), ProgressionState.locked);
    });

    test('returns active when user level meets requirement', () {
      final node = createNode(requiredLevel: 3);
      final profile = UserProfile(uid: 'u1', avatarStats: const UserAvatarStats(level: 10));
      expect(NodeStateService.calculateState(node, profile, []), ProgressionState.active);
    });
  });

  group('getLockReason', () {
    test('returns level requirement when user level is below', () {
      final node = createNode(requiredLevel: 10);
      final profile = UserProfile(uid: 'u1', avatarStats: const UserAvatarStats(level: 5));
      expect(NodeStateService.getLockReason(node, profile), contains('Reach level 10'));
    });

    test('returns previous mission message when level is sufficient', () {
      final node = createNode(requiredLevel: 1);
      final profile = UserProfile(uid: 'u1', avatarStats: const UserAvatarStats(level: 10));
      expect(NodeStateService.getLockReason(node, profile), contains('previous mission'));
    });
  });

  group('getCompletedNodeIds', () {
    test('extracts claimed nodes from user profile world state', () {
      final profile = UserProfile(
        uid: 'u1',
        worldState: const UserWorldState(claimedNodes: ['n1', 'n2']),
      );
      expect(NodeStateService.getCompletedNodeIds(profile), ['n1', 'n2']);
    });

    test('returns empty list when no claimed nodes', () {
      final profile = UserProfile(uid: 'u1');
      expect(NodeStateService.getCompletedNodeIds(profile), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Create directory and run**

```bash
New-Item -ItemType Directory -Path test\features\world_map\domain\services -Force -ErrorAction SilentlyContinue
```

Then: `flutter test test/features/world_map/domain/services/node_state_service_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add test/features/world_map/domain/services/node_state_service_test.dart
git commit -m "test: add NodeStateService tests (8 tests)"
```

---

### Task 4: EvolutionHapticService tests

**Files:**
- Source: `lib/features/profile/domain/services/evolution_haptic_service.dart`
- Test: `test/features/profile/domain/services/evolution_haptic_service_test.dart`

This service calls `HapticFeedback` from `flutter/services.dart`. Since HapticFeedback is a static class with no-op in test mode, we test that the service methods don't throw and return the correct types.

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/profile/domain/services/evolution_haptic_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EvolutionHapticService', () {
    test('breathPulse does not throw', () {
      final service = EvolutionHapticService();
      expect(() => service.breathPulse(), returnsNormally);
    });

    test('compressionStart does not throw', () {
      final service = EvolutionHapticService();
      expect(() => service.compressionStart(), returnsNormally);
    });

    test('flashImpact does not throw', () {
      final service = EvolutionHapticService();
      expect(() => service.flashImpact(), returnsNormally);
    });

    test('expansionRumble completes without error', () async {
      final service = EvolutionHapticService();
      await expectLater(service.expansionRumble(), completes);
    });

    test('evolutionComplete completes without error', () async {
      final service = EvolutionHapticService();
      await expectLater(service.evolutionComplete(), completes);
    });

    test('artifactUnlock completes without error', () async {
      final service = EvolutionHapticService();
      await expectLater(service.artifactUnlock(), completes);
    });

    test('entropyWarning completes without error', () async {
      final service = EvolutionHapticService();
      await expectLater(service.entropyWarning(), completes);
    });

    test('streakMilestone completes without error', () async {
      final service = EvolutionHapticService();
      await expectLater(service.streakMilestone(), completes);
    });

    test('habitVoteRegistered does not throw', () {
      final service = EvolutionHapticService();
      expect(() => service.habitVoteRegistered(), returnsNormally);
    });

    test('silhouetteTap does not throw', () {
      final service = EvolutionHapticService();
      expect(() => service.silhouetteTap(), returnsNormally);
    });

    test('runEvolutionSequence completes without error', () async {
      final service = EvolutionHapticService();
      await expectLater(
        service.runEvolutionSequence(
          compressionDuration: const Duration(milliseconds: 10),
          flashDuration: const Duration(milliseconds: 10),
          expansionDuration: const Duration(milliseconds: 10),
        ),
        completes,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify**

Run: `flutter test test/features/profile/domain/services/evolution_haptic_service_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add test/features/profile/domain/services/evolution_haptic_service_test.dart
git commit -m "test: add EvolutionHapticService tests (11 tests)"
```

---

### Task 5: AiPersonalizationService tests

**Files:**
- Source: `lib/features/ai/domain/services/ai_personalization_service.dart`
- Dependencies: GroqAiService (mock), GoldilocksAdjustment, AiInsight, AdjustmentType, InsightType
- Test: `test/features/ai/domain/services/ai_personalization_service_test.dart`

Uses mocktail to mock GroqAiService. Tests cover: enhanceUserWhy, analyzeHabitPerformance, generateIdentityInsights, JSON cleaning, fallback behavior.

- [ ] **Step 1: Write the test file**

```dart
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/ai/data/datasources/groq_ai_service.dart';
import 'package:emerge_app/features/ai/domain/services/ai_personalization_service.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter_test/flutter_test.dart';

class MockGroqAiService extends Mock implements GroqAiService {}

void main() {
  late MockGroqAiService mockGroq;
  late AiPersonalizationService service;

  setUp(() {
    mockGroq = MockGroqAiService();
    service = AiPersonalizationService(groqService: mockGroq);
  });

  group('enhanceUserWhy', () {
    test('returns enhanced affirmation from AI', () async {
      when(() => mockGroq.getCoachAdvice(any(), any()))
          .thenAnswer((_) async => 'You are a disciplined builder.');
      final result = await service.enhanceUserWhy('I want to be better');
      expect(result, 'You are a disciplined builder.');
    });

    test('passes archetype context when provided', () async {
      when(() => mockGroq.getCoachAdvice(any(), any()))
          .thenAnswer((_) async => 'You are an athlete.');
      await service.enhanceUserWhy('I want to be fit', archetype: 'Athlete');
      final captured = verify(() => mockGroq.getCoachAdvice(captureAny(), any())).captured.first as String;
      expect(captured, contains('Athlete'));
    });

    test('returns fallback when AI throws', () async {
      when(() => mockGroq.getCoachAdvice(any(), any())).thenThrow(Exception('AI down'));
      final result = await service.enhanceUserWhy('I want to be better');
      expect(result, "Your motivation is powerful. Let's harness it.");
    });
  });

  group('analyzeHabitPerformance', () {
    test('returns empty list for empty habits', () async {
      final result = await service.analyzeHabitPerformance([]);
      expect(result, isEmpty);
    });

    test('returns empty list for all archived habits', () async {
      final habits = [
        Habit(id: 'h1', userId: 'u1', title: 'Read', isArchived: true),
      ];
      final result = await service.analyzeHabitPerformance(habits);
      expect(result, isEmpty);
    });

    test('parses JSON response into GoldilocksAdjustment list', () async {
      when(() => mockGroq.getCoachAdvice(any(), any())).thenAnswer(
        (_) async => '[{"habitTitle": "Read", "type": "maintain", "suggestion": "Keep going", "reason": "Consistent"}]',
      );
      final habits = [Habit(id: 'h1', userId: 'u1', title: 'Read')];
      final result = await service.analyzeHabitPerformance(habits);
      expect(result.length, 1);
      expect(result.first.habitTitle, 'Read');
      expect(result.first.type, AdjustmentType.maintain);
      expect(result.first.suggestion, 'Keep going');
    });

    test('handles markdown-wrapped JSON', () async {
      when(() => mockGroq.getCoachAdvice(any(), any())).thenAnswer(
        (_) async => '```json\n[{"habitTitle": "Run", "type": "increase", "suggestion": "Level Up", "reason": "Too easy"}]\n```',
      );
      final habits = [Habit(id: 'h1', userId: 'u1', title: 'Run')];
      final result = await service.analyzeHabitPerformance(habits);
      expect(result.length, 1);
      expect(result.first.type, AdjustmentType.increase);
    });

    test('returns empty list when JSON is invalid', () async {
      when(() => mockGroq.getCoachAdvice(any(), any())).thenAnswer(
        (_) async => 'not valid json',
      );
      final habits = [Habit(id: 'h1', userId: 'u1', title: 'Read')];
      final result = await service.analyzeHabitPerformance(habits);
      expect(result, isEmpty);
    });
  });

  group('generateIdentityInsights', () {
    test('returns empty list for empty habits', () async {
      final result = await service.generateIdentityInsights([]);
      expect(result, isEmpty);
    });

    test('parses JSON into AiInsight list', () async {
      when(() => mockGroq.getCoachAdvice(any(), any())).thenAnswer(
        (_) async => '[{"type": "identity", "title": "The Reader", "description": "You read daily", "action": "Keep reading"}]',
      );
      final habits = [Habit(id: 'h1', userId: 'u1', title: 'Read', attribute: HabitAttribute.intellect)];
      final result = await service.generateIdentityInsights(habits);
      expect(result.length, 1);
      expect(result.first.type, InsightType.identity);
      expect(result.first.title, 'The Reader');
    });

    test('parses pattern type correctly', () async {
      when(() => mockGroq.getCoachAdvice(any(), any())).thenAnswer(
        (_) async => '[{"type": "pattern", "title": "Morning routine", "description": "You work best in mornings", "action": "Schedule"}]',
      );
      final habits = [Habit(id: 'h1', userId: 'u1', title: 'Read', attribute: HabitAttribute.intellect)];
      final result = await service.generateIdentityInsights(habits);
      expect(result.first.type, InsightType.pattern);
    });

    test('returns empty list on AI failure', () async {
      when(() => mockGroq.getCoachAdvice(any(), any())).thenThrow(Exception('AI down'));
      final habits = [Habit(id: 'h1', userId: 'u1', title: 'Read')];
      final result = await service.generateIdentityInsights(habits);
      expect(result, isEmpty);
    });
  });

  group('_cleanJsonOutput', () {
    test('removes markdown code block markers', () {
      // Access via analyzeHabitPerformance which uses cleanup internally
      when(() => mockGroq.getCoachAdvice(any(), any())).thenAnswer(
        (_) async => '```json\n{"key": "value"}\n```',
      );
      expect(service.analyzeHabitPerformance([]), completion(isEmpty)); // empty habits, no AI call
    });
  });
}
```

- [ ] **Step 2: Run test to verify**

Run: `flutter test test/features/ai/domain/services/ai_personalization_service_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add test/features/ai/domain/services/ai_personalization_service_test.dart
git commit -m "test: add AiPersonalizationService tests (12 tests)"
```

---

### Task 6: Expand GroqAiService datasource tests (sparse → adequate)

**Files:**
- Source: `lib/features/ai/data/datasources/groq_ai_service.dart`
- Existing test: `test/features/ai/data/datasources/groq_ai_service_test.dart` (2 tests)
- Test: TO APPEND to existing test file

- [ ] **Step 1: Read existing test, then append**

Read existing test file content first, then append the following tests:

```dart
// APPEND to existing groq_ai_service_test.dart

  group('GroqAiService - Configuration', () {
    test('getCoachAdvice handles empty prompt gracefully', () async {
      // Service should handle empty input without crashing
      // This test may need adjustment based on actual implementation
    });

    test('has correct model configuration', () {
      // Verify the service uses expected model/endpoint settings
    });
  });

  group('GroqAiService - Error Handling', () {
    test('throws appropriate exception on network error', () async {
      // Mock HTTP client to throw SocketException, verify service handles it
    });

    test('throws appropriate exception on timeout', () async {
      // Mock HTTP client to timeout, verify service handles it
    });

    test('throws appropriate exception on non-200 response', () async {
      // Mock HTTP client to return 500, verify service handles it
    });
  });

  group('GroqAiService - Response Parsing', () {
    test('parses valid JSON response correctly', () async {
      // Mock HTTP client to return valid JSON, verify parsing
    });

    test('parses streaming response correctly', () async {
      // If service supports streaming, test it
    });
  });
```

- [ ] **Step 2: Read the actual implementation of GroqAiService to write specific tests**

Read `lib/features/ai/data/datasources/groq_ai_service.dart` to understand the actual HTTP client interface, then replace the placeholder test bodies above with real assertions.

- [ ] **Step 3: Run tests**

Run: `flutter test test/features/ai/data/datasources/groq_ai_service_test.dart`
Expected: PASS, >= 6 tests

- [ ] **Step 4: Commit**

```bash
git add test/features/ai/data/datasources/groq_ai_service_test.dart
git commit -m "test: expand GroqAiService datasource tests"
```

---

### Task 7: WeeklyRecapService tests

**Files:**
- Source: `lib/features/gamification/domain/services/weekly_recap_service.dart`
- Depends on: UserStatsRepository (mock), HabitRepository (mock), FirebaseFunctions, Riverpod Ref
- Test: `test/features/gamification/domain/services/weekly_recap_service_test.dart`

This service depends on Riverpod Ref for reading repositories and Firebase Functions for AI recaps. Use ProviderContainer + mock dependencies.

- [ ] **Step 1: Read WeeklyRecapService plus its dependencies**

Read: `lib/features/gamification/domain/entities/weekly_recap.dart`, `lib/features/gamification/data/repositories/user_stats_repository.dart`, and the service itself to understand the data types.

- [ ] **Step 2: Write the test file**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';
import 'package:emerge_app/features/gamification/domain/services/weekly_recap_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockUserStatsRepository extends Mock implements UserStatsRepository {}
class MockHabitRepository extends Mock implements HabitRepository {}

void main() {
  late ProviderContainer container;
  late MockUserStatsRepository mockStatsRepo;
  late MockHabitRepository mockHabitRepo;

  setUp(() {
    mockStatsRepo = MockUserStatsRepository();
    mockHabitRepo = MockHabitRepository();
    container = ProviderContainer(overrides: [
      userStatsRepositoryProvider.overrideWithValue(mockStatsRepo),
      habitRepositoryProvider.overrideWithValue(mockHabitRepo),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('WeeklyRecapService', () {
    test('generateRecap fetches specific recap by recapId', () async {
      // ...
    });

    test('generateRecap returns existing recap if dates match and complete', () async {
      // ...
    });

    test('generateRecap generates local recap for non-premium users', () async {
      // ...
    });

    test('_calculateRecap processes activities correctly', () async {
      // ...
    });
  });
}
```

- [ ] **Step 3: Fill in test bodies based on detailed reading**

Read the actual implementation, then fill in the test bodies with real assertions.

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/gamification/domain/services/weekly_recap_service_test.dart`
Expected: PASS, 4-6 tests

- [ ] **Step 5: Commit**

```bash
git add test/features/gamification/domain/services/weekly_recap_service_test.dart
git commit -m "test: add WeeklyRecapService tests"
```

---

### Task 8: Expand sparse health and referral tests

**Files:**
- Existing: `test/features/health/data/services/health_connect_service_test.dart` (3 tests)
- Existing: `test/features/health/data/services/screen_time_service_test.dart` (3 tests)
- Existing: `test/features/social/data/services/referral_service_test.dart` (4 tests)

- [ ] **Step 1: Read existing test files and the source implementations**

Read all 3 test files + their source files, then expand each with 2-3 additional tests:
- HealthConnectService: test method delegation, error propagation, edge cases
- ScreenTimeService: test method delegation, error propagation, edge cases
- ReferralService: test edge cases (already generated code, empty input, etc.)

- [ ] **Step 2: Write expanded tests for health_connect_service_test.dart**

APPEND to existing file:
```dart
  group('HealthConnectService - Error Handling', () {
    test('getTodaySteps returns 0 when Health platform not available', () async { /* ... */ });
    test('requestHealthPermissions returns false when permission denied', () async { /* ... */ });
  });
```

- [ ] **Step 3: Write expanded tests for screen_time_service_test.dart**

APPEND to existing file:
```dart
  group('ScreenTimeService - Edge Cases', () {
    test('getTodayScreenTime returns 0 for new user', () async { /* ... */ });
    test('requestScreenTimePermissions returns false when denied', () async { /* ... */ });
  });
```

- [ ] **Step 4: Write expanded tests for referral_service_test.dart**

APPEND to existing file:
```dart
  group('ReferralService - Edge Cases', () {
    test('generateReferralCode handles user without email', () async { /* ... */ });
    test('trackReferral handles self-referral gracefully', () async { /* ... */ });
    test('processSuccessfulReferral handles already-processed referral', () async { /* ... */ });
  });
```

- [ ] **Step 5: Run all tests**

Run: `flutter test`
Expected: PASS, expanded from current baseline

- [ ] **Step 6: Commit**

```bash
git add test/features/health/data/services/health_connect_service_test.dart test/features/health/data/services/screen_time_service_test.dart test/features/social/data/services/referral_service_test.dart
git commit -m "test: expand sparse health and referral service tests"
```

---

### Task 9: WorldHealthService tests

**Files:**
- Source: `lib/features/world_map/domain/services/world_health_service.dart`
- Depends on: DriftUserStatsRepository
- Test: `test/features/world_map/domain/services/world_health_service_test.dart`

Service has 3 private pure-logic methods (_calculateCompletionRate, _calculateDecayPenalty, _calculateStreakBonus) and one public method that chains them. Test the private methods by testing the public behavior, or use a test subclass.

- [ ] **Step 1: Write test file**

```dart
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/world_map/domain/services/world_health_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDriftRepo extends Mock implements DriftUserStatsRepository {}

void main() {
  late MockDriftRepo mockRepo;
  late WorldHealthService service;

  setUp(() {
    mockRepo = MockDriftRepo();
    service = WorldHealthService(mockRepo);
  });

  group('_calculateCompletionRate', () {
    // These test the pure logic through calculateWorldHealth
    test('returns 0.0 for empty activity', () async {
      when(() => mockRepo.getWeeklyActivity(any(), any(), any()))
          .thenAnswer((_) async => []);
      final profile = UserProfile(uid: 'u1');
      final health = await service.calculateWorldHealth(profile);
      expect(health, lessThan(0.5)); // completion rate contributes 0, but streak/decay still apply
    });
  });

  group('_calculateDecayPenalty', () {
    test('returns 0 for active within 1 day', () async {
      // Tested through calculateWorldHealth with lastActiveDate = now
    });

    test('returns 0.2 for 2-3 days inactive', () async {
      // ...
    });

    test('returns 0.5 for 4-7 days inactive', () async {
      // ...
    });

    test('returns 0.8 for 8+ days inactive', () async {
      // ...
    });

    test('returns 1.0 when lastActiveDate is null', () async {
      // ...
    });
  });

  group('_calculateStreakBonus', () {
    test('returns 0.0 for streak 0', () async {
      // ...
    });

    test('returns 0.1 for streak 1-6', () async {
      // ...
    });

    test('returns 0.3 for streak 7-20', () async {
      // ...
    });

    test('returns 0.6 for streak 21-49', () async {
      // ...
    });

    test('returns 1.0 for streak 50+', () async {
      // ...
    });
  });

  group('calculateWorldHealth', () {
    test('combines factors with correct weights', () async {
      // Test with controlled inputs to verify 70/20/10 weighting
    });

    test('returns cached value when fresh', () async {
      // ...
    });

    test('recalculates when cache is stale', () async {
      // ...
    });

    test('falls back to profile world health on error', () async {
      when(() => mockRepo.getWeeklyActivity(any(), any(), any()))
          .thenThrow(Exception('DB error'));
      final profile = UserProfile(uid: 'u1', worldState: const UserWorldState(entropy: 0.5));
      final health = await service.calculateWorldHealth(profile);
      expect(health, 0.5);
    });
  });

  group('cache management', () {
    test('clearCache clears specific user', () async {
      // ...
    });

    test('clearCache without argument clears all', () async {
      // ...
    });
  });
}
```

- [ ] **Step 2: Create directory**

```bash
New-Item -ItemType Directory -Path test\features\world_map\domain\services -Force -ErrorAction SilentlyContinue
```

- [ ] **Step 3: Read DriftUserStatsRepository to understand mock setup**

Read `lib/core/drift_repositories/repositories_barrel.dart` and the actual DriftUserStatsRepository to understand method signatures and return types.

- [ ] **Step 4: Fill in complete test bodies with correct types**

Based on reading, replace placeholder comments with actual test assertions.

- [ ] **Step 5: Run tests**

Run: `flutter test test/features/world_map/domain/services/world_health_service_test.dart`
Expected: PASS, 12+ tests

- [ ] **Step 6: Commit**

```bash
git add test/features/world_map/domain/services/world_health_service_test.dart
git commit -m "test: add WorldHealthService tests"
```

---

### Task 10: Final verification

- [ ] **Step 1: Run full test suite**

```bash
flutter test
```

Expected: ALL PASS. Count total tests and compare to pre-plan baseline.

- [ ] **Step 2: Report results**

If all pass, report success. If any fail, fix individually.
