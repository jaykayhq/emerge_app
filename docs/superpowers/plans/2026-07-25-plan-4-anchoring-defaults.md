# Plan 4: Anchoring + Defaults Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add smart defaults to habit creation (anchoring), reframe the EMERGE locked-state button with progress info, and improve typeahead sort order.

**Architecture:** (1) A `SmartDefaultsService` that analyzes existing habits and archetype to pre-fill time, attribute, difficulty, and timer. (2) EMERGE button shows level progress and preview text instead of a generic lock. (3) Typeahead suggestions sorted by user history → archetype match → curated fallback.

**Tech Stack:** Flutter, Riverpod, existing `archetype_provider`, `habits_provider`, `future_self_studio_screen.dart`, new `habit_create_screen.dart` (Plan 7).

**State: Pending Implementation**

---

### Task 1: SmartDefaultsService — pure logic

**Files:**
- Create: `lib/features/habits/domain/services/smart_defaults_service.dart`
- Test: `test/features/habits/domain/services/smart_defaults_service_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/habits/domain/services/smart_defaults_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/services/smart_defaults_service.dart';

void main() {
  group('SmartDefaultsService', () {
    test('returns archetype time when no existing habits', () {
      final defaults = computeSmartDefaults(
        existingHabits: [],
        archetype: Archetype.vitality,
      );
      expect(defaults.time, equals('7:00 AM')); // Vitality default: morning
    });

    test('returns most common time from existing habits', () {
      final defaults = computeSmartDefaults(
        existingHabits: [
          _TestHabit(time: '7:00 AM'),
          _TestHabit(time: '7:00 AM'),
          _TestHabit(time: '8:00 PM'),
        ],
        archetype: Archetype.vitality,
      );
      expect(defaults.time, equals('7:00 AM'));
    });

    test('returns Easy difficulty when fewer than 3 active habits', () {
      final defaults = computeSmartDefaults(
        existingHabits: [_TestHabit(time: '7:00 AM')],
        archetype: Archetype.vitality,
        activeHabitCount: 2,
      );
      expect(defaults.difficulty, equals(Difficulty.easy));
    });

    test('returns Medium difficulty when 3 or more active habits', () {
      final defaults = computeSmartDefaults(
        existingHabits: [],
        archetype: Archetype.vitality,
        activeHabitCount: 5,
      );
      expect(defaults.difficulty, equals(Difficulty.medium));
    });

    test('returns 5 min timer default when no existing timer data', () {
      final defaults = computeSmartDefaults(
        existingHabits: [],
        archetype: Archetype.vitality,
      );
      expect(defaults.timerMinutes, equals(5));
    });
  });
}

class _TestHabit {
  final String time;
  const _TestHabit({required this.time});
}
```

- [ ] **Step 2: Implement SmartDefaultsService**

```dart
// lib/features/habits/domain/services/smart_defaults_service.dart

enum Archetype { vitality, serenity, wisdom, creativity, community, discipline }
enum Difficulty { easy, medium, hard }

class SmartDefaults {
  final String time;
  final String attribute;
  final Difficulty difficulty;
  final int timerMinutes;

  const SmartDefaults({
    required this.time,
    required this.attribute,
    required this.difficulty,
    required this.timerMinutes,
  });
}

/// Archetype-based default times
const _archetypeDefaultTimes = {
  Archetype.vitality: '7:00 AM',
  Archetype.serenity: '6:00 AM',
  Archetype.wisdom: '8:00 AM',
  Archetype.creativity: '10:00 AM',
  Archetype.community: '9:00 AM',
  Archetype.discipline: '5:00 AM',
};

const _archetypeDefaultAttributes = {
  Archetype.vitality: 'VITALITY',
  Archetype.serenity: 'SERENITY',
  Archetype.wisdom: 'WISDOM',
  Archetype.creativity: 'CREATIVITY',
  Archetype.community: 'COMMUNITY',
  Archetype.discipline: 'DISCIPLINE',
};

SmartDefaults computeSmartDefaults<T extends HasTimeField>({
  required List<T> existingHabits,
  required Archetype archetype,
  int activeHabitCount = 0,
}) {
  // Time: most common among existing, or archetype default
  String time;
  if (existingHabits.isEmpty) {
    time = _archetypeDefaultTimes[archetype] ?? '7:00 AM';
  } else {
    final timeCounts = <String, int>{};
    for (final h in existingHabits) {
      timeCounts[h.time] = (timeCounts[h.time] ?? 0) + 1;
    }
    time = timeCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Attribute: archetype primary
  final attribute = _archetypeDefaultAttributes[archetype] ?? 'VITALITY';

  // Difficulty: Easy if <3 active habits, Medium otherwise
  final difficulty = activeHabitCount < 3 ? Difficulty.easy : Difficulty.medium;

  // Timer: 5 min default
  const timerMinutes = 5;

  return SmartDefaults(
    time: time,
    attribute: attribute,
    difficulty: difficulty,
    timerMinutes: timerMinutes,
  );
}

abstract class HasTimeField {
  String get time;
}
```

- [ ] **Step 3: Run test → pass**

- [ ] **Step 4: Commit**

```bash
git add lib/features/habits/domain/services/ test/features/habits/domain/services/
git commit -m "feat(habits): add SmartDefaultsService with pure compute function and tests"
```

---

### Task 2: Riverpod provider for smart defaults

**Files:**
- Create: `lib/features/habits/presentation/providers/smart_defaults_provider.dart`

- [ ] **Step 1: Create the provider**

```dart
@riverpod
SmartDefaults smartDefaults(Ref ref) {
  final habits = ref.watch(todayHabitsProvider);
  final archetype = ref.watch(userArchetypeProvider);
  final activeCount = habits.length;
  return computeSmartDefaults(
    existingHabits: habits,
    archetype: archetype, // adjust type as needed
    activeHabitCount: activeCount,
  );
}
```

- [ ] **Step 2: Run build_runner**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/habits/presentation/providers/smart_defaults_provider.dart
git commit -m "feat(habits): add smartDefaults provider"
```

---

### Task 3: EMERGE button reframing with progress

**Files:**
- Modify: `lib/features/profile/presentation/screens/future_self_studio_screen.dart`

- [ ] **Step 1: Read current EMERGE ceremony button**

Find the EMERGE button (likely a locked/unlockable button).

- [ ] **Step 2: Refactor to show progress + preview**

```dart
// Locked state:
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Column(
    children: [
      Text("Level ${currentLevel}/5", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      Text("Complete ${nextLevelRequirement - currentProgress} more habits to unlock", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
      LinearProgressIndicator(value: currentLevel / 5),
      const Gap(12),
      Text("Next: ${nextCeremonyTitle}", style: TextStyle(color: Colors.cyanAccent, fontSize: 14)),
      const Gap(16),
      ElevatedButton.icon(
        onPressed: null, // locked
        icon: const Icon(Icons.lock_outline),
        label: const Text("EMERGE"),
      ),
    ],
  ),
)
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/presentation/screens/future_self_studio_screen.dart
git commit -m "feat(profile): reframe EMERGE button with level progress and next ceremony preview"
```

---

### Task 4: Typeahead sort order

**Files:**
- Modify: `lib/features/habits/presentation/providers/habit_suggestions_provider.dart` (or similar)

- [ ] **Step 1: Read current typeahead implementation**

- [ ] **Step 2: Update sort order**

```dart
List<String> sortedSuggestions(
  List<String> allSuggestions,
  List<String> userCreatedHabits,
  String? archetype,
  List<String> interestTags,
) {
  // 1. Habits user has created before (priority)
  // 2. Archetype + interest match
  // 3. Curated fallback
  final created = allSuggestions.where((s) => userCreatedHabits.contains(s)).toList();
  final matched = allSuggestions.where((s) =>
    !userCreatedHabits.contains(s) &&
    (interestTags.any((t) => s.contains(t)) || s.contains(archetype ?? ''))
  ).toList();
  final fallback = allSuggestions.where((s) =>
    !created.contains(s) && !matched.contains(s)
  ).toList();
  return [...created, ...matched, ...fallback];
}
```

- [ ] **Step 3: Write test**

```dart
test('sorts user-created habits first', () {
  final result = sortedSuggestions(
    ['Meditate', 'Read', 'Run', 'Write'],
    userCreatedHabits: ['Read'],
    archetype: 'VITALITY',
    interestTags: ['Fitness'],
  );
  expect(result.first, 'Read');
});
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/habits/presentation/providers/habit_suggestions_provider.dart
git commit -m "feat(habits): improve typeahead sort order by user history, archetype match, fallback"
```

---

### Task 5: Verification

- [ ] **Step 1: Run build_runner + analyze + test**

```bash
flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat(anchoring): verify all anchoring and defaults features"
```
