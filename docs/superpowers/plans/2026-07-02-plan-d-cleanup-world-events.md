# Habitual Engagement — Plan D: Cleanup, World Events & FeatureCoachMark Removal

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove `FeatureCoachMark` from all 13 remaining screens (replacing it with the Narrator `screenFirstVisit` trigger), add the `WorldEventEngine` for ambient world state changes, delete dead component files (`ai_coach_card.dart`, `reflection_card.dart`, `feature_coach_mark.dart`), and wire the evening reflection trigger into Timeline.

**Architecture:** `WorldEventEngine` is a pure function tested without any framework. Each screen formerly using `FeatureCoachMark` instead calls `NarratorTriggerEngine.shouldTrigger()` on first route visit and calls `showNarratorSheet()` if `screenFirstVisit` is returned. The `feature_coach_mark.dart` file is deleted after all usages are removed.

**Tech Stack:** Flutter, Dart, Riverpod 3, Firestore, fpdart `Either`

**Prerequisite:** Plans A and B must be complete. `NarratorTriggerEngine`, `NarratorSheet`, `NarratorRepository`, and the Riverpod providers from Plan B must exist.

---

## Context You Must Read First

- `lib/core/presentation/widgets/feature_coach_mark.dart` — read the full file so you understand the pattern you are removing from each screen.
- `lib/features/narrator/domain/services/narrator_trigger_engine.dart` — the engine you will be calling in its place.
- `lib/features/narrator/presentation/widgets/narrator_sheet.dart` — `showNarratorSheet()` is the function you call after the trigger fires.
- Each of the 13 screens listed in the File Map below — open each one to find the `FeatureCoachMark(...)` block before deleting it.

---

## Narrator Screen Templates Reference

Use these shell texts verbatim when adding the Narrator trigger to each screen. They follow the structure: *who you are + what this place is + one orienting question*.

| Screen | NarratorAppearance shell text | buttonA | buttonB |
|--------|-------------------------------|---------|---------|
| `ai_reflections_screen` | `"This is your memory, ${firstName}.\n\nEvery session your Narrator watches gets stored here — patterns, reflections, moments you answered honestly.\n\nThe longer you use Emerge, the sharper this becomes."` | `"Show me my patterns"` | `"What does the Narrator watch for"` |
| `leveling_screen` | `"Each level you see here is a threshold.\n\nYou cross it by completing directives — not by waiting.\n\nYour ${archetype} path has its own pacing. Trust the process."` | `"Let's keep moving"` | `"How does XP work"` |
| `advanced_create_habit_dialog` | `"A ${archetype} who wants to build ${habitGoal}.\n\nThe best habits are small enough to be unavoidable.\n\nWhat's the minimum version of this that still counts?"` | `"That works for me"` | `"Help me make it smaller"` |
| `future_self_studio_screen` | `"This is where you decide who you're becoming.\n\nEvery identity tag you set here shapes what your Narrator says to you — and what your world looks like.\n\nBe honest about the person you actually want to be."` | `"I'm ready to define it"` | `"What happens if I change this later"` |
| `all_tribes_screen` | `"Your ${archetype} path is clearer in a group.\n\nPeople who track together outperform solo trackers by 65%.\n\nFind people building the same thing you are."` | `"Find my tribe"` | `"I'll explore first"` |
| `challenge_detail_screen` | `"This challenge is a concentrated test.\n\nEvery mission here earns attribute XP faster than daily habits.\n\nFinish it and your world shifts."` | `"I'm in"` | `"Tell me what's at stake"` |
| `challenges_screen` | `"Quests are time-boxed identity sprints.\n\nThey exist for ${archetype}s who want to move faster.\n\nEach one you complete is a chapter in your story."` | `"Show me what's available"` | `"What do I earn"` |
| `friends_screen` | `"The people in this list are watching the same thing you are — themselves.\n\nYou don't need to compete. Witnessing each other is enough."` | `"Invite someone I know"` | `"Just browse for now"` |
| `leaderboard_screen` | `"This is the scoreboard for ${archetype}s this week.\n\nMomentum is the metric — not perfection.\n\nYou don't have to be first. You have to be consistent."` | `"I understand"` | `"How is the score calculated"` |
| `social_activity_screen` | `"This is what movement looks like in real-time.\n\nEvery card here is someone voting for who they are.\n\nYou're part of this."` | `"Let's go"` | `"Tell me more"` |
| `social_contacts_screen` | `"These are people already on Emerge.\n\nYou can follow their progress — not to judge, to be reminded that this is possible.\n\nFind one person who inspires you."` | `"Find someone"` | `"Maybe later"` |
| `tribe_lobby_screen` (if separate route remains) | `"Your tribe is where accountability becomes culture.\n\nEveryone here has committed to the same mission.\n\nShow up consistently and the tribe amplifies everything."` | `"I'm committed"` | `"What does the tribe do"` |

---

## File Map

| Action | File |
|--------|------|
| MODIFY | `lib/features/ai/presentation/screens/ai_reflections_screen.dart` |
| MODIFY | `lib/features/gamification/presentation/screens/leveling_screen.dart` |
| MODIFY | `lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart` |
| MODIFY | `lib/features/profile/presentation/screens/future_self_studio_screen.dart` |
| MODIFY | `lib/features/social/presentation/screens/all_tribes_screen.dart` |
| MODIFY | `lib/features/social/presentation/screens/challenge_detail_screen.dart` |
| MODIFY | `lib/features/social/presentation/screens/challenges_screen.dart` |
| MODIFY | `lib/features/social/presentation/screens/friends_screen.dart` |
| MODIFY | `lib/features/social/presentation/screens/leaderboard_screen.dart` |
| MODIFY | `lib/features/social/presentation/screens/social_activity_screen.dart` |
| MODIFY | `lib/features/social/presentation/screens/social_contacts_screen.dart` |
| MODIFY | `lib/features/social/presentation/screens/tribe_lobby_screen.dart` (if still present) |
| DELETE | `lib/core/presentation/widgets/feature_coach_mark.dart` |
| DELETE | `lib/features/timeline/presentation/widgets/ai_coach_card.dart` |
| DELETE | `lib/features/timeline/presentation/widgets/reflection_card.dart` |
| CREATE | `lib/features/gamification/domain/services/world_event_engine.dart` |
| MODIFY | `lib/features/timeline/presentation/screens/timeline_screen.dart` (evening reflection trigger) |
| CREATE | `test/features/gamification/domain/services/world_event_engine_test.dart` |

---

## Task 1: `WorldEventEngine` — pure function

**Files:**
- Create: `lib/features/gamification/domain/services/world_event_engine.dart`
- Create: `lib/features/gamification/domain/models/world_event.dart`
- Test: `test/features/gamification/domain/services/world_event_engine_test.dart`

### Background
The `WorldEventEngine` decides what ambient events happen in the user's world. It is a pure function: given a `UserStats` snapshot and the current time, it returns a list of `WorldEvent`s to fire. No Firebase, no async, fully unit-testable.

Events:
- `travelerVisit` — a traveler NPC appears in the world after 5 consecutive active days
- `weatherShift` — daily ambient weather change (seeded by day of month, deterministic)
- `discoveryBurst` — particle burst on the world map when momentum >= 90
- `biomeTransition` — world biome changes at level milestones (5, 10, 20, 30)

- [ ] **Step 1.1: Create `WorldEvent` and `WorldEventType`**

```dart
// lib/features/gamification/domain/models/world_event.dart

enum WorldEventType {
  travelerVisit,
  weatherShift,
  discoveryBurst,
  biomeTransition,
}

class WorldEvent {
  final WorldEventType type;
  final Map<String, dynamic> payload;
  final DateTime firedAt;

  const WorldEvent({
    required this.type,
    required this.payload,
    required this.firedAt,
  });

  factory WorldEvent.travelerVisit(UserStats stats) => WorldEvent(
        type: WorldEventType.travelerVisit,
        payload: {'streak': stats.consecutiveActiveDays},
        firedAt: DateTime.now(),
      );

  factory WorldEvent.weatherShift(int seed) => WorldEvent(
        type: WorldEventType.weatherShift,
        payload: {'seed': seed, 'weatherType': _weatherFromSeed(seed)},
        firedAt: DateTime.now(),
      );

  factory WorldEvent.discoveryBurst(UserStats stats) => WorldEvent(
        type: WorldEventType.discoveryBurst,
        payload: {'momentumScore': stats.currentMomentumScore},
        firedAt: DateTime.now(),
      );

  factory WorldEvent.biomeTransition(int level) => WorldEvent(
        type: WorldEventType.biomeTransition,
        payload: {'level': level, 'biome': _biomeForLevel(level)},
        firedAt: DateTime.now(),
      );

  static String _weatherFromSeed(int seed) {
    const types = ['clear', 'misty', 'stormy', 'golden', 'aurora'];
    return types[seed % types.length];
  }

  static String _biomeForLevel(int level) {
    if (level >= 30) return 'celestial';
    if (level >= 20) return 'volcanic';
    if (level >= 10) return 'alpine';
    if (level >= 5) return 'forest';
    return 'grassland';
  }
}

/// Snapshot of user stats — no Firebase types, fully serializable.
class UserStats {
  final int consecutiveActiveDays;
  final int currentMomentumScore;
  final int level;

  const UserStats({
    required this.consecutiveActiveDays,
    required this.currentMomentumScore,
    required this.level,
  });
}
```

- [ ] **Step 1.2: Write failing tests**

```dart
// test/features/gamification/domain/services/world_event_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/gamification/domain/models/world_event.dart';
import 'package:emerge_app/features/gamification/domain/services/world_event_engine.dart';

void main() {
  final baseNow = DateTime(2026, 7, 6, 9, 0);
  final baseStats = const UserStats(
    consecutiveActiveDays: 3,
    currentMomentumScore: 50,
    level: 3,
  );

  group('travelerVisit', () {
    test('fires when consecutiveActiveDays >= 5 and not recently fired', () {
      final stats = const UserStats(
        consecutiveActiveDays: 5,
        currentMomentumScore: 50,
        level: 3,
      );
      final events = WorldEventEngine.evaluateAndFire(
        stats: stats,
        now: baseNow,
        recentEvents: [],
      );
      expect(events.any((e) => e.type == WorldEventType.travelerVisit), isTrue);
    });

    test('does NOT fire when consecutiveActiveDays < 5', () {
      final events = WorldEventEngine.evaluateAndFire(
        stats: baseStats,
        now: baseNow,
        recentEvents: [],
      );
      expect(events.any((e) => e.type == WorldEventType.travelerVisit), isFalse);
    });

    test('does NOT fire if travelerVisit was recently fired (within 24h)', () {
      const stats = UserStats(
        consecutiveActiveDays: 6,
        currentMomentumScore: 50,
        level: 3,
      );
      final recentEvent = WorldEvent(
        type: WorldEventType.travelerVisit,
        payload: {},
        firedAt: baseNow.subtract(const Duration(hours: 12)),
      );
      final events = WorldEventEngine.evaluateAndFire(
        stats: stats,
        now: baseNow,
        recentEvents: [recentEvent],
      );
      expect(events.any((e) => e.type == WorldEventType.travelerVisit), isFalse);
    });
  });

  group('weatherShift', () {
    test('fires once per day with deterministic seed', () {
      final events1 = WorldEventEngine.evaluateAndFire(
        stats: baseStats,
        now: DateTime(2026, 7, 6, 9, 0),
        recentEvents: [],
      );
      final events2 = WorldEventEngine.evaluateAndFire(
        stats: baseStats,
        now: DateTime(2026, 7, 6, 14, 0), // same day, different hour
        recentEvents: [],
      );
      // Both calls on the same day should produce the same weather seed
      final seed1 = events1
          .firstWhere((e) => e.type == WorldEventType.weatherShift)
          .payload['seed'];
      final seed2 = events2
          .firstWhere((e) => e.type == WorldEventType.weatherShift)
          .payload['seed'];
      expect(seed1, seed2);
    });
  });

  group('discoveryBurst', () {
    test('fires when momentumScore >= 90 and not recently fired', () {
      const stats = UserStats(
        consecutiveActiveDays: 2,
        currentMomentumScore: 92,
        level: 3,
      );
      final events = WorldEventEngine.evaluateAndFire(
        stats: stats,
        now: baseNow,
        recentEvents: [],
      );
      expect(events.any((e) => e.type == WorldEventType.discoveryBurst), isTrue);
    });

    test('does NOT fire when momentumScore < 90', () {
      final events = WorldEventEngine.evaluateAndFire(
        stats: baseStats,
        now: baseNow,
        recentEvents: [],
      );
      expect(events.any((e) => e.type == WorldEventType.discoveryBurst), isFalse);
    });
  });

  group('biomeTransition', () {
    test('fires at level 5 milestone', () {
      const stats = UserStats(
        consecutiveActiveDays: 1,
        currentMomentumScore: 50,
        level: 5,
      );
      final events = WorldEventEngine.evaluateAndFire(
        stats: stats,
        now: baseNow,
        recentEvents: [],
      );
      expect(events.any((e) => e.type == WorldEventType.biomeTransition), isTrue);
      final event = events.firstWhere((e) => e.type == WorldEventType.biomeTransition);
      expect(event.payload['biome'], 'forest');
    });

    test('does NOT fire at non-milestone level', () {
      const stats = UserStats(
        consecutiveActiveDays: 1,
        currentMomentumScore: 50,
        level: 3,
      );
      final events = WorldEventEngine.evaluateAndFire(
        stats: stats,
        now: baseNow,
        recentEvents: [],
      );
      expect(events.any((e) => e.type == WorldEventType.biomeTransition), isFalse);
    });
  });

  group('multiple events', () {
    test('can fire weatherShift and discoveryBurst together', () {
      const stats = UserStats(
        consecutiveActiveDays: 2,
        currentMomentumScore: 95,
        level: 3,
      );
      final events = WorldEventEngine.evaluateAndFire(
        stats: stats,
        now: baseNow,
        recentEvents: [],
      );
      expect(events.any((e) => e.type == WorldEventType.weatherShift), isTrue);
      expect(events.any((e) => e.type == WorldEventType.discoveryBurst), isTrue);
    });
  });
}
```

- [ ] **Step 1.3: Run — expect compile error**

```bash
flutter test test/features/gamification/domain/services/world_event_engine_test.dart
```

- [ ] **Step 1.4: Implement `WorldEventEngine`**

```dart
// lib/features/gamification/domain/services/world_event_engine.dart
import 'package:emerge_app/features/gamification/domain/models/world_event.dart';

class WorldEventEngine {
  static const _recentWindowHours = 24;
  static const _levelMilestones = {5, 10, 20, 30};

  /// Pure function — no side effects, no async, no framework dependencies.
  /// Returns all events that should fire given the current state.
  static List<WorldEvent> evaluateAndFire({
    required UserStats stats,
    required DateTime now,
    required List<WorldEvent> recentEvents,
  }) {
    final events = <WorldEvent>[];

    // Rule 1: Traveler Visit — 5+ consecutive active days, not fired in last 24h
    if (stats.consecutiveActiveDays >= 5 &&
        !_recentlyFired(recentEvents, WorldEventType.travelerVisit, now)) {
      events.add(WorldEvent.travelerVisit(stats));
    }

    // Rule 2: Weather Shift — once per day, seeded by day*month (deterministic)
    final weatherSeed = now.day * now.month;
    if (!_weatherFiredToday(recentEvents, now)) {
      events.add(WorldEvent.weatherShift(weatherSeed));
    }

    // Rule 3: Discovery Burst — momentum >= 90, not recently fired
    if (stats.currentMomentumScore >= 90 &&
        !_recentlyFired(recentEvents, WorldEventType.discoveryBurst, now)) {
      events.add(WorldEvent.discoveryBurst(stats));
    }

    // Rule 4: Biome Transition — level milestone, not recently fired
    if (_levelMilestones.contains(stats.level) &&
        !_recentlyFired(recentEvents, WorldEventType.biomeTransition, now)) {
      events.add(WorldEvent.biomeTransition(stats.level));
    }

    return events;
  }

  static bool _recentlyFired(
    List<WorldEvent> events,
    WorldEventType type,
    DateTime now,
  ) {
    return events.any((e) =>
        e.type == type &&
        now.difference(e.firedAt).inHours < _recentWindowHours);
  }

  static bool _weatherFiredToday(List<WorldEvent> events, DateTime now) {
    return events.any((e) =>
        e.type == WorldEventType.weatherShift &&
        e.firedAt.year == now.year &&
        e.firedAt.month == now.month &&
        e.firedAt.day == now.day);
  }
}
```

- [ ] **Step 1.5: Run — expect green**

```bash
flutter test test/features/gamification/domain/services/world_event_engine_test.dart
```

- [ ] **Step 1.6: Commit**

```bash
git add lib/features/gamification/domain/models/world_event.dart
git add lib/features/gamification/domain/services/world_event_engine.dart
git add test/features/gamification/domain/services/world_event_engine_test.dart
git commit -m "feat(gamification): add WorldEventEngine pure function (4 event types)"
```

---

## Task 2: Add evening reflection trigger to Timeline

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

### Background
When the user opens Timeline in the evening (>= 18:00) and has completed at least 1 habit today, the `NarratorTriggerEngine` should return `eveningReflection`. This gets passed to `NarratorStateNotifier.show()` which triggers `showNarratorSheet()` with Template 11.

- [ ] **Step 2.1: Add evening reflection check in Timeline `initState`**

In `lib/features/timeline/presentation/screens/timeline_screen.dart`, inside `initState` (after the existing post-frame callback or inside it):

```dart
// Add this import at the top of timeline_screen.dart:
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_sheet.dart';

// Inside initState, after super.initState():
WidgetsBinding.instance.addPostFrameCallback((_) async {
  await _drainNotificationQueue(); // existing from Plan C
  await _checkEveningReflection(); // new
});

// Add this method to the State class:
Future<void> _checkEveningReflection() async {
  final notes = ref.read(recentNarratorNotesProvider).value ?? [];
  final habits = ref.read(todayHabitsProvider).value ?? [];
  final completed = habits.where((h) => h.isCompletedToday).length;
  final total = habits.length;

  final trigger = NarratorTriggerEngine.shouldTrigger(
    stats: NarratorUserStats(
      momentumScore: 50, // use real value from userStatsProvider
      consecutiveActiveDays: 1,
      totalHabitsToday: total,
      completedHabitsToday: completed,
      currentLevel: 1,
      justLeveledUp: false,
      archetype: 'Scholar', // use real value from userProfileProvider
      firstName: 'Friend',  // use real value from userProfileProvider
      onboardingComplete: true,
      weekNumber: DateTime.now().weekday,
    ),
    context: AppOpenContext(
      currentRoute: '/timeline',
      now: DateTime.now(),
      isFirstAppOpen: false,
      daysSinceInstall: 10,
      daysSinceLastOpen: 0,
    ),
    recentNotes: notes,
  );

  if (trigger == NarratorTrigger.eveningReflection && mounted) {
    ref.read(narratorStateNotifierProvider.notifier).show(trigger);
    showNarratorSheet(
      context,
      ref,
      appearance: NarratorAppearance(
        trigger: NarratorTrigger.eveningReflection,
        shellText:
            "$completed of $total today.\n\n"
            "You showed up. That matters.\n\n"
            "One question before you close:\n"
            "What was the hardest moment today?",
        buttonA: "I pushed through it",
        buttonB: "I didn't — and that's okay",
        hasTextField: true,
      ),
      archetypeColor: EmergeColors.teal, // use real archetype color
    );
  }
}
```

> **Important:** Read `userStatsProvider` and `userProfileProvider` (or whatever providers hold the current user's level, archetype, and firstName) and pass the real values instead of the hardcoded placeholders above. Check `lib/features/gamification/presentation/providers/` and `lib/features/profile/presentation/providers/` for the correct provider names.

- [ ] **Step 2.2: Run the app and verify**

```bash
flutter run
```

Set device time to 18:30, complete 1 habit, then re-open the app to Timeline.
- [ ] Narrator sheet appears automatically
- [ ] Text types out: "1 of 3 today. You showed up. That matters..."
- [ ] Optional text field appears below the text
- [ ] Two action buttons appear after text completes

- [ ] **Step 2.3: Commit**

```bash
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "feat(narrator): add eveningReflection trigger in Timeline initState"
```

---

## Task 3: Remove `FeatureCoachMark` from all 13 remaining screens

**Important instruction for each screen below:** The pattern to follow is identical for every screen:

1. **Find** the `FeatureCoachMark(...)` block in the file
2. **Delete** the `FeatureCoachMark(...)` widget from the widget tree
3. **Delete** any state variables tracking its visibility (e.g., `bool _showGuide = false`)
4. **Delete** any `setState(() => _showGuide = true)` or similar calls in `initState`
5. **Delete** the `FeatureCoachMark` import line
6. **Add** the Narrator `screenFirstVisit` trigger (pattern below)
7. **Run** `dart analyze` on the file — fix any remaining errors
8. **Commit** after each screen (not all at once)

### Narrator trigger pattern to add to each screen

Add these imports to every screen being modified:

```dart
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_sheet.dart';
```

Add this method to the State class (or use a mixin — paste it into each screen for now):

```dart
// Call this from initState via addPostFrameCallback
void _checkScreenFirstVisit(String route, NarratorAppearance appearance) async {
  final notes = ref.read(recentNarratorNotesProvider).value ?? [];
  final trigger = NarratorTriggerEngine.shouldTrigger(
    stats: const NarratorUserStats(
      momentumScore: 50,
      consecutiveActiveDays: 1,
      totalHabitsToday: 0,
      completedHabitsToday: 0,
      currentLevel: 1,
      justLeveledUp: false,
      archetype: 'Scholar',
      firstName: 'Friend',
      onboardingComplete: true,
      weekNumber: 1,
    ),
    context: AppOpenContext(
      currentRoute: route,
      now: DateTime.now(),
      isFirstAppOpen: false,
      daysSinceInstall: 10,
      daysSinceLastOpen: 0,
    ),
    recentNotes: notes,
  );
  if (trigger == NarratorTrigger.screenFirstVisit && mounted) {
    showNarratorSheet(
      context,
      ref,
      appearance: appearance,
      archetypeColor: const Color(0xFF4ECDC4),
    );
  }
}
```

Call it in `initState`:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkScreenFirstVisit(
      '/your-route-here',          // exact route string
      const NarratorAppearance(    // see table above for each screen's text
        trigger: NarratorTrigger.screenFirstVisit,
        shellText: '...',
        buttonA: '...',
        buttonB: '...',
      ),
    );
  });
}
```

> **Note on `ref` access:** If the screen is a `ConsumerStatefulWidget`, `ref` is available in the State. If it's a `ConsumerWidget` (stateless), convert it to `ConsumerStatefulWidget` first. Only do this if strictly needed — check first.

---

### Screen 3.1: `ai_reflections_screen.dart`

**File:** `lib/features/ai/presentation/screens/ai_reflections_screen.dart`
**Route:** `/profile/reflections`

- [ ] **Step 3.1.1:** Open file. Find `FeatureCoachMark(` at line ~223. Delete the block.
- [ ] **Step 3.1.2:** Delete the import `feature_coach_mark.dart` and any visibility state variable.
- [ ] **Step 3.1.3:** Add `_checkScreenFirstVisit('/profile/reflections', ...)` call in `initState` with the shell text from the table at the top of this plan.
- [ ] **Step 3.1.4:** `dart analyze lib/features/ai/presentation/screens/ai_reflections_screen.dart`
- [ ] **Step 3.1.5:**
```bash
git add lib/features/ai/presentation/screens/ai_reflections_screen.dart
git commit -m "feat(narrator): replace FeatureCoachMark with screenFirstVisit in ai_reflections_screen"
```

---

### Screen 3.2: `leveling_screen.dart`

**File:** `lib/features/gamification/presentation/screens/leveling_screen.dart`
**Route:** `/gamification/leveling`

- [ ] **Step 3.2.1:** Find `FeatureCoachMark(` at line ~234. Delete block and import.
- [ ] **Step 3.2.2:** Add `_checkScreenFirstVisit('/gamification/leveling', ...)` in `initState`.
- [ ] **Step 3.2.3:** `dart analyze lib/features/gamification/presentation/screens/leveling_screen.dart`
- [ ] **Step 3.2.4:**
```bash
git add lib/features/gamification/presentation/screens/leveling_screen.dart
git commit -m "feat(narrator): replace FeatureCoachMark in leveling_screen"
```

---

### Screen 3.3: `advanced_create_habit_dialog.dart`

**File:** `lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart`
**Route:** `/timeline/create-habit` (or `/habits/advanced-create`)

- [ ] **Step 3.3.1:** Find `FeatureCoachMark(` at line ~358. Delete block and import.
- [ ] **Step 3.3.2:** Add `_checkScreenFirstVisit('/timeline/create-habit', ...)` in `initState`.

> **Note:** This screen also gets `NarratorTrigger.newHabitCreation` (from Plan B, Task 8). The `screenFirstVisit` fires ONCE ever; `newHabitCreation` fires every time a habit is saved. Both can coexist because `screenFirstVisit` only fires on the first visit.

- [ ] **Step 3.3.3:** `dart analyze lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart`
- [ ] **Step 3.3.4:**
```bash
git add lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart
git commit -m "feat(narrator): replace FeatureCoachMark in advanced_create_habit_dialog"
```

---

### Screen 3.4: `future_self_studio_screen.dart`

**File:** `lib/features/profile/presentation/screens/future_self_studio_screen.dart`
**Route:** `/profile/future-self`

- [ ] **Step 3.4.1:** Find `FeatureCoachMark(` at line ~569. Delete block and import.
- [ ] **Step 3.4.2:** Add `_checkScreenFirstVisit('/profile/future-self', ...)` in `initState`.
- [ ] **Step 3.4.3:** `dart analyze lib/features/profile/presentation/screens/future_self_studio_screen.dart`
- [ ] **Step 3.4.4:**
```bash
git add lib/features/profile/presentation/screens/future_self_studio_screen.dart
git commit -m "feat(narrator): replace FeatureCoachMark in future_self_studio_screen"
```

---

### Screen 3.5: `all_tribes_screen.dart`

**File:** `lib/features/social/presentation/screens/all_tribes_screen.dart`
**Route:** `/social/tribes`

- [ ] **Step 3.5.1:** Find `FeatureCoachMark(` at line ~112. Delete block and import.
- [ ] **Step 3.5.2:** Add `_checkScreenFirstVisit('/social/tribes', ...)` in `initState`.
- [ ] **Step 3.5.3:** `dart analyze lib/features/social/presentation/screens/all_tribes_screen.dart`
- [ ] **Step 3.5.4:**
```bash
git add lib/features/social/presentation/screens/all_tribes_screen.dart
git commit -m "feat(narrator): replace FeatureCoachMark in all_tribes_screen"
```

---

### Screen 3.6: `challenge_detail_screen.dart`

**File:** `lib/features/social/presentation/screens/challenge_detail_screen.dart`
**Route:** `/social/challenges/:id`

- [ ] **Step 3.6.1:** Find `FeatureCoachMark(` at line ~546. Delete block and import.
- [ ] **Step 3.6.2:** Add `_checkScreenFirstVisit('/social/challenges/detail', ...)` in `initState`.
- [ ] **Step 3.6.3:** `dart analyze lib/features/social/presentation/screens/challenge_detail_screen.dart`
- [ ] **Step 3.6.4:**
```bash
git add lib/features/social/presentation/screens/challenge_detail_screen.dart
git commit -m "feat(narrator): replace FeatureCoachMark in challenge_detail_screen"
```

---

### Screen 3.7: `challenges_screen.dart`

**File:** `lib/features/social/presentation/screens/challenges_screen.dart`
**Route:** `/social/challenges`

- [ ] **Step 3.7.1:** Find `FeatureCoachMark(` at line ~95. Delete block and import.
- [ ] **Step 3.7.2:** Add `_checkScreenFirstVisit('/social/challenges', ...)` in `initState`.
- [ ] **Step 3.7.3:** `dart analyze lib/features/social/presentation/screens/challenges_screen.dart`
- [ ] **Step 3.7.4:**
```bash
git add lib/features/social/presentation/screens/challenges_screen.dart
git commit -m "feat(narrator): replace FeatureCoachMark in challenges_screen"
```

---

### Screen 3.8: `friends_screen.dart`

**File:** `lib/features/social/presentation/screens/friends_screen.dart`
**Route:** `/social/friends`

- [ ] **Step 3.8.1:** Find `FeatureCoachMark(` at line ~311. Delete block and import.
- [ ] **Step 3.8.2:** Add `_checkScreenFirstVisit('/social/friends', ...)` in `initState`.
- [ ] **Step 3.8.3:** `dart analyze lib/features/social/presentation/screens/friends_screen.dart`
- [ ] **Step 3.8.4:**
```bash
git add lib/features/social/presentation/screens/friends_screen.dart
git commit -m "feat(narrator): replace FeatureCoachMark in friends_screen"
```

---

### Screen 3.9: `leaderboard_screen.dart`

**File:** `lib/features/social/presentation/screens/leaderboard_screen.dart`
**Route:** `/social/leaderboard`

- [ ] **Step 3.9.1:** Find `FeatureCoachMark(` at line ~142. Delete block and import.
- [ ] **Step 3.9.2:** Add `_checkScreenFirstVisit('/social/leaderboard', ...)` in `initState`.
- [ ] **Step 3.9.3:** `dart analyze lib/features/social/presentation/screens/leaderboard_screen.dart`
- [ ] **Step 3.9.4:**
```bash
git add lib/features/social/presentation/screens/leaderboard_screen.dart
git commit -m "feat(narrator): replace FeatureCoachMark in leaderboard_screen"
```

---

### Screen 3.10: `social_activity_screen.dart`

**File:** `lib/features/social/presentation/screens/social_activity_screen.dart`
**Route:** `/social/activity`

- [ ] **Step 3.10.1:** Find `FeatureCoachMark(` at line ~90. Delete block and import.
- [ ] **Step 3.10.2:** Add `_checkScreenFirstVisit('/social/activity', ...)` in `initState`.
- [ ] **Step 3.10.3:** `dart analyze lib/features/social/presentation/screens/social_activity_screen.dart`
- [ ] **Step 3.10.4:**
```bash
git add lib/features/social/presentation/screens/social_activity_screen.dart
git commit -m "feat(narrator): replace FeatureCoachMark in social_activity_screen"
```

---

### Screen 3.11: `social_contacts_screen.dart`

**File:** `lib/features/social/presentation/screens/social_contacts_screen.dart`
**Route:** `/social/contacts`

- [ ] **Step 3.11.1:** Find `FeatureCoachMark(` at line ~154. Delete block and import.
- [ ] **Step 3.11.2:** Add `_checkScreenFirstVisit('/social/contacts', ...)` in `initState`.
- [ ] **Step 3.11.3:** `dart analyze lib/features/social/presentation/screens/social_contacts_screen.dart`
- [ ] **Step 3.11.4:**
```bash
git add lib/features/social/presentation/screens/social_contacts_screen.dart
git commit -m "feat(narrator): replace FeatureCoachMark in social_contacts_screen"
```

---

### Screen 3.12: `tribe_lobby_screen.dart`

**File:** `lib/features/social/presentation/screens/tribe_lobby_screen.dart`

> **Check first:** After Plan C replaces `TribeLobbyScreen` with `PulseFeedScreen` as the main `/social` route, this file may still exist as a sub-route (e.g., `/social/tribe/:id`). If the file is no longer used by any route, skip steps 3.12.1–3.12.3 and go straight to marking it for deletion in Task 4.

- [ ] **Step 3.12.1:** If still active: Find `FeatureCoachMark(` at line ~158. Delete block and import.
- [ ] **Step 3.12.2:** Add `_checkScreenFirstVisit('/social/tribe', ...)` in `initState`.
- [ ] **Step 3.12.3:** `dart analyze lib/features/social/presentation/screens/tribe_lobby_screen.dart`
- [ ] **Step 3.12.4:**
```bash
git add lib/features/social/presentation/screens/tribe_lobby_screen.dart
git commit -m "feat(narrator): replace FeatureCoachMark in tribe_lobby_screen"
```

---

## Task 4: Delete deprecated files

**Files to delete:**
- `lib/core/presentation/widgets/feature_coach_mark.dart`
- `lib/features/timeline/presentation/widgets/ai_coach_card.dart`
- `lib/features/timeline/presentation/widgets/reflection_card.dart`

- [ ] **Step 4.1: Verify no remaining usages**

```bash
# Run each of these — all must return 0 results:
grep -r "FeatureCoachMark" lib/ --include="*.dart"
grep -r "AiCoachCard" lib/ --include="*.dart"
grep -r "ReflectionCard" lib/ --include="*.dart"
grep -r "feature_coach_mark" lib/ --include="*.dart"
grep -r "ai_coach_card" lib/ --include="*.dart"
grep -r "reflection_card" lib/ --include="*.dart"
```

If any result is found, fix the remaining usage before proceeding.

- [ ] **Step 4.2: Delete the files**

```bash
Remove-Item "lib/core/presentation/widgets/feature_coach_mark.dart"
Remove-Item "lib/features/timeline/presentation/widgets/ai_coach_card.dart"
Remove-Item "lib/features/timeline/presentation/widgets/reflection_card.dart"
```

- [ ] **Step 4.3: Run analysis — must be zero errors**

```bash
dart analyze lib/
```

Expected: 0 errors, 0 warnings related to deleted files.

- [ ] **Step 4.4: Commit**

```bash
git add -A
git commit -m "chore: delete deprecated feature_coach_mark, ai_coach_card, reflection_card files"
```

---

## Task 5: Full test run

- [ ] **Step 5.1: Run all tests**

```bash
flutter test
```

Expected: 0 failures. If there are failures, read the error output carefully and fix one test at a time.

- [ ] **Step 5.2: Run full analysis**

```bash
dart analyze lib/
```

Expected: 0 errors.

- [ ] **Step 5.3: Smoke test on device**

```bash
flutter run
```

Walk through this checklist:

| Check | Expected |
|-------|----------|
| App opens | Timeline tab (index 0) |
| First visit to `/social` | Narrator sheet opens with tribe text, NOT a coach mark overlay |
| First visit to `/social/friends` | Narrator sheet opens with friends text |
| First visit to `/social/leaderboard` | Narrator sheet opens with leaderboard text |
| Second visit to any screen | Narrator does NOT fire again |
| World Map → node → first visit | Narrator sheet opens (from Plan B) |
| Timeline 18:30 + 1 habit done | Evening reflection Narrator fires |
| NarratorSummaryCard in Timeline | Shows, no loading spinner |
| Tapping "Hear more" | Narrator sheet opens |
| Notification action "Complete ✓" | Habit marked done (from Plan C) |

- [ ] **Step 5.4: Final commit**

```bash
git add -A
git commit -m "feat: complete habitual engagement redesign — Plans A, B, C, D"
```

---

## Verification Checklist (Plan D — All Plans Complete)

```bash
flutter test
dart analyze lib/
```

```bash
# Confirm all coach marks gone:
grep -r "FeatureCoachMark" lib/ --include="*.dart"
# Expected: no output

# Confirm deleted files gone:
ls lib/core/presentation/widgets/feature_coach_mark.dart
# Expected: file not found error

# Confirm Narrator files exist:
ls lib/features/narrator/domain/models/narrator_trigger.dart
ls lib/features/narrator/domain/services/narrator_trigger_engine.dart
ls lib/features/narrator/presentation/widgets/narrator_sheet.dart
ls lib/features/narrator/presentation/widgets/narrator_summary_card.dart
```

Manual checks:
- [ ] `FeatureCoachMark` does not appear anywhere in the codebase
- [ ] `NarratorSheet` opens on every first-visit screen in story form
- [ ] Buttons only appear after typewriter text finishes
- [ ] `WorldEventEngine` tests all pass (8 tests)
- [ ] `NarratorTriggerEngine` tests all pass (12 tests)
- [ ] Timeline opens in < 1 second, no skeleton loaders visible on `NarratorSummaryCard`
- [ ] Evening reflection fires after 18:00 with completed habits
- [ ] `flutter test` shows 0 failures
