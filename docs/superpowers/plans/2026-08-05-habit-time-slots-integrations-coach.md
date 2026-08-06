# Habit Time-of-Day, Integrations, Starter-Pack Selection & Coach Fixes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix six regressions: habits land in the correct time-of-day timeline slots with intuitive section names, create-habit Steps/Screen-Time integrations return, the onboarding starter pack is user-selected, coach asks stay flat at 3/day with a verified paywall dialog, all user-facing "Narrator" copy says "Coach", and guide cards never cover their spotlight target.

**Architecture:** Pure, unit-testable domain helpers (`habit_time_slots.dart`, a guide-card placement helper) feed the existing presentation layer. Persistence requires **no schema change** — `timeOfDayPreference`, `integrationType`, `integrationTarget` columns already exist in Drift and sync to Firestore. The create screen, starter-pack repository, timeline titles, first-habits screen, quota gate, and guide host are wired to consume those helpers.

**Tech Stack:** Flutter, Riverpod (codegen), Drift, fpdart `Either`, go_router, FakeHabitRepository / `NativeDatabase.memory()` test seams.

**State: Pending Implementation**

---

## Phase 1 — Time-of-Day Buckets

### Task 1: Pure slot helpers

**Files:**
- Create: `lib/features/habits/domain/services/habit_time_slots.dart`
- Test: `test/features/habits/domain/services/habit_time_slots_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/services/habit_time_slots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('timelineSlotKeyFor', () {
    test('maps 4:00–11:59 to morning', () {
      expect(timelineSlotKeyFor(const TimeOfDay(hour: 4, minute: 0)), 'morning');
      expect(timelineSlotKeyFor(const TimeOfDay(hour: 11, minute: 59)), 'morning');
    });

    test('maps 12:00–16:59 to afternoon', () {
      expect(
        timelineSlotKeyFor(const TimeOfDay(hour: 12, minute: 0)),
        'afternoon',
      );
      expect(
        timelineSlotKeyFor(const TimeOfDay(hour: 16, minute: 59)),
        'afternoon',
      );
    });

    test('maps 17:00–20:59 to evening', () {
      expect(timelineSlotKeyFor(const TimeOfDay(hour: 17, minute: 0)), 'evening');
      expect(timelineSlotKeyFor(const TimeOfDay(hour: 20, minute: 59)), 'evening');
    });

    test('maps 21:00–3:59 and no time to anytime (Before Bed)', () {
      expect(timelineSlotKeyFor(const TimeOfDay(hour: 21, minute: 0)), 'anytime');
      expect(timelineSlotKeyFor(const TimeOfDay(hour: 3, minute: 59)), 'anytime');
      expect(timelineSlotKeyFor(null), 'anytime');
    });
  });

  group('timelineSlotKeyForCue', () {
    test('recognizes wake/breakfast/morning keywords', () {
      expect(timelineSlotKeyForCue('After waking up'), 'morning');
      expect(timelineSlotKeyForCue('After breakfast'), 'morning');
      expect(timelineSlotKeyForCue('Morning coffee'), 'morning');
    });

    test('recognizes lunch/afternoon keywords', () {
      expect(timelineSlotKeyForCue('After lunch'), 'afternoon');
    });

    test('recognizes work/dinner/evening keywords', () {
      expect(timelineSlotKeyForCue('After work'), 'evening');
      expect(timelineSlotKeyForCue('Before dinner'), 'evening');
    });

    test('recognizes bed/night/reflection keywords', () {
      expect(timelineSlotKeyForCue('Before bed'), 'anytime');
      expect(timelineSlotKeyForCue('Evening reflection'), 'anytime');
    });

    test('defaults to morning when no keyword matches', () {
      expect(timelineSlotKeyForCue('During your run'), 'morning');
    });
  });

  group('timeOfDayPreferenceFrom', () {
    test('maps each slot key to the persisted enum value', () {
      expect(timeOfDayPreferenceFrom('morning'), TimeOfDayPreference.morning);
      expect(timeOfDayPreferenceFrom('afternoon'), TimeOfDayPreference.afternoon);
      expect(timeOfDayPreferenceFrom('evening'), TimeOfDayPreference.evening);
      expect(timeOfDayPreferenceFrom('anytime'), TimeOfDayPreference.anytime);
      expect(timeOfDayPreferenceFrom(null), TimeOfDayPreference.morning);
    });
  });
}
```

Note: `timelineSlotKeyForCue('Evening reflection')` must resolve to `'anytime'`. The keyword loop checks the **rest** keywords before `'evening'` (see implementation) so a cue containing both "evening" and "reflection" lands in the rest slot. The implementation below handles this with an explicit rest-first ordering.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/habits/domain/services/habit_time_slots_test.dart`
Expected: FAIL — "Error: No file or library found" (module does not exist).

- [ ] **Step 3: Write the implementation**

```dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

/// Canonical timeline slot keys. These match the grouping keys used by
/// `timeline_screen.dart` and `habit_timeline_section.dart`.
const List<String> timelineSlotKeys = [
  'morning',
  'afternoon',
  'evening',
  'anytime',
];

/// Keyword table for `StarterHabitBlueprint.shortCue` → slot.
/// The rest/`anytime` keywords are matched FIRST so cues like
/// "Evening reflection" land in "Before Bed", not "After Work".
const Map<String, List<String>> _cueKeywords = {
  'anytime': ['bed', 'night', 'reflection', 'journal', 'relax', 'sleep'],
  'morning': ['wake', 'breakfast', 'coffee', 'morning', 'shower', 'sunrise', 'rise'],
  'afternoon': ['lunch', 'noon', 'midday', 'afternoon'],
  'evening': ['work', 'dinner', 'evening', 'commute'],
};

/// Maps a clock time to the timeline slot key:
/// 4:00–11:59 morning · 12:00–16:59 afternoon · 17:00–20:59 evening ·
/// 21:00–3:59 (and no time) → 'anytime' (displayed as "Before Bed").
String timelineSlotKeyFor(TimeOfDay? time) {
  if (time == null) return 'anytime';
  final h = time.hour;
  if (h >= 4 && h < 12) return 'morning';
  if (h >= 12 && h < 17) return 'afternoon';
  if (h >= 17 && h < 21) return 'evening';
  return 'anytime';
}

/// Maps a starter-habit `shortCue` ("After breakfast", "Before bed") to a
/// timeline slot via keyword match; falls back to 'morning'.
String timelineSlotKeyForCue(String shortCue) {
  final cue = shortCue.toLowerCase();
  for (final slot in timelineSlotKeys) {
    for (final keyword in _cueKeywords[slot]!) {
      if (cue.contains(keyword)) return slot;
    }
  }
  return 'morning';
}

/// Maps a timeline slot key onto the persisted `TimeOfDayPreference` enum.
/// 'anytime' is the stored value for the "Before Bed" rest slot.
TimeOfDayPreference timeOfDayPreferenceFrom(String? slotKey) {
  switch (slotKey) {
    case 'afternoon':
      return TimeOfDayPreference.afternoon;
    case 'evening':
      return TimeOfDayPreference.evening;
    case 'anytime':
      return TimeOfDayPreference.anytime;
    case 'morning':
    default:
      return TimeOfDayPreference.morning;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/habits/domain/services/habit_time_slots_test.dart`
Expected: PASS (all groups).

- [ ] **Step 5: Commit**

```bash
git add lib/features/habits/domain/services/habit_time_slots.dart test/features/habits/domain/services/habit_time_slots_test.dart
git commit -m "feat(habits): pure timeline time-slot helpers (time + cue mapping)"
```

---

### Task 2: `Habit.timelineSection` derives the slot for legacy habits

**Files:**
- Modify: `lib/features/habits/domain/entities/habit.dart:356-362` (timelineSection getter)
- Test: `test/features/habits/domain/entities/habit_test.dart`

- [ ] **Step 1: Write the failing test**

Append a new group to `test/features/habits/domain/entities/habit_test.dart` (create the file if it does not exist, importing `package:emerge_app/features/habits/domain/services/habit_time_slots.dart` via `habit.dart`'s import — `habit_time_slots.dart` must be imported directly too):

```dart
group('timelineSection', () {
  test('returns the stored preference when set', () {
    final habit = Habit(
      id: 'h1',
      userId: 'u1',
      title: 'Read',
      createdAt: DateTime.now(),
      timeOfDayPreference: TimeOfDayPreference.morning,
    );
    expect(habit.timelineSection, 'morning');
  });

  test('derives the slot from reminderTime for legacy habits', () {
    final habit = Habit(
      id: 'h1',
      userId: 'u1',
      title: 'Read',
      createdAt: DateTime.now(),
      reminderTime: const TimeOfDay(hour: 19, minute: 0),
    );
    expect(habit.timelineSection, 'evening');
  });

  test('falls back to anytime (Before Bed) when neither is set', () {
    final habit = Habit(
      id: 'h1',
      userId: 'u1',
      title: 'Read',
      createdAt: DateTime.now(),
    );
    expect(habit.timelineSection, 'anytime');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/habits/domain/entities/habit_test.dart`
Expected: FAIL — the first test passes but the second returns null and the third returns null.

- [ ] **Step 3: Implement the fallback**

Add the import at the top of `habit.dart`:

```dart
import 'package:emerge_app/features/habits/domain/services/habit_time_slots.dart';
```

Replace the getter (`habit.dart:356-362`):

```dart
extension HabitExtension on Habit {
  String? get timelineSection {
    // Stored preference is authoritative. Legacy habits (preference null)
    // derive the slot from their reminder time so every habit lands in a
    // named section — no data migration required.
    if (timeOfDayPreference != null) {
      return timeOfDayPreference!.name;
    }
    return timelineSlotKeyFor(reminderTime);
  }
```

(Leave the rest of the extension — `isActiveOnDay`, `isCompletedOn` — unchanged.)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/habits/domain/entities/habit_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the timeline widget tests to catch regressions**

Run: `flutter test test/features/timeline/presentation/widgets/habit_timeline_section_test.dart`
Expected: PASS (titles unchanged so far).

- [ ] **Step 6: Commit**

```bash
git add lib/features/habits/domain/entities/habit.dart test/features/habits/domain/entities/habit_test.dart
git commit -m "feat(habits): derive timeline slot from reminder time for legacy habits"
```

---

### Task 3: Create screen persists the time-of-day slot

**Files:**
- Modify: `lib/features/habits/presentation/screens/habit_create_screen.dart` (import + `_createHabit`)
- Test: `test/features/habits/presentation/screens/habit_create_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Add a new group to `habit_create_screen_test.dart` that captures the habit passed to `createHabitProvider`:

```dart
group('HabitCreateScreen - time-of-day persistence', () {
  testWidgets('stores timeOfDayPreference derived from the reminder time',
      (tester) async {
    Habit? captured;
    await tester.pumpWidget(
      createScreenUnderTest(
        screen: const HabitCreateScreen(),
        overrides: [
          smartDefaultsProvider.overrideWith(
            (ref) => const SmartDefaults(
              time: TimeOfDay(hour: 7, minute: 0),
              attribute: HabitAttribute.vitality,
              difficulty: HabitDifficulty.easy,
              timerMinutes: 5,
            ),
          ),
          habitSuggestionsProvider.overrideWith(
            (ref) => const <String>['Drink water', 'Meditate'],
          ),
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(const AuthUser(id: 'u1', email: 'u@x.com')),
          ),
          createHabitProvider.overrideWith((ref, habit) async {
            captured = habit;
          }),
        ],
      ),
    );
    await tester.pump();

    // Fill the title via the typeahead (this also enables FORGE HABIT).
    await tester.tap(find.text('action'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField), 'med');
    await tester.pump();
    await tester.tap(find.text('Meditate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.text('FORGE HABIT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(captured, isNotNull);
    // Smart default time is 7:00 AM → morning.
    expect(captured!.timeOfDayPreference, TimeOfDayPreference.morning);
    expect(captured!.reminderTime, const TimeOfDay(hour: 7, minute: 0));
  });
});
```

Add imports to the test file:

```dart
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/habits/presentation/screens/habit_create_screen_test.dart`
Expected: FAIL — `captured!.timeOfDayPreference` is null.

- [ ] **Step 3: Implement persistence**

Add the import at the top of `habit_create_screen.dart`:

```dart
import 'package:emerge_app/features/habits/domain/services/habit_time_slots.dart';
```

In `_createHabit` (`habit_create_screen.dart:659`), add the `timeOfDayPreference` line to the `Habit(...)` constructor:

```dart
final habit = Habit(
  id: const Uuid().v4(),
  userId: userId,
  title: form.title.trim(),
  frequency: frequency,
  specificDays: specificDays,
  reminderTime: form.reminderTime ?? defaults.time,
  timeOfDayPreference: timeOfDayPreferenceFrom(
    timelineSlotKeyFor(form.reminderTime ?? defaults.time),
  ),
  location: form.location.isNotEmpty ? form.location : null,
  // ...rest unchanged
);
```

- [ ] **Step 4: Regenerate codegen**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: exits 0 (no `.g.dart` changes for this edit, but confirms the tree is clean).

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/habits/presentation/screens/habit_create_screen_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/habits/presentation/screens/habit_create_screen.dart test/features/habits/presentation/screens/habit_create_screen_test.dart
git commit -m "feat(habits): persist time-of-day slot from the create-screen time picker"
```

---

### Task 4: Starter pack persists the slot from the blueprint cue

**Files:**
- Modify: `lib/core/drift_repositories/drift_habit_repository.dart:734-757`
- Test: `test/features/habits/data/repositories/drift_habit_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `drift_habit_repository_test.dart`:

```dart
test('createStarterPack persists timeOfDayPreference derived from the cue',
    () async {
  final res = await repo.createStarterPack(
    userId: 'u1',
    blueprints: const [
      StarterHabitBlueprint(
        id: 'athlete.squats.10',
        title: '10 squats',
        shortCue: 'After breakfast',
        attribute: HabitAttribute.vitality,
        archetype: UserArchetype.athlete,
        interestCategories: [InterestCategory.movement],
        clubTags: [],
        sourceAttribution: 'happytrainers.com',
      ),
      StarterHabitBlueprint(
        id: 'scholar.read.2pages',
        title: 'Read 2 pages',
        shortCue: 'Before bed',
        attribute: HabitAttribute.intellect,
        archetype: UserArchetype.scholar,
        interestCategories: [InterestCategory.learning],
        clubTags: [],
        sourceAttribution: 'James Clear',
      ),
    ],
  );

  final habits = res.getRight().toList();
  expect(habits.length, 2);
  expect(habits[0].timeOfDayPreference, TimeOfDayPreference.morning);
  expect(habits[1].timeOfDayPreference, TimeOfDayPreference.anytime);

  final row = await db.habitsDao.getHabit(habits[0].id);
  expect(row!.timeOfDayPreference, 'morning');
});
```

Add imports to the test file:

```dart
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/onboarding/domain/models/interest.dart';
import 'package:emerge_app/features/onboarding/domain/models/starter_habit_blueprint.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/habits/data/repositories/drift_habit_repository_test.dart`
Expected: FAIL — `habits[0].timeOfDayPreference` is null.

- [ ] **Step 3: Implement persistence**

In `createStarterPack` (`drift_habit_repository.dart:734`), add the slot to the `Habit` constructor:

```dart
final habit = Habit(
  id: habitId,
  userId: userId,
  title: blueprint.title,
  cue: blueprint.shortCue,
  difficulty: HabitDifficulty.easy,
  attribute: blueprint.attribute,
  identityTags: [...tagSet, blueprint.id],
  frequency: HabitFrequency.daily,
  createdAt: now,
  timeOfDayPreference: timeOfDayPreferenceFrom(
    timelineSlotKeyForCue(blueprint.shortCue),
  ),
);
```

Add the import at the top of the file (next to the existing `starter_habit_blueprint.dart` import if present, otherwise create it):

```dart
import 'package:emerge_app/features/habits/domain/services/habit_time_slots.dart';
```

And pass the field to Drift in the `insertFromData` call (`drift_habit_repository.dart:746-757`) — append the named parameter:

```dart
timeOfDayPreference: habit.timeOfDayPreference?.name,
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/habits/data/repositories/drift_habit_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/drift_repositories/drift_habit_repository.dart test/features/habits/data/repositories/drift_habit_repository_test.dart
git commit -m "feat(habits): starter pack habits get a time-of-day slot from their cue"
```

---

### Task 5: Timeline section titles

**Files:**
- Modify: `lib/features/timeline/presentation/widgets/habit_timeline_section.dart:179-192`
- Test: `test/features/timeline/presentation/widgets/habit_timeline_section_test.dart`

- [ ] **Step 1: Write the failing test**

Append a group to `habit_timeline_section_test.dart`:

```dart
group('HierarchicalHabitTimeline - section titles', () {
  Widget _section({required String slot, required List<Habit> habits}) {
    return MaterialApp(
      home: Scaffold(
        body: HierarchicalHabitTimeline(
          groupedHabits: {slot: habits},
          selectedDate: DateTime.now(),
          onHabitTap: (_) {},
          onHabitToggle: (_) {},
          onTimerTap: (_) async => null,
          onMenuTap: (_) {},
        ),
      ),
    );
  }

  testWidgets('shows declaration-free intuitive section names',
      (tester) async {
    final now = DateTime.now();
    final h = Habit(
      id: 'h1',
      userId: 'u1',
      title: 'X',
      createdAt: now,
      timeOfDayPreference: TimeOfDayPreference.morning,
    );
    await tester.pumpWidget(_section(slot: 'morning', habits: [h]));
    expect(find.text('After I Wake Up'), findsOneWidget);

    await tester.pumpWidget(
      _section(
        slot: 'afternoon',
        habits: [h.copyWith(timeOfDayPreference: TimeOfDayPreference.afternoon)],
      ),
    );
    expect(find.text('During Lunch'), findsOneWidget);

    await tester.pumpWidget(
      _section(
        slot: 'evening',
        habits: [h.copyWith(timeOfDayPreference: TimeOfDayPreference.evening)],
      ),
    );
    expect(find.text('After Work'), findsOneWidget);

    await tester.pumpWidget(
      _section(
        slot: 'anytime',
        habits: [h.copyWith(timeOfDayPreference: TimeOfDayPreference.anytime)],
      ),
    );
    expect(find.text('Before Bed'), findsOneWidget);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/timeline/presentation/widgets/habit_timeline_section_test.dart`
Expected: FAIL — finds `After You Wake Up`, `During Lunch`, `Before Bed`, `Scheduled for Anytime` instead.

- [ ] **Step 3: Update the titles**

In `habit_timeline_section.dart:179-192`, replace the `_categoryTitle` getter:

```dart
String get _categoryTitle {
  switch (slot) {
    case 'morning':
      return 'After I Wake Up';
    case 'afternoon':
      return 'During Lunch';
    case 'evening':
      return 'After Work';
    case 'anytime':
      return 'Before Bed';
    default:
      return slot;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/timeline/presentation/widgets/habit_timeline_section_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/timeline/presentation/widgets/habit_timeline_section.dart test/features/timeline/presentation/widgets/habit_timeline_section_test.dart
git commit -m "feat(timeline): intuitive time-of-day section names"
```

---

## Phase 2 — Create-Habit Integrations

### Task 6: Integration form state + picker sheet

**Files:**
- Modify: `lib/features/habits/presentation/screens/habit_create_screen.dart`
- Test: `test/features/habits/presentation/screens/habit_create_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Append a group:

```dart
group('HabitCreateScreen - integrations', () {
  testWidgets('integration pill opens the sheet and applies a steps target',
      (tester) async {
    await tester.pumpWidget(_createTestWidget());
    await tester.pump();

    expect(find.text('NO INTEGRATION'), findsOneWidget);

    await tester.tap(find.text('NO INTEGRATION'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('LINK INTEGRATION'), findsOneWidget);
    await tester.tap(find.text('Health Steps'));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('integration_target_field')),
      '10000',
    );
    await tester.tap(find.text('CONFIRM'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('STEPS 10000'), findsOneWidget);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/habits/presentation/screens/habit_create_screen_test.dart`
Expected: FAIL — `find.text('NO INTEGRATION')` finds nothing.

- [ ] **Step 3: Add form state**

In `HabitFormData` (`habit_create_screen.dart:28`), add fields, defaults, copyWith, and constructor params:

```dart
class HabitFormData {
  final String title;
  final String emoji;
  final String time; // formatted display string, e.g. "7:00 AM"
  final TimeOfDay? reminderTime;
  final String location;
  final String frequency;
  final int timerMinutes;
  final HabitDifficulty difficulty;
  final HabitAttribute attribute;
  final String twoMinuteVersion;
  final HabitIntegrationType integrationType;
  final int? integrationTarget;

  const HabitFormData({
    required this.title,
    required this.emoji,
    required this.time,
    required this.reminderTime,
    required this.location,
    required this.frequency,
    required this.timerMinutes,
    required this.difficulty,
    required this.attribute,
    required this.twoMinuteVersion,
    this.integrationType = HabitIntegrationType.none,
    this.integrationTarget,
  });

  static const empty = HabitFormData(
    title: '',
    emoji: '🔥',
    time: '',
    reminderTime: null,
    location: '',
    frequency: 'daily',
    timerMinutes: 5,
    difficulty: HabitDifficulty.medium,
    attribute: HabitAttribute.vitality,
    twoMinuteVersion: '',
  );

  HabitFormData copyWith({
    String? title,
    String? emoji,
    String? time,
    TimeOfDay? reminderTime,
    String? location,
    String? frequency,
    int? timerMinutes,
    HabitDifficulty? difficulty,
    HabitAttribute? attribute,
    String? twoMinuteVersion,
    HabitIntegrationType? integrationType,
    int? integrationTarget,
  }) {
    return HabitFormData(
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      time: time ?? this.time,
      reminderTime: reminderTime ?? this.reminderTime,
      location: location ?? this.location,
      frequency: frequency ?? this.frequency,
      timerMinutes: timerMinutes ?? this.timerMinutes,
      difficulty: difficulty ?? this.difficulty,
      attribute: attribute ?? this.attribute,
      twoMinuteVersion: twoMinuteVersion ?? this.twoMinuteVersion,
      integrationType: integrationType ?? this.integrationType,
      integrationTarget: integrationTarget ?? this.integrationTarget,
    );
  }
}
```

In `HabitCreateState` (`habit_create_screen.dart:93`), add:

```dart
void updateIntegration(HabitIntegrationType type, int? target) =>
    state = state.copyWith(integrationType: type, integrationTarget: target);
```

- [ ] **Step 4: Add the integration pill to the secondary pills row**

In the `build` method's `Wrap` (after the Timer pill, `habit_create_screen.dart:220`), add:

```dart
// Integration pill
_SecondaryPill(
  label: _integrationLabel(form),
  isSelected: true,
  color: form.integrationType == HabitIntegrationType.none
      ? null
      : EmergeColors.teal,
  onTap: _showIntegrationSheet,
),
```

And the label helper at the bottom of the screen's private helpers:

```dart
String _integrationLabel(HabitFormData form) {
  switch (form.integrationType) {
    case HabitIntegrationType.healthSteps:
      return 'STEPS ${form.integrationTarget ?? 10000}';
    case HabitIntegrationType.screenTimeLimit:
      return 'SCREEN ${form.integrationTarget ?? 30} MIN';
    case HabitIntegrationType.none:
      return 'NO INTEGRATION';
  }
}
```

- [ ] **Step 5: Add the sheet**

Add the sheet method next to the other `_show*Sheet` methods:

```dart
void _showIntegrationSheet() {
  final form = ref.read(habitCreateStateProvider);
  var selected = form.integrationType;
  final targetController = TextEditingController(
    text: form.integrationTarget?.toString() ??
        (selected == HabitIntegrationType.healthSteps
            ? '10000'
            : selected == HabitIntegrationType.screenTimeLimit
                ? '30'
                : ''),
  );
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => _GlassSheet(
        title: 'LINK INTEGRATION',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IntegrationOption(
              label: 'No Integration',
              icon: Icons.block,
              isSelected: selected == HabitIntegrationType.none,
              onTap: () {
                setSheetState(() => selected = HabitIntegrationType.none);
              },
            ),
            _IntegrationOption(
              label: 'Health Steps',
              icon: Icons.directions_walk,
              isSelected: selected == HabitIntegrationType.healthSteps,
              onTap: () {
                setSheetState(() => selected = HabitIntegrationType.healthSteps);
              },
            ),
            _IntegrationOption(
              label: 'Screen Time Limit',
              icon: Icons.phone_android_outlined,
              isSelected: selected == HabitIntegrationType.screenTimeLimit,
              onTap: () {
                setSheetState(
                  () => selected = HabitIntegrationType.screenTimeLimit,
                );
              },
            ),
            if (selected != HabitIntegrationType.none) ...[
              const Gap(12),
              TextField(
                key: const Key('integration_target_field'),
                controller: targetController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: selected == HabitIntegrationType.healthSteps
                      ? 'Daily step goal (e.g. 10000)'
                      : 'Daily screen time limit in minutes (e.g. 30)',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const Gap(8),
              Text(
                'Requires the matching permission — enable it under '
                'Settings > Integrations & Data.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                ),
              ),
            ],
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final target = int.tryParse(targetController.text.trim());
                  if (selected == HabitIntegrationType.none) {
                    ref
                        .read(habitCreateStateProvider.notifier)
                        .updateIntegration(HabitIntegrationType.none, null);
                  } else if (target != null && target > 0) {
                    ref
                        .read(habitCreateStateProvider.notifier)
                        .updateIntegration(selected, target);
                  }
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmergeColors.teal,
                  foregroundColor: const Color(0xFF05100B),
                ),
                child: const Text('CONFIRM'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

Add the `_IntegrationOption` helper widget at the bottom of the file (next to `_SecondaryPill`):

```dart
class _IntegrationOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _IntegrationOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? EmergeColors.teal : Colors.white54),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? EmergeColors.teal : Colors.white,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: EmergeColors.teal, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/habits/presentation/screens/habit_create_screen_test.dart`
Expected: PASS (both the new integration group and existing groups).

- [ ] **Step 7: Commit**

```bash
git add lib/features/habits/presentation/screens/habit_create_screen.dart test/features/habits/presentation/screens/habit_create_screen_test.dart
git commit -m "feat(habits): integration picker on the create-habit screen"
```

---

### Task 7: Persist integration fields on create

**Files:**
- Modify: `lib/features/habits/presentation/screens/habit_create_screen.dart` (`_createHabit`)
- Test: `test/features/habits/presentation/screens/habit_create_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Append to the same file:

```dart
testWidgets('forges a habit with the selected integration fields',
    (tester) async {
  Habit? captured;
  await tester.pumpWidget(
    createScreenUnderTest(
      screen: const HabitCreateScreen(),
      overrides: [
        smartDefaultsProvider.overrideWith(
          (ref) => const SmartDefaults(
            time: TimeOfDay(hour: 7, minute: 0),
            attribute: HabitAttribute.vitality,
            difficulty: HabitDifficulty.easy,
            timerMinutes: 5,
          ),
        ),
        habitSuggestionsProvider.overrideWith(
          (ref) => const <String>['Drink water', 'Meditate'],
        ),
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(const AuthUser(id: 'u1', email: 'u@x.com')),
        ),
        createHabitProvider.overrideWith((ref, habit) async {
          captured = habit;
        }),
      ],
    ),
  );
  await tester.pump();

  // Title via typeahead.
  await tester.tap(find.text('action'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.enterText(find.byType(TextField), 'med');
  await tester.pump();
  await tester.tap(find.text('Meditate'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  // Pick Screen Time Limit = 45.
  await tester.tap(find.text('NO INTEGRATION'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.tap(find.text('Screen Time Limit'));
  await tester.pump();
  await tester.enterText(
    find.byKey(const Key('integration_target_field')),
    '45',
  );
  await tester.tap(find.text('CONFIRM'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  await tester.tap(find.text('FORGE HABIT'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  expect(captured, isNotNull);
  expect(
    captured!.integrationType,
    HabitIntegrationType.screenTimeLimit,
  );
  expect(captured!.integrationTarget, 45);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/habits/presentation/screens/habit_create_screen_test.dart`
Expected: FAIL — `captured.integrationType` is `none`.

- [ ] **Step 3: Implement persistence**

In `_createHabit` (`habit_create_screen.dart:659`), add the integration fields to the `Habit(...)` constructor:

```dart
final habit = Habit(
  id: const Uuid().v4(),
  userId: userId,
  title: form.title.trim(),
  frequency: frequency,
  specificDays: specificDays,
  reminderTime: form.reminderTime ?? defaults.time,
  timeOfDayPreference: timeOfDayPreferenceFrom(
    timelineSlotKeyFor(form.reminderTime ?? defaults.time),
  ),
  location: form.location.isNotEmpty ? form.location : null,
  attribute: form.attribute,
  createdAt: DateTime.now(),
  difficulty: form.difficulty,
  currentStreak: 0,
  twoMinuteVersion: form.twoMinuteVersion.isNotEmpty
      ? form.twoMinuteVersion
      : null,
  reward: 'Complete and enjoy your progress!',
  timerDurationMinutes: form.timerMinutes,
  imageUrl: form.emoji,
  integrationType: form.integrationType,
  integrationTarget: form.integrationTarget,
);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/habits/presentation/screens/habit_create_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the auto-complete unit test to confirm the engine still reads the fields**

Run: `flutter test test/features/health/` (or the health feature's existing auto-complete test file if present; if the directory has no tests, run `dart analyze lib/features/health/`)
Expected: PASS / no diagnostics.

- [ ] **Step 6: Commit**

```bash
git add lib/features/habits/presentation/screens/habit_create_screen.dart test/features/habits/presentation/screens/habit_create_screen_test.dart
git commit -m "feat(habits): persist integration type + target from create screen"
```

---

## Phase 3 — First-Habits Screen Multi-Select

### Task 8: Selectable starter cards, gated CTA, filtered pack

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/first_habits_screen.dart`
- Create: `test/features/onboarding/presentation/screens/first_habits_screen_test.dart`

- [ ] **Step 1: Write the failing tests**

Create the test file:

```dart
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/data/repositories/fake_habit_repository.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/onboarding/domain/models/starter_habit_blueprint.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_state_notifier.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/first_habits_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

class _FakeOnboarding extends EnhancedOnboardingNotifier {
  _FakeOnboarding(this._initial);
  final EnhancedOnboardingState _initial;

  @override
  EnhancedOnboardingState build() => _initial;

  @override
  void removeHabitStack(String stackId) {}

  @override
  Future<void> completeMilestone(int milestone) async {}
}

class _CapturingHabitRepository extends FakeHabitRepository {
  List<StarterHabitBlueprint> createdBlueprints = [];

  @override
  Future<Either<Failure, List<Habit>>> createStarterPack({
    required String userId,
    required List<StarterHabitBlueprint> blueprints,
    String? archetypeName,
    List<String> interestIds = const [],
    String? clubId,
  }) async {
    createdBlueprints = List.of(blueprints);
    return super.createStarterPack(
      userId: userId,
      blueprints: blueprints,
      archetypeName: archetypeName,
      interestIds: interestIds,
      clubId: clubId,
    );
  }
}

void main() {
  Future<ProviderContainer> container(_CapturingHabitRepository repo) async {
    return ProviderContainer(
      overrides: [
        habitRepositoryProvider.overrideWithValue(repo),
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(const AuthUser(id: 'u1', email: 'u@x.com')),
        ),
        enhancedOnboardingProvider.overrideWith(
          () => _FakeOnboarding(
            const EnhancedOnboardingState(selectedArchetype: UserArchetype.athlete),
          ),
        ),
      ],
    );
  }

  Future<void> pump(
    WidgetTester tester,
    ProviderContainer c,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: FirstHabitsScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('CTA disabled until at least one habit is selected',
      (tester) async {
    final repo = _CapturingHabitRepository();
    final c = await container(repo);
    addTearDown(c.dispose);
    await pump(tester, c);

    final start = find.widgetWithText(ElevatedButton, 'START MY JOURNEY');
    expect(tester.widget<ElevatedButton>(start).enabled, isFalse);

    await tester.tap(find.text('10 squats'));
    await tester.pump();
    expect(tester.widget<ElevatedButton>(start).enabled, isTrue);
  });

  testWidgets('creates the pack with only the selected habits',
      (tester) async {
    final repo = _CapturingHabitRepository();
    final c = await container(repo);
    addTearDown(c.dispose);
    await pump(tester, c);

    await tester.tap(find.text('10 squats'));
    await tester.pump();
    await tester.tap(find.text('60-second plank'));
    await tester.pump();

    await tester.tap(find.text('START MY JOURNEY'));
    await tester.pump();

    final ids = repo.createdBlueprints.map((b) => b.id).toList();
    expect(ids, contains('athlete.squats.10'));
    expect(ids, contains('athlete.plank.60s'));
    expect(ids, isNot(contains('athlete.walk.10min')));
  });
}
```

Note: the exact top-3 cards come from `StarterHabitBlueprint.forPersonalization`; the assertions above only depend on the visible athlete cards ('10 squats' and '60-second plank' are in the top-3 for `athlete`).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/onboarding/presentation/screens/first_habits_screen_test.dart`
Expected: FAIL — START MY JOURNEY is enabled with 0 selections, and tapping cards does nothing.

- [ ] **Step 3: Implement selection state**

In `_FirstHabitsScreenState` (`first_habits_screen.dart:33`), add selection state:

```dart
class _FirstHabitsScreenState extends ConsumerState<FirstHabitsScreen> {
  bool _isSaving = false;
  final Set<String> _selectedIds = {};
```

Change `_onStartJourney` to build the pack from the selected blueprints:

```dart
Future<void> _onStartJourney() async {
  if (_isSaving) return;
  final notifier = ref.read(enhancedOnboardingProvider.notifier);
  final state = ref.read(enhancedOnboardingProvider);
  final archetype = state.selectedArchetype;
  if (archetype == null || archetype == UserArchetype.none) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pick an archetype first.')),
    );
    return;
  }

  final all = StarterHabitBlueprint.forPersonalization(
    archetype: archetype,
    interestIds: state.interests,
    clubTags: state.joinedClubId != null ? [state.joinedClubId!] : const [],
  );
  final blueprints =
      all.where((b) => _selectedIds.contains(b.id)).toList(growable: false);

  if (blueprints.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Select at least one habit to start your pack.'),
      ),
    );
    return;
  }

  setState(() => _isSaving = true);

  try {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null || user.isEmpty) {
      throw Exception('Not signed in');
    }
    final repository = ref.read(habitRepositoryProvider);
    final result = await repository.createStarterPack(
      userId: user.id,
      blueprints: blueprints,
      archetypeName: archetype.name,
      interestIds: state.interests,
      clubId: state.joinedClubId,
    );
    result.fold(
      (failure) => throw Exception(failure.message),
      (_) {
        notifier.removeHabitStack('first_habits_screen');
      },
    );
    await notifier.completeMilestone(3);
    if (!mounted) return;
    context.push('/onboarding/world-reveal');
  } catch (e, s) {
    AppLogger.e('FirstHabitsScreen: failed to save starter pack', e, s);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save starter pack: $e')),
    );
    setState(() => _isSaving = false);
  }
}
```

In the `build` method, pass the selection state into each card (`first_habits_screen.dart:201-209`):

```dart
for (var i = 0; i < blueprints.length; i++)
  Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _BlueprintCard(
      index: i,
      blueprint: blueprints[i],
      isSelected: _selectedIds.contains(blueprints[i].id),
      onTap: () {
        setState(() {
          if (!_selectedIds.add(blueprints[i].id)) {
            _selectedIds.remove(blueprints[i].id);
          }
        });
        HapticFeedback.selectionClick();
      },
      onCustomizeTap: () => _onHabitTap(blueprints[i], i),
    ),
  ),
```

Update `_BottomBar`'s `canContinue`:

```dart
_BottomBar(
  canContinue: blueprints.isNotEmpty && !_isSaving && _selectedIds.isNotEmpty,
  isSaving: _isSaving,
  onContinue: _onStartJourney,
),
```

Update `_BlueprintCard` (`first_habits_screen.dart:267`) to accept `isSelected` and `onCustomizeTap`, render a check indicator, and move the customize affordance to a separate button:

```dart
class _BlueprintCard extends StatelessWidget {
  final int index;
  final StarterHabitBlueprint blueprint;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onCustomizeTap;

  const _BlueprintCard({
    required this.index,
    required this.blueprint,
    required this.isSelected,
    this.onTap,
    this.onCustomizeTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2BEE79).withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2BEE79).withValues(alpha: 0.5)
                : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2BEE79)
                        : const Color(0xFF2BEE79).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Color(0xFF05100B),
                          size: 18,
                        )
                      : Text(
                          '${index + 1}',
                          style: GoogleFonts.splineSans(
                            color: const Color(0xFF2BEE79),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const Gap(16),
                Expanded(
                  child: Text(
                    blueprint.title,
                    style: GoogleFonts.splineSans(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onCustomizeTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.tune,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                const Icon(
                  Icons.bolt,
                  color: Color(0xFF2BEE79),
                  size: 16,
                ),
                const Gap(6),
                Text(
                  blueprint.shortCue,
                  style: GoogleFonts.splineSans(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Gap(6),
            Text(
              blueprint.sourceAttribution,
              style: GoogleFonts.splineSans(
                color: Colors.white38,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 120 * (index + 1)));
  }
}
```

- [ ] **Step 4: Detail sheet stops creating habits directly**

In `_HabitDetailSheetState` (`first_habits_screen.dart:454`), replace the `_save` body so it never calls the repository:

```dart
Future<void> _save() async {
  if (_isSaving) return;
  setState(() => _isSaving = true);
  // The detail sheet only previews/edits the blueprint locally; the pack is
  // persisted once by _onStartJourney. No repository call here — creating a
  // habit directly would double-create for selected cards.
  await Future<void>.delayed(const Duration(milliseconds: 200));
  if (mounted) {
    Navigator.pop(context);
    widget.onSave(
      _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      _cueController.text.trim().isEmpty ? null : _cueController.text.trim(),
    );
  }
  setState(() => _isSaving = false);
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/onboarding/presentation/screens/first_habits_screen_test.dart`
Expected: PASS.

- [ ] **Step 6: Run the onboarding state notifier tests to catch regressions**

Run: `flutter test test/features/onboarding/presentation/providers/onboarding_state_notifier_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/onboarding/presentation/screens/first_habits_screen.dart test/features/onboarding/presentation/screens/first_habits_screen_test.dart
git commit -m "feat(onboarding): select one or more starter habits for the pack"
```

---

## Phase 4 — Coach Ask Quota

### Task 9: Lock the flat-3 quota + dialog gate with regression tests

**Files:**
- Test: `test/features/monetization/domain/coach_ask_quota_test.dart`
- Test: `test/features/narrator/presentation/widgets/narrator_card_test.dart`

- [ ] **Step 1: Write the failing regression tests**

Append to `coach_ask_quota_test.dart`:

```dart
group('flat free tier', () {
  test('free daily limit is exactly 3', () {
    expect(CoachAskQuota.freeDailyLimit, 3);
  });

  test('canAsk is false once usedToday reaches the limit', () {
    const atLimit = CoachAskQuota(
      dateKey: '2026-08-05',
      usedToday: 3,
      isPremium: false,
    );
    const over = CoachAskQuota(
      dateKey: '2026-08-05',
      usedToday: 4,
      isPremium: false,
    );
    expect(atLimit.canAsk, isFalse);
    expect(over.canAsk, isFalse);
    expect(over.remaining, 0);
  });

  test('the quota has no habit-count input', () {
    // The quota model is a pure (dateKey, usedToday, isPremium) triple.
    // This test exists to prevent anyone from re-introducing habit-count
    // scaling that regressed the UI to "8 of 8" when the user had 8 habits.
    const q = CoachAskQuota(
      dateKey: '2026-08-05',
      usedToday: 0,
      isPremium: false,
    );
    expect(q.remaining, 3);
  });
});
```

Append to `narrator_card_test.dart`:

```dart
testWidgets(
    'quota hint stays "X of 3" regardless of how many habits exist',
    (tester) async {
  SharedPreferences.setMockInitialValues({
    'coach_asks_${CoachAskQuota.dateKeyFor(DateTime.now())}': 0,
  });
  // 8 habits — the exact scenario that previously displayed "8 of 8".
  final c = await container(
    habits: List.generate(8, (i) => _habit('Habit $i')),
  );
  addTearDown(c.dispose);
  await pumpCard(tester, c);
  expect(find.text('3 of 3 coach asks left today'), findsOneWidget);
});
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/features/monetization/domain/coach_ask_quota_test.dart test/features/narrator/presentation/widgets/narrator_card_test.dart`
Expected: PASS. If the narrator-card hint test fails with "8 of 8" or similar, the quota path is genuinely scaled somewhere — stop and investigate (see Task 10) before proceeding.

- [ ] **Step 3: Commit**

```bash
git add test/features/monetization/domain/coach_ask_quota_test.dart test/features/narrator/presentation/widgets/narrator_card_test.dart
git commit -m "test(coach): lock flat 3/day coach quota regardless of habit count"
```

---

### Task 10: Root-cause the reported "8 of 8" (systematic debugging)

**Files:** investigation only — no production change unless a defect is found.

- [ ] **Step 1: Confirm the current behavior in code**

Read `lib/features/monetization/domain/services/coach_ask_quota.dart` and `lib/features/narrator/presentation/widgets/narrator_card.dart:140-146`. Expected: `freeDailyLimit == 3`; the hint string is `'$remaining of 3 coach asks left today'`. If the code differs (a `remaining` derived from habit count), that is the defect — fix it to use `CoachAskQuota.freeDailyLimit`.

- [ ] **Step 2: Check whether the user ran a stale build**

Run: `git log --oneline -5 -- lib/features/monetization/domain/services/coach_ask_quota.dart`
Expected: recent commits touch the quota file. If the "8 of 8" predates the current `freeDailyLimit == 3` code, the report is from an older build and Task 9's regression test is sufficient.

- [ ] **Step 3: Check for duplicate quota keys**

Run: `grep -rn "coach_asks_" lib/`
Expected: the only writer is `coach_ask_quota_provider.dart`. Multiple writers with different keys (e.g. a per-habit key) would explain inflated counts — if found, consolidate on `coach_asks_<yyyy-MM-dd>`.

- [ ] **Step 4: Verify the dialog gate**

Read `lib/features/narrator/presentation/widgets/narrator_card.dart:84-98`. Expected: `quota.canAsk` gates the ask and, when false, calls `showPremiumLimitDialog(limitType: PremiumLimitType.coachAsk)`, whose button navigates to `/paywall` (`premium_limit_dialog.dart:125-129`). The `exhausted quota opens the premium limit dialog` test in `narrator_card_test.dart` already asserts this — run it:

Run: `flutter test test/features/narrator/presentation/widgets/narrator_card_test.dart --plain-name "exhausted quota"`
Expected: PASS.

- [ ] **Step 5: Report findings + commit any fix**

If a defect was found, add a focused fix with a failing test first (Red → Green). Otherwise record the finding in the plan review notes and commit nothing:

```bash
git status --short
```

---

## Phase 5 — Narrator → Coach (User-Facing Text Only)

### Task 11: Rename user-visible "Narrator" copy to "Coach"

**Files:**
- Modify: all files listed by the grep in Step 1 (settings, guide card, avatar, milestone card, registry scripts, card copy, paywall)
- Test: existing narrator widget/provider tests that assert copy strings

- [ ] **Step 1: Enumerate the user-facing strings**

Run:

```bash
grep -rn "'Narrator'\|'NARRATOR'\|Narrator the\|the narrator\|Ask the narrator\|Replay narrator" lib/ | grep -v "\.g\.dart"
```

Review each hit. Only strings that appear in the UI (Text widgets, tooltips, snackbars, paywall copy, guide scripts, notification text) are renamed. Code identifiers, comments, file names, and provider/class names are untouched.

- [ ] **Step 2: Rename the known copy sites**

Apply these specific edits:

`lib/features/narrator/presentation/widgets/narrator_guide_card.dart:53`:

```dart
const Text(
  'COACH',
  style: TextStyle(
    fontSize: 10,
    letterSpacing: 2.5,
    fontWeight: FontWeight.bold,
    color: EmergeColors.teal,
  ),
),
```

`lib/features/settings/presentation/screens/settings_screen.dart:363`:

```dart
_buildListTile(
  context,
  Icons.replay_outlined,
  'Replay coach guides',
  subtitle: 'Shows every guide again on next visit',
  onTap: () => _showReplayGuidesDialog(context, ref),
),
```

For every other hit from Step 1, replace the display string with the "Coach"/"coach" equivalent (e.g. `'✎ Ask the narrator'` → `'✎ Ask the coach'` in `narrator_card.dart`, avatar tooltip, milestone copy, guide scripts in `narrator_guide_registry.dart`).

- [ ] **Step 3: Update tests asserting the old copy**

Run: `grep -rn "narrator" test/features/narrator/ test/features/settings/ | grep -iv "narrator_[a-z]*\|Narrator[A-Z]"`
Update any assertion that references the old display strings to the new "Coach" text. Known site: `test/features/narrator/presentation/widgets/narrator_card_test.dart:113,135` uses `find.text('✎ Ask the narrator')`.

- [ ] **Step 4: Run focused tests**

Run: `flutter test test/features/narrator/`
Expected: PASS.

- [ ] **Step 5: Run the analyzer**

Run: `dart analyze lib/features/narrator/ lib/features/settings/`
Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(coach): rename user-facing narrator copy to coach"
```

---

## Phase 6 — Spotlight Card Placement

### Task 12: Pure guide-card placement helper

**Files:**
- Create: `lib/features/narrator/domain/services/guide_card_placement.dart`
- Test: `test/features/narrator/domain/services/guide_card_placement_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/narrator/domain/services/guide_card_placement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cardHeight = 140.0;
  const margin = 16.0;

  test('no target -> pinned to the bottom like today', () {
    final pos = guideCardPositionFor(
      targetRect: null,
      screenSize: const Size(400, 800),
      cardHeight: cardHeight,
      margin: margin,
      topInset: 0,
      bottomInset: 24,
    );
    expect(pos.top, isNull);
    expect(pos.bottom, 48); // 24 fallback + 24 bottomInset
  });

  test('target near the bottom -> card sits above it', () {
    final pos = guideCardPositionFor(
      targetRect: const Rect.fromLTWH(100, 640, 200, 50),
      screenSize: const Size(400, 800),
      cardHeight: cardHeight,
      margin: margin,
      topInset: 0,
      bottomInset: 24,
    );
    // spaceAbove = 640 >= 156 -> above: top = 640 - 140 - 16.
    expect(pos.top, 484);
    expect(pos.bottom, isNull);
  });

  test('target near the top -> card sits below it', () {
    final pos = guideCardPositionFor(
      targetRect: const Rect.fromLTWH(100, 100, 200, 50),
      screenSize: const Size(400, 800),
      cardHeight: cardHeight,
      margin: margin,
      topInset: 0,
      bottomInset: 24,
    );
    // spaceAbove = 100 < 156; spaceBelow = 800 - 24 - 150 = 626 >= 156.
    expect(pos.top, 166); // target.bottom + margin
    expect(pos.bottom, isNull);
  });

  test('full-screen target -> falls back to bottom pinned', () {
    final pos = guideCardPositionFor(
      targetRect: const Rect.fromLTWH(0, 0, 400, 800),
      screenSize: const Size(400, 800),
      cardHeight: cardHeight,
      margin: margin,
      topInset: 0,
      bottomInset: 24,
    );
    expect(pos.top, isNull);
    expect(pos.bottom, 48);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/narrator/domain/services/guide_card_placement_test.dart`
Expected: FAIL — module does not exist.

- [ ] **Step 3: Write the implementation**

```dart
import 'dart:ui';

/// Resolved position for the guide card. Exactly one of [top]/[bottom] is
/// non-null so it can be passed straight to a `Positioned` widget.
typedef GuideCardPosition = ({double? top, double? bottom});

/// Chooses where the first-visit guide card goes so it never covers the
/// spotlighted target when there is room elsewhere:
///  1. above the target if that space fits;
///  2. else below the target if that space fits;
///  3. else pinned to the bottom (current behavior).
GuideCardPosition guideCardPositionFor({
  required Rect? targetRect,
  required Size screenSize,
  required double cardHeight,
  required double margin,
  required double topInset,
  required double bottomInset,
}) {
  const fallback = 24.0;
  if (targetRect == null) {
    return (top: null, bottom: fallback + bottomInset);
  }

  final spaceAbove = targetRect.top - topInset;
  final spaceBelow =
      screenSize.height - bottomInset - targetRect.bottom;

  if (spaceAbove >= cardHeight + margin) {
    return (top: targetRect.top - cardHeight - margin, bottom: null);
  }
  if (spaceBelow >= cardHeight + margin) {
    return (top: targetRect.bottom + margin, bottom: null);
  }
  return (top: null, bottom: fallback + bottomInset);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/narrator/domain/services/guide_card_placement_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/narrator/domain/services/guide_card_placement.dart test/features/narrator/domain/services/guide_card_placement_test.dart
git commit -m "feat(narrator): pure guide-card placement helper"
```

---

### Task 13: Guide host uses the placement helper

**Files:**
- Modify: `lib/features/narrator/presentation/widgets/narrator_guide_host.dart`
- Test: `test/features/narrator/presentation/widgets/narrator_guide_host_test.dart`

- [ ] **Step 1: Write the failing widget test**

Append to `narrator_guide_host_test.dart`, reusing the file's `_FakeSettings` + `localSettingsRepositoryProvider.overrideWithValue` pattern (bounded pumps — the card's typewriter never settles):

```dart
testWidgets('guide card renders clear of a low target instead of covering it',
    (tester) async {
  final targetKey = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localSettingsRepositoryProvider.overrideWithValue(
          _FakeSettings(tutorialsEnabled: true),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: NarratorGuideHost(
            nodeId: 'habit_create',
            targets: {'name_field': targetKey},
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                key: targetKey,
                width: 120,
                height: 60,
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(); // post-frame gate resolves, card builds
  await tester.pump(const Duration(milliseconds: 400)); // typewriter ticks

  final cardFinder = find.byType(NarratorGuideCard);
  expect(cardFinder, findsOneWidget);
  final cardBox = tester.getRect(cardFinder);
  final targetBox = tester.getRect(targetKey.currentContext!);
  // The card must not overlap the spotlighted element.
  expect(cardBox.overlaps(targetBox), isFalse);
});
```

Add the import to the test file:

```dart
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_card.dart';
```

Note: the first step of the `habit_create` node targets `'name_field'`. The `_guideCardEstimatedHeight` (160) + margin (16) must fit in the space above the bottom-anchored 60px target (screen 800×600 → target top ≈ 540; space above ≈ 540 ≥ 176 → card placed above).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/narrator/presentation/widgets/narrator_guide_host_test.dart`
Expected: FAIL — the card overlaps the FAB (current fixed-bottom placement).

- [ ] **Step 3: Wire the helper into the host**

In `narrator_guide_host.dart`, add the import:

```dart
import 'package:emerge_app/features/narrator/domain/services/guide_card_placement.dart';
```

Add a height estimate constant and helper to `_NarratorGuideHostState`:

```dart
static const double _guideCardEstimatedHeight = 160;
```

In `build` (`narrator_guide_host.dart:152`), replace the fixed `Positioned` with one that resolves placement from the current target rect:

```dart
if (step != null)
  _buildGuideCard(step),
```

and add the method:

```dart
Widget _buildGuideCard(NarratorGuideStep step) {
  final targetRect = _rectFor(step.targetKey);
  final screenSize = MediaQuery.sizeOf(context);
  final topInset = MediaQuery.paddingOf(context).top;
  final bottomInset = MediaQuery.paddingOf(context).bottom;
  final position = guideCardPositionFor(
    targetRect: targetRect,
    screenSize: screenSize,
    cardHeight: _guideCardEstimatedHeight,
    margin: 16,
    topInset: topInset,
    bottomInset: bottomInset,
  );
  return Positioned(
    left: 16,
    right: 16,
    top: position.top,
    bottom: position.bottom,
    child: NarratorGuideCard(
      script: step.script,
      stepIndex: _step,
      stepCount: _steps.length,
      onAdvance: _advance,
      onSkip: _finish,
    ),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/narrator/presentation/widgets/narrator_guide_host_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the guide card tests too**

Run: `flutter test test/features/narrator/presentation/widgets/narrator_guide_card_test.dart test/features/narrator/domain/services/guide_card_placement_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/narrator/presentation/widgets/narrator_guide_host.dart test/features/narrator/presentation/widgets/narrator_guide_host_test.dart
git commit -m "fix(narrator): position guide card clear of its spotlight target"
```

---

## Final Verification

- [ ] **Step 1: Analyze the touched areas**

Run: `dart analyze lib/features/habits lib/features/timeline lib/features/onboarding lib/features/monetization lib/features/narrator lib/core/drift_repositories`
Expected: No issues found.

- [ ] **Step 2: Run the focused suites for every phase**

Run:
```bash
flutter test test/features/habits/domain/services/habit_time_slots_test.dart
flutter test test/features/habits/domain/entities/habit_test.dart
flutter test test/features/habits/presentation/screens/habit_create_screen_test.dart
flutter test test/features/habits/data/repositories/drift_habit_repository_test.dart
flutter test test/features/timeline/presentation/widgets/habit_timeline_section_test.dart
flutter test test/features/onboarding/presentation/screens/first_habits_screen_test.dart
flutter test test/features/monetization/domain/coach_ask_quota_test.dart
flutter test test/features/narrator/presentation/widgets/narrator_card_test.dart
flutter test test/features/narrator/domain/services/guide_card_placement_test.dart
flutter test test/features/narrator/presentation/widgets/narrator_guide_host_test.dart
```
Expected: all pass.

- [ ] **Step 3: Report evidence**

Summarize the command output for each suite, plus the Task 10 root-cause findings, before declaring the work complete.
