# Habitual Engagement — Plan B: The Narrator System

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Narrator — a single AI storyteller that replaces `FeatureCoachMark` (14 screens), the Node Guide AlertDialog, `AiCoachCard`, and `ReflectionCard` — appearing at 12 critical moments in the user's journey with typewriter-streamed, identity-language text.

**Architecture:** The Narrator is a feature module at `lib/features/narrator/`. A pure-function `NarratorTriggerEngine` decides when to show (no Firebase, no Riverpod — fully unit-testable). A `NarratorStateNotifier` (Riverpod) holds visibility state. A `NarratorSheet` bottom sheet renders with a typewriter effect. Templates are local (instant render); AI slots stream in from a Groq Cloud Function. `NarratorNote`s are written to Drift locally first, synced to Firestore for premium users.

**Tech Stack:** Flutter, Dart, Riverpod 3 (codegen), Drift, freezed, fpdart `Either`, Firebase Cloud Functions (TypeScript), Groq API

**Prerequisite:** Plan A must be complete. `HabitStreakState` and `CompletionResult` must exist.

---

## Context You Must Read First

- `lib/features/companion/` — the existing companion system this replaces. Read but do NOT delete yet (deletion is in Plan D).
- `lib/features/timeline/presentation/widgets/ai_coach_card.dart` — what `NarratorSummaryCard` replaces. Read to understand its data shape.
- `lib/features/timeline/presentation/widgets/reflection_card.dart` — what the `eveningReflection` trigger replaces.
- `lib/core/drift/app_database.dart` — understand Drift table definitions before adding a new table.
- `lib/features/gamification/presentation/providers/user_stats_providers.dart` — where `UserProfile`/`UserStats` lives.
- `functions/src/index.ts` — how existing Cloud Functions are registered; follow the same pattern.

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| CREATE | `lib/features/narrator/domain/models/narrator_trigger.dart` | Enum: 12 trigger values |
| CREATE | `lib/features/narrator/domain/models/narrator_note.dart` | Observation log model |
| CREATE | `lib/features/narrator/domain/models/narrator_appearance.dart` | What the Narrator says + buttons |
| CREATE | `lib/features/narrator/domain/services/narrator_trigger_engine.dart` | Pure function — should Narrator show? |
| CREATE | `lib/features/narrator/data/datasources/narrator_local_datasource.dart` | Drift table + queries |
| CREATE | `lib/features/narrator/data/repositories/narrator_repository.dart` | Interface + implementation |
| CREATE | `lib/features/narrator/presentation/providers/narrator_providers.dart` | Riverpod providers |
| CREATE | `lib/features/narrator/presentation/providers/narrator_providers.g.dart` | Generated (run build_runner) |
| CREATE | `lib/features/narrator/presentation/widgets/narrator_pulse_indicator.dart` | Animated ◐ symbol |
| CREATE | `lib/features/narrator/presentation/widgets/narrator_typewriter.dart` | Typewriter text widget |
| CREATE | `lib/features/narrator/presentation/widgets/narrator_sheet.dart` | Full bottom sheet UI |
| CREATE | `lib/features/narrator/presentation/widgets/narrator_summary_card.dart` | Inline Timeline card |
| CREATE | `functions/src/narrator.ts` | Groq slot-filling Cloud Function |
| MODIFY | `lib/core/drift/app_database.dart` | Add `narrator_notes` table |
| MODIFY | `lib/features/timeline/presentation/screens/timeline_screen.dart` | Replace AiCoachCard → NarratorSummaryCard, add eveningReflection trigger |
| MODIFY | `lib/features/world_map/presentation/screens/level_immersive_screen.dart` | Replace _showCompanionGuide → Narrator nodeFirstVisit |
| CREATE | `test/features/narrator/domain/services/narrator_trigger_engine_test.dart` | Unit tests |
| CREATE | `test/features/narrator/presentation/widgets/narrator_typewriter_test.dart` | Widget tests |

---

## Task 1: Narrator models

**Files:**
- Create: `lib/features/narrator/domain/models/narrator_trigger.dart`
- Create: `lib/features/narrator/domain/models/narrator_note.dart`
- Create: `lib/features/narrator/domain/models/narrator_appearance.dart`
- Test: `test/features/narrator/domain/models/narrator_models_test.dart`

- [ ] **Step 1.1: Write failing test**

```dart
// test/features/narrator/domain/models/narrator_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';

void main() {
  test('NarratorTrigger has 12 values', () {
    expect(NarratorTrigger.values.length, 12);
  });

  test('NarratorNote stores type and data', () {
    final note = NarratorNote(
      id: 'n1',
      type: NarratorNoteType.reflection,
      data: {'response': 'life happened'},
      recordedAt: DateTime(2026, 7, 2),
    );
    expect(note.type, NarratorNoteType.reflection);
    expect(note.data['response'], 'life happened');
    expect(note.habitId, isNull);
  });

  test('NarratorAppearance holds shell text and two buttons', () {
    final appearance = NarratorAppearance(
      trigger: NarratorTrigger.streakBreakFirstMiss,
      shellText: 'You missed yesterday.',
      buttonA: 'Life happened',
      buttonB: 'It felt too hard',
    );
    expect(appearance.shellText, 'You missed yesterday.');
    expect(appearance.buttonA, 'Life happened');
    expect(appearance.slotKeys, isEmpty);
  });
}
```

- [ ] **Step 1.2: Run — expect compile error**

```bash
flutter test test/features/narrator/domain/models/narrator_models_test.dart
```

- [ ] **Step 1.3: Create `NarratorTrigger` enum**

```dart
// lib/features/narrator/domain/models/narrator_trigger.dart

/// The 12 moments at which the Narrator may appear.
/// Priority (highest first): longAbsence, levelUp, streakBreakFirstMiss,
/// onFireState, weeklyRecap, morningBriefEarlyDays, screenFirstVisit,
/// nodeFirstVisit, eveningReflection, dailyInsight, newHabitCreation,
/// onboardingPostArchetype.
enum NarratorTrigger {
  /// Fired once after the user selects their archetype in onboarding.
  onboardingPostArchetype,

  /// Fired on morning opens during the first 3 days of app use.
  morningBriefEarlyDays,

  /// Fired when the user first misses a habit after a streak.
  streakBreakFirstMiss,

  /// Fired when momentumScore crosses into onFire (>= 90) for the first time.
  onFireState,

  /// Fired immediately after a level-up event.
  levelUp,

  /// Fired on Sunday evenings (>= 17:00).
  weeklyRecap,

  /// Fired when the user returns after 5+ days with no app open.
  longAbsence,

  /// Fired when the user saves a new habit.
  newHabitCreation,

  /// Fired on the FIRST visit to any named route. Passes the route as context.
  /// Replaces FeatureCoachMark across all 14 screens.
  screenFirstVisit,

  /// Fired on the first visit to a level/node in the World Map.
  /// Replaces the Node Guide AlertDialog.
  nodeFirstVisit,

  /// Fired when >= 1 habit is completed today AND time >= 18:00,
  /// OR when all habits are complete (any time).
  /// Replaces ReflectionCard.
  eveningReflection,

  /// Fired when the user taps "Hear more" on the NarratorSummaryCard.
  /// Replaces the AiCoachCard's AI insight display.
  dailyInsight,
}
```

- [ ] **Step 1.4: Create `NarratorNote`**

```dart
// lib/features/narrator/domain/models/narrator_note.dart

enum NarratorNoteType {
  completionTime,    // When habits are completed during the day
  missPattern,       // Which habits are skipped and when
  streakRecovery,    // How user responds to recovery prompts
  questionResponse,  // Which action button user tapped in any Narrator appearance
  sessionLength,     // Duration of each app session
  openTrigger,       // What caused the app to open
  screenVisited,     // Which route was visited for the first time
  nodeVisited,       // Which world node was visited for the first time
  reflection,        // User's evening reflection response
  aiInsight,         // The last AI insight shown in NarratorSummaryCard
}

class NarratorNote {
  final String id;
  final NarratorNoteType type;
  final Map<String, dynamic> data;
  final DateTime recordedAt;
  final String? habitId; // null for non-habit notes

  const NarratorNote({
    required this.id,
    required this.type,
    required this.data,
    required this.recordedAt,
    this.habitId,
  });
}
```

- [ ] **Step 1.5: Create `NarratorAppearance`**

```dart
// lib/features/narrator/domain/models/narrator_appearance.dart
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';

/// Describes a single Narrator appearance:
/// [shellText] renders immediately (from local template).
/// [slotKeys] are placeholders like '[SLOT: archetype_trait]' that get
/// filled asynchronously by the Groq Cloud Function.
/// [buttonA] and [buttonB] are the two action buttons (always exactly 2).
/// [hasTextField] is true only for eveningReflection.
class NarratorAppearance {
  final NarratorTrigger trigger;
  final String shellText;
  final String buttonA;
  final String buttonB;
  final List<String> slotKeys;
  final bool hasTextField;
  final Map<String, dynamic> context;

  const NarratorAppearance({
    required this.trigger,
    required this.shellText,
    required this.buttonA,
    required this.buttonB,
    this.slotKeys = const [],
    this.hasTextField = false,
    this.context = const {},
  });
}
```

- [ ] **Step 1.6: Run — expect green**

```bash
flutter test test/features/narrator/domain/models/narrator_models_test.dart
```

- [ ] **Step 1.7: Commit**

```bash
git add lib/features/narrator/domain/models/
git add test/features/narrator/domain/models/narrator_models_test.dart
git commit -m "feat(narrator): add NarratorTrigger, NarratorNote, NarratorAppearance models"
```

---

## Task 2: `NarratorTriggerEngine` — pure function

**Files:**
- Create: `lib/features/narrator/domain/services/narrator_trigger_engine.dart`
- Test: `test/features/narrator/domain/services/narrator_trigger_engine_test.dart`

### Background
This is the most important class in the Narrator system. It is a **pure function** — no Firebase, no Riverpod, no Flutter imports. It takes data structs and returns a decision. This means it is fast, deterministic, and unit-testable without any mocks.

`screenFirstVisit` and `nodeFirstVisit` bypass the 4-hour cooldown — they fire exactly once per screen/node lifetime and are recorded as `NarratorNote.screenVisited` / `NarratorNote.nodeVisited`.

- [ ] **Step 2.1: Define `AppOpenContext` data struct**

Add to `lib/features/narrator/domain/services/narrator_trigger_engine.dart`:

```dart
// lib/features/narrator/domain/services/narrator_trigger_engine.dart
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';

/// Immutable snapshot of why/when the app was opened.
class AppOpenContext {
  final String currentRoute;    // e.g. '/timeline', '/world/node/1'
  final DateTime now;
  final bool isFirstAppOpen;    // true only on the very first ever open
  final int daysSinceInstall;
  final int daysSinceLastOpen;  // 0 = opened today already

  const AppOpenContext({
    required this.currentRoute,
    required this.now,
    required this.isFirstAppOpen,
    required this.daysSinceInstall,
    required this.daysSinceLastOpen,
  });
}

/// Immutable snapshot of the user's current stats.
class NarratorUserStats {
  final int momentumScore;        // 0–100
  final int consecutiveActiveDays;
  final int totalHabitsToday;
  final int completedHabitsToday;
  final int currentLevel;
  final bool justLeveledUp;       // true if level changed this session
  final String archetype;         // e.g. 'Athlete', 'Scholar'
  final String firstName;
  final bool onboardingComplete;
  final int weekNumber;           // ISO week of year

  const NarratorUserStats({
    required this.momentumScore,
    required this.consecutiveActiveDays,
    required this.totalHabitsToday,
    required this.completedHabitsToday,
    required this.currentLevel,
    required this.justLeveledUp,
    required this.archetype,
    required this.firstName,
    required this.onboardingComplete,
    required this.weekNumber,
  });
}
```

- [ ] **Step 2.2: Write failing tests**

```dart
// test/features/narrator/domain/services/narrator_trigger_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';

void main() {
  // Helper: builds a baseline stats object (all safe defaults)
  NarratorUserStats _stats({
    int momentumScore = 50,
    int consecutiveActiveDays = 3,
    int totalHabitsToday = 3,
    int completedHabitsToday = 1,
    int currentLevel = 2,
    bool justLeveledUp = false,
    String archetype = 'Scholar',
    String firstName = 'Jay',
    bool onboardingComplete = true,
    int weekNumber = 27,
  }) => NarratorUserStats(
    momentumScore: momentumScore,
    consecutiveActiveDays: consecutiveActiveDays,
    totalHabitsToday: totalHabitsToday,
    completedHabitsToday: completedHabitsToday,
    currentLevel: currentLevel,
    justLeveledUp: justLeveledUp,
    archetype: archetype,
    firstName: firstName,
    onboardingComplete: onboardingComplete,
    weekNumber: weekNumber,
  );

  // Helper: builds a baseline open context
  AppOpenContext _ctx({
    String route = '/timeline',
    DateTime? now,
    bool isFirstAppOpen = false,
    int daysSinceInstall = 10,
    int daysSinceLastOpen = 0,
  }) => AppOpenContext(
    currentRoute: route,
    now: now ?? DateTime(2026, 7, 6, 9, 0), // Monday 9 AM
    isFirstAppOpen: isFirstAppOpen,
    daysSinceInstall: daysSinceInstall,
    daysSinceLastOpen: daysSinceLastOpen,
  );

  group('longAbsence', () {
    test('fires when daysSinceLastOpen >= 5', () {
      final trigger = NarratorTriggerEngine.shouldTrigger(
        stats: _stats(),
        context: _ctx(daysSinceLastOpen: 5),
        recentNotes: [],
      );
      expect(trigger, NarratorTrigger.longAbsence);
    });

    test('does NOT fire when daysSinceLastOpen < 5', () {
      final trigger = NarratorTriggerEngine.shouldTrigger(
        stats: _stats(),
        context: _ctx(daysSinceLastOpen: 4),
        recentNotes: [],
      );
      expect(trigger, isNot(NarratorTrigger.longAbsence));
    });
  });

  group('levelUp', () {
    test('fires when justLeveledUp is true', () {
      final trigger = NarratorTriggerEngine.shouldTrigger(
        stats: _stats(justLeveledUp: true),
        context: _ctx(),
        recentNotes: [],
      );
      expect(trigger, NarratorTrigger.levelUp);
    });
  });

  group('onFireState', () {
    test('fires when momentumScore >= 90 and not recently shown', () {
      final trigger = NarratorTriggerEngine.shouldTrigger(
        stats: _stats(momentumScore: 90),
        context: _ctx(),
        recentNotes: [],
      );
      expect(trigger, NarratorTrigger.onFireState);
    });

    test('does NOT fire if onFireState appeared in last 4 hours', () {
      final recentNote = NarratorNote(
        id: 'n1',
        type: NarratorNoteType.questionResponse,
        data: {'trigger': 'onFireState'},
        recordedAt: DateTime(2026, 7, 6, 7, 0), // 2 hours ago (now is 9 AM)
      );
      final trigger = NarratorTriggerEngine.shouldTrigger(
        stats: _stats(momentumScore: 95),
        context: _ctx(now: DateTime(2026, 7, 6, 9, 0)),
        recentNotes: [recentNote],
      );
      expect(trigger, isNot(NarratorTrigger.onFireState));
    });
  });

  group('weeklyRecap', () {
    test('fires on Sunday at or after 17:00', () {
      // DateTime(2026, 7, 5) is a Sunday
      final trigger = NarratorTriggerEngine.shouldTrigger(
        stats: _stats(),
        context: _ctx(now: DateTime(2026, 7, 5, 17, 0)),
        recentNotes: [],
      );
      expect(trigger, NarratorTrigger.weeklyRecap);
    });

    test('does NOT fire on Sunday before 17:00', () {
      final trigger = NarratorTriggerEngine.shouldTrigger(
        stats: _stats(),
        context: _ctx(now: DateTime(2026, 7, 5, 16, 59)),
        recentNotes: [],
      );
      expect(trigger, isNot(NarratorTrigger.weeklyRecap));
    });

    test('does NOT fire on non-Sunday', () {
      // DateTime(2026, 7, 6) is Monday
      final trigger = NarratorTriggerEngine.shouldTrigger(
        stats: _stats(),
        context: _ctx(now: DateTime(2026, 7, 6, 18, 0)),
        recentNotes: [],
      );
      expect(trigger, isNot(NarratorTrigger.weeklyRecap));
    });
  });

  group('morningBriefEarlyDays', () {
    test('fires on morning open within first 7 days of install', () {
      final trigger = NarratorTriggerEngine.shouldTrigger(
        stats: _stats(),
        context: _ctx(
          now: DateTime(2026, 7, 6, 8, 0),
          daysSinceInstall: 3,
        ),
        recentNotes: [],
      );
      expect(trigger, NarratorTrigger.morningBriefEarlyDays);
    });

    test('does NOT fire after day 7', () {
      final trigger = NarratorTriggerEngine.shouldTrigger(
        stats: _stats(),
        context: _ctx(
          now: DateTime(2026, 7, 6, 8, 0),
          daysSinceInstall: 8,
        ),
        recentNotes: [],
      );
      expect(trigger, isNot(NarratorTrigger.morningBriefEarlyDays));
    });
  });

  group('screenFirstVisit', () {
    test('fires when route has never been recorded in notes', () {
      final trigger = NarratorTriggerEngine.shouldTrigger(
        stats: _stats(),
        context: _ctx(route: '/social'),
        recentNotes: [], // no screenVisited notes
      );
      expect(trigger, NarratorTrigger.screenFirstVisit);
    });

    test('does NOT fire when route already recorded', () {
      final note = NarratorNote(
        id: 'n1',
        type: NarratorNoteType.screenVisited,
        data: {'route': '/social'},
        recordedAt: DateTime(2026, 7, 1),
      );
      final trigger = NarratorTriggerEngine.shouldTrigger(
        stats: _stats(),
        context: _ctx(route: '/social'),
        recentNotes: [note],
      );
      expect(trigger, isNot(NarratorTrigger.screenFirstVisit));
    });

    test('does NOT fire for /timeline (always visited)', () {
      // /timeline is the home tab — skip its first-visit trigger
      final trigger = NarratorTriggerEngine.shouldTrigger(
        stats: _stats(),
        context: _ctx(route: '/timeline'),
        recentNotes: [],
      );
      expect(trigger, isNot(NarratorTrigger.screenFirstVisit));
    });
  });

  group('priority ordering', () {
    test('longAbsence beats screenFirstVisit', () {
      final trigger = NarratorTriggerEngine.shouldTrigger(
        stats: _stats(),
        context: _ctx(route: '/social', daysSinceLastOpen: 6),
        recentNotes: [],
      );
      expect(trigger, NarratorTrigger.longAbsence);
    });

    test('returns null when no trigger conditions met and cooldown active', () {
      // All habits done, momentum fine, been open today, not Sunday
      final recentNote = NarratorNote(
        id: 'n1',
        type: NarratorNoteType.questionResponse,
        data: {'trigger': 'dailyInsight'},
        recordedAt: DateTime(2026, 7, 6, 8, 30), // 30 min ago
      );
      final trigger = NarratorTriggerEngine.shouldTrigger(
        stats: _stats(momentumScore: 50, justLeveledUp: false),
        context: _ctx(
          route: '/timeline',
          now: DateTime(2026, 7, 6, 9, 0),
          daysSinceLastOpen: 0,
          daysSinceInstall: 10,
        ),
        recentNotes: [recentNote],
      );
      // /timeline is excluded from screenFirstVisit, no other triggers apply
      expect(trigger, isNull);
    });
  });
}
```

- [ ] **Step 2.3: Run — expect compile error**

```bash
flutter test test/features/narrator/domain/services/narrator_trigger_engine_test.dart
```

- [ ] **Step 2.4: Implement `NarratorTriggerEngine`**

```dart
// lib/features/narrator/domain/services/narrator_trigger_engine.dart
// (AppOpenContext and NarratorUserStats already defined above — keep in same file)

class NarratorTriggerEngine {
  /// Routes that never trigger screenFirstVisit (they are always "home" routes).
  static const _excludedFromFirstVisit = {'/timeline', '/'};

  /// Cooldown period between most Narrator appearances.
  static const _cooldown = Duration(hours: 4);

  /// Pure function — no side effects, no async, no framework dependencies.
  /// Returns the highest-priority trigger that applies, or null if none.
  static NarratorTrigger? shouldTrigger({
    required NarratorUserStats stats,
    required AppOpenContext context,
    required List<NarratorNote> recentNotes,
  }) {
    // 1. Long absence (highest priority — always fires regardless of cooldown)
    if (context.daysSinceLastOpen >= 5) {
      return NarratorTrigger.longAbsence;
    }

    // 2. Level up (fires once per session)
    if (stats.justLeveledUp && !_recentlyFired(recentNotes, 'levelUp', context.now)) {
      return NarratorTrigger.levelUp;
    }

    // 3. Streak break (first miss)
    // Detected externally — caller passes streakBreakFirstMiss directly
    // via a separate entry point: shouldTriggerOnStreakBreak()

    // 4. On Fire state
    if (stats.momentumScore >= 90 &&
        !_recentlyFired(recentNotes, 'onFireState', context.now)) {
      return NarratorTrigger.onFireState;
    }

    // 5. Weekly recap — Sunday >= 17:00
    if (context.now.weekday == DateTime.sunday &&
        context.now.hour >= 17 &&
        !_recentlyFired(recentNotes, 'weeklyRecap', context.now)) {
      return NarratorTrigger.weeklyRecap;
    }

    // 6. Morning brief (days 1–7 of install, morning open 5:00–11:00)
    if (context.daysSinceInstall <= 7 &&
        context.now.hour >= 5 &&
        context.now.hour < 12 &&
        !_recentlyFired(recentNotes, 'morningBriefEarlyDays', context.now)) {
      return NarratorTrigger.morningBriefEarlyDays;
    }

    // 7. Screen first visit (exempt from cooldown — fires once per route lifetime)
    if (!_excludedFromFirstVisit.contains(context.currentRoute) &&
        !_routeAlreadyVisited(recentNotes, context.currentRoute)) {
      return NarratorTrigger.screenFirstVisit;
    }

    // 8. Node first visit (exempt from cooldown)
    if (context.currentRoute.startsWith('/world/node/') &&
        !_nodeAlreadyVisited(recentNotes, context.currentRoute)) {
      return NarratorTrigger.nodeFirstVisit;
    }

    // 9. Evening reflection (>= 18:00, at least 1 habit done, not already logged today)
    if (context.now.hour >= 18 &&
        stats.completedHabitsToday >= 1 &&
        !_reflectionLoggedToday(recentNotes, context.now)) {
      return NarratorTrigger.eveningReflection;
    }

    // No trigger applies
    return null;
  }

  /// Separate entry point for streak-break detection
  /// (called from HabitCompletionService after a miss is recorded).
  static NarratorTrigger? shouldTriggerOnStreakBreak({
    required List<NarratorNote> recentNotes,
    required DateTime now,
  }) {
    if (!_recentlyFired(recentNotes, 'streakBreakFirstMiss', now)) {
      return NarratorTrigger.streakBreakFirstMiss;
    }
    return null;
  }

  // ── Private helpers ───────────────────────────────────────────────

  static bool _recentlyFired(
    List<NarratorNote> notes,
    String triggerName,
    DateTime now,
  ) {
    return notes.any((n) =>
        n.type == NarratorNoteType.questionResponse &&
        n.data['trigger'] == triggerName &&
        now.difference(n.recordedAt) < _cooldown);
  }

  static bool _routeAlreadyVisited(List<NarratorNote> notes, String route) {
    return notes.any((n) =>
        n.type == NarratorNoteType.screenVisited &&
        n.data['route'] == route);
  }

  static bool _nodeAlreadyVisited(List<NarratorNote> notes, String route) {
    return notes.any((n) =>
        n.type == NarratorNoteType.nodeVisited &&
        n.data['route'] == route);
  }

  static bool _reflectionLoggedToday(List<NarratorNote> notes, DateTime now) {
    return notes.any((n) =>
        n.type == NarratorNoteType.reflection &&
        n.recordedAt.year == now.year &&
        n.recordedAt.month == now.month &&
        n.recordedAt.day == now.day);
  }
}
```

- [ ] **Step 2.5: Run — expect green**

```bash
flutter test test/features/narrator/domain/services/narrator_trigger_engine_test.dart
```

- [ ] **Step 2.6: Commit**

```bash
git add lib/features/narrator/domain/services/narrator_trigger_engine.dart
git add test/features/narrator/domain/services/narrator_trigger_engine_test.dart
git commit -m "feat(narrator): add NarratorTriggerEngine pure function (12 triggers)"
```

---

## Task 3: Drift table for `NarratorNote`

**Files:**
- Modify: `lib/core/drift/app_database.dart`
- Modify: `lib/core/drift/app_database.g.dart` (regenerated — do not hand-edit)

- [ ] **Step 3.1: Read the existing Drift table pattern**

Open `lib/core/drift/app_database.dart`. Find one existing table class (e.g., `HabitsTable`) and study the pattern: `@DataClassName`, column definitions, and how the table is listed in `@DriftDatabase(tables: [...])`.

- [ ] **Step 3.2: Add `NarratorNotesTable`**

In `lib/core/drift/app_database.dart`, add the new table class **before** the `@DriftDatabase` annotation:

```dart
/// Drift table for locally-stored Narrator observations.
/// Synced to Firestore on premium accounts only.
@DataClassName('NarratorNoteData')
class NarratorNotesTable extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // NarratorNoteType.name
  TextColumn get dataJson => text()(); // JSON-encoded Map<String, dynamic>
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get habitId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 3.3: Register the table**

In the `@DriftDatabase(tables: [...])` annotation, add `NarratorNotesTable`:

```dart
@DriftDatabase(tables: [
  // ... existing tables ...
  NarratorNotesTable,
])
class AppDatabase extends _$AppDatabase {
  // ...
}
```

- [ ] **Step 3.4: Regenerate**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/core/drift/app_database.g.dart` is regenerated with no errors.

- [ ] **Step 3.5: Commit**

```bash
git add lib/core/drift/app_database.dart
git add lib/core/drift/app_database.g.dart
git commit -m "feat(drift): add NarratorNotesTable"
```

---

## Task 4: `NarratorRepository`

**Files:**
- Create: `lib/features/narrator/data/datasources/narrator_local_datasource.dart`
- Create: `lib/features/narrator/data/repositories/narrator_repository.dart`
- Test: `test/features/narrator/data/repositories/narrator_repository_test.dart`

- [ ] **Step 4.1: Create the local datasource**

```dart
// lib/features/narrator/data/datasources/narrator_local_datasource.dart
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';

class NarratorLocalDatasource {
  final AppDatabase _db;
  const NarratorLocalDatasource(this._db);

  Future<void> insertNote(NarratorNote note) async {
    await _db.into(_db.narratorNotesTable).insert(
      NarratorNotesTableCompanion.insert(
        id: note.id,
        type: note.type.name,
        dataJson: jsonEncode(note.data),
        recordedAt: note.recordedAt,
        habitId: Value(note.habitId),
      ),
    );
  }

  Future<List<NarratorNote>> getRecentNotes({int limitDays = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: limitDays));
    final rows = await (_db.select(_db.narratorNotesTable)
          ..where((t) => t.recordedAt.isBiggerThanValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
        .get();
    return rows.map(_rowToNote).toList();
  }

  Future<void> clearOlderThan(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    await (_db.delete(_db.narratorNotesTable)
          ..where((t) => t.recordedAt.isSmallerThanValue(cutoff)))
        .go();
  }

  NarratorNote _rowToNote(NarratorNoteData row) {
    return NarratorNote(
      id: row.id,
      type: NarratorNoteType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => NarratorNoteType.questionResponse,
      ),
      data: Map<String, dynamic>.from(jsonDecode(row.dataJson) as Map),
      recordedAt: row.recordedAt,
      habitId: row.habitId,
    );
  }
}
```

- [ ] **Step 4.2: Create the repository**

```dart
// lib/features/narrator/data/repositories/narrator_repository.dart
import 'package:emerge_app/features/narrator/data/datasources/narrator_local_datasource.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';

class NarratorRepository {
  final NarratorLocalDatasource _local;
  const NarratorRepository(this._local);

  Future<void> saveNote(NarratorNote note) => _local.insertNote(note);

  Future<List<NarratorNote>> getRecentNotes() => _local.getRecentNotes();

  /// Call during app startup to clean up notes older than 30 days.
  Future<void> pruneOldNotes() => _local.clearOlderThan(30);
}
```

- [ ] **Step 4.3: Commit**

```bash
git add lib/features/narrator/data/
git commit -m "feat(narrator): add NarratorLocalDatasource and NarratorRepository"
```

---

## Task 5: Riverpod providers for Narrator

**Files:**
- Create: `lib/features/narrator/presentation/providers/narrator_providers.dart`

- [ ] **Step 5.1: Create providers**

```dart
// lib/features/narrator/presentation/providers/narrator_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/features/narrator/data/datasources/narrator_local_datasource.dart';
import 'package:emerge_app/features/narrator/data/repositories/narrator_repository.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';

part 'narrator_providers.g.dart';

@Riverpod(keepAlive: true)
NarratorRepository narratorRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider); // use whatever your DB provider is named
  return NarratorRepository(NarratorLocalDatasource(db));
}

@riverpod
Future<List<NarratorNote>> recentNarratorNotes(Ref ref) {
  return ref.watch(narratorRepositoryProvider).getRecentNotes();
}

/// Holds the currently-active Narrator trigger.
/// null = Narrator is not showing.
/// Set by NarratorStateNotifier.show() and cleared by .dismiss().
@riverpod
class NarratorStateNotifier extends _$NarratorStateNotifier {
  @override
  NarratorTrigger? build() => null;

  void show(NarratorTrigger trigger) => state = trigger;
  void dismiss() => state = null;
}
```

- [ ] **Step 5.2: Regenerate**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5.3: Commit**

```bash
git add lib/features/narrator/presentation/providers/
git commit -m "feat(narrator): add Riverpod providers (NarratorStateNotifier)"
```

---

## Task 6: Narrator UI widgets

**Files:**
- Create: `lib/features/narrator/presentation/widgets/narrator_pulse_indicator.dart`
- Create: `lib/features/narrator/presentation/widgets/narrator_typewriter.dart`
- Create: `lib/features/narrator/presentation/widgets/narrator_sheet.dart`
- Test: `test/features/narrator/presentation/widgets/narrator_typewriter_test.dart`

- [ ] **Step 6.1: Write typewriter test**

```dart
// test/features/narrator/presentation/widgets/narrator_typewriter_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_typewriter.dart';

void main() {
  testWidgets('NarratorTypewriter starts empty and reveals text over time', (tester) async {
    bool completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NarratorTypewriter(
            text: 'Hello.',
            color: Colors.white,
            onComplete: () => completed = true,
          ),
        ),
      ),
    );

    // At start: text widget exists but text is empty
    expect(find.text(''), findsOneWidget);

    // Advance time: 'H' appears after first character delay (~36ms)
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('H'), findsOneWidget);

    // Advance past the full text + period pause (text='Hello.' ~250ms for period)
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Hello.'), findsOneWidget);

    // onComplete fires after all characters revealed
    await tester.pump(const Duration(milliseconds: 400));
    expect(completed, isTrue);
  });
}
```

- [ ] **Step 6.2: Run — expect compile error**

```bash
flutter test test/features/narrator/presentation/widgets/narrator_typewriter_test.dart
```

- [ ] **Step 6.3: Create `NarratorPulseIndicator`**

```dart
// lib/features/narrator/presentation/widgets/narrator_pulse_indicator.dart
import 'dart:math';
import 'package:flutter/material.dart';

/// Animated ◐ symbol that pulses in the archetype color.
class NarratorPulseIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const NarratorPulseIndicator({
    super.key,
    required this.color,
    this.size = 20,
  });

  @override
  State<NarratorPulseIndicator> createState() => _NarratorPulseIndicatorState();
}

class _NarratorPulseIndicatorState extends State<NarratorPulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _HalfCirclePainter(
          color: widget.color,
          progress: _controller.value,
        ),
      ),
    );
  }
}

class _HalfCirclePainter extends CustomPainter {
  final Color color;
  final double progress;
  _HalfCirclePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final opacity = (0.4 + 0.6 * (sin(progress * 2 * pi) + 1) / 2).clamp(0.4, 1.0);
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    // Draw left half-circle (◐)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi / 2,
      pi,
      false,
      paint,
    );
    // Draw circle outline
    canvas.drawCircle(center, radius, Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_HalfCirclePainter old) => old.progress != progress;
}
```

- [ ] **Step 6.4: Create `NarratorTypewriter`**

```dart
// lib/features/narrator/presentation/widgets/narrator_typewriter.dart
import 'dart:async';
import 'package:flutter/material.dart';

/// Reveals text character-by-character with natural rhythm.
/// Pauses at sentence endings for a human-like storytelling feel.
class NarratorTypewriter extends StatefulWidget {
  final String text;
  final Color color;
  final TextStyle? style;
  final VoidCallback? onComplete;

  const NarratorTypewriter({
    super.key,
    required this.text,
    required this.color,
    this.style,
    this.onComplete,
  });

  @override
  State<NarratorTypewriter> createState() => _NarratorTypewriterState();
}

class _NarratorTypewriterState extends State<NarratorTypewriter> {
  String _displayed = '';
  int _index = 0;
  Timer? _timer;

  static const _baseMs = 28;

  // Returns how many milliseconds to wait AFTER revealing the character at [index].
  int _delayFor(String text, int index) {
    if (index >= text.length) return _baseMs;
    final ch = text[index];
    if (ch == '.') return 250;
    if (ch == '!') return 200;
    if (ch == '?') return 300;
    if (ch == ',') return 100;
    if (ch == '\n') return 150;
    // Slight randomness: alternate between 24ms and 32ms
    return index.isEven ? 24 : 32;
  }

  void _next() {
    if (!mounted) return;
    if (_index >= widget.text.length) {
      widget.onComplete?.call();
      return;
    }
    setState(() {
      _displayed = widget.text.substring(0, _index + 1);
      _index++;
    });
    _timer = Timer(Duration(milliseconds: _delayFor(widget.text, _index - 1)), _next);
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 200), _next); // small initial pause
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayed,
      style: widget.style ??
          TextStyle(
            color: widget.color,
            fontSize: 15,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
    );
  }
}
```

- [ ] **Step 6.5: Create `NarratorSheet`**

```dart
// lib/features/narrator/presentation/widgets/narrator_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_pulse_indicator.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_typewriter.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:uuid/uuid.dart';

/// Shows the Narrator bottom sheet for the given [appearance].
/// Handles: typewriter text, optional text field (eveningReflection only),
/// two action buttons that fade in after text completes, swipe to dismiss.
Future<void> showNarratorSheet(
  BuildContext context,
  WidgetRef ref, {
  required NarratorAppearance appearance,
  required Color archetypeColor,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _NarratorSheetContent(
      appearance: appearance,
      archetypeColor: archetypeColor,
      ref: ref,
    ),
  );
}

class _NarratorSheetContent extends StatefulWidget {
  final NarratorAppearance appearance;
  final Color archetypeColor;
  final WidgetRef ref;

  const _NarratorSheetContent({
    required this.appearance,
    required this.archetypeColor,
    required this.ref,
  });

  @override
  State<_NarratorSheetContent> createState() => _NarratorSheetContentState();
}

class _NarratorSheetContentState extends State<_NarratorSheetContent> {
  bool _buttonsVisible = false;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onTextComplete() {
    if (mounted) setState(() => _buttonsVisible = true);
  }

  void _handleButton(String buttonLabel) {
    // Record NarratorNote
    final note = NarratorNote(
      id: const Uuid().v4(),
      type: widget.appearance.trigger == NarratorTrigger.eveningReflection
          ? NarratorNoteType.reflection
          : NarratorNoteType.questionResponse,
      data: {
        'trigger': widget.appearance.trigger.name,
        'response': buttonLabel,
        if (_noteController.text.isNotEmpty) 'note': _noteController.text,
      },
      recordedAt: DateTime.now(),
    );
    widget.ref.read(narratorRepositoryProvider).saveNote(note);
    widget.ref.read(narratorStateNotifierProvider.notifier).dismiss();
    Navigator.of(context).pop(buttonLabel);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.80,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.4),
            BlendMode.darken,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header: pulse indicator + EMERGE label
                  Row(
                    children: [
                      NarratorPulseIndicator(
                        color: widget.archetypeColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'EMERGE',
                        style: TextStyle(
                          color: widget.archetypeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 1,
                    color: widget.archetypeColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 20),

                  // Typewriter text
                  NarratorTypewriter(
                    text: widget.appearance.shellText,
                    color: Colors.white,
                    onComplete: _onTextComplete,
                  ),

                  // Optional text field (eveningReflection only)
                  if (widget.appearance.hasTextField) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'What actually happened today?',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.archetypeColor,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ],

                  // Action buttons — fade in after text completes
                  const SizedBox(height: 28),
                  AnimatedOpacity(
                    opacity: _buttonsVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _NarratorButton(
                          label: widget.appearance.buttonA,
                          color: widget.archetypeColor,
                          filled: true,
                          onTap: () => _handleButton(widget.appearance.buttonA),
                        ),
                        const SizedBox(height: 10),
                        _NarratorButton(
                          label: widget.appearance.buttonB,
                          color: widget.archetypeColor,
                          filled: false,
                          onTap: () => _handleButton(widget.appearance.buttonB),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NarratorButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _NarratorButton({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: filled ? 0 : 0.5)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: filled ? Colors.black : color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6.6: Run typewriter test — expect green**

```bash
flutter test test/features/narrator/presentation/widgets/narrator_typewriter_test.dart
```

- [ ] **Step 6.7: Commit**

```bash
git add lib/features/narrator/presentation/widgets/
git add test/features/narrator/presentation/widgets/
git commit -m "feat(narrator): add NarratorPulseIndicator, NarratorTypewriter, NarratorSheet"
```

---

## Task 7: `NarratorSummaryCard` (replaces `AiCoachCard` in Timeline)

**Files:**
- Create: `lib/features/narrator/presentation/widgets/narrator_summary_card.dart`
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

### What this does
`NarratorSummaryCard` is always visible in Timeline where `AiCoachCard` was. It reads from the local `NarratorNote` cache — zero API latency, no skeleton loader. Tapping "Hear more" opens the Narrator sheet with `dailyInsight`. Tapping "Add a habit" navigates to `/timeline/create-habit`.

- [ ] **Step 7.1: Create `NarratorSummaryCard`**

```dart
// lib/features/narrator/presentation/widgets/narrator_summary_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_pulse_indicator.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_sheet.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:go_router/go_router.dart';

class NarratorSummaryCard extends ConsumerWidget {
  final Color archetypeColor;

  const NarratorSummaryCard({
    super.key,
    this.archetypeColor = EmergeColors.teal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(recentNarratorNotesProvider);

    final insightText = notesAsync.when(
      data: (notes) {
        final insightNote = notes
            .where((n) => n.type == NarratorNoteType.aiInsight)
            .firstOrNull;
        return insightNote?.data['text'] as String? ??
            "I'm watching how you work. Check back after your first habit.";
      },
      loading: () =>
          "I'm watching how you work. Check back after your first habit.",
      error: (_, __) => "Focus on one small win today.",
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassmorphismCard(
        glowColor: archetypeColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                NarratorPulseIndicator(color: archetypeColor, size: 16),
                const SizedBox(width: 10),
                Text(
                  'EMERGE',
                  style: TextStyle(
                    color: archetypeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Insight text
            Text(
              insightText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _SummaryButton(
                    label: 'Hear more',
                    color: archetypeColor,
                    filled: true,
                    onTap: () => _openDailyInsight(context, ref),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryButton(
                    label: 'Add a habit',
                    color: archetypeColor,
                    filled: false,
                    onTap: () => context.push('/timeline/create-habit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDailyInsight(BuildContext context, WidgetRef ref) {
    ref.read(narratorStateNotifierProvider.notifier).show(NarratorTrigger.dailyInsight);
    showNarratorSheet(
      context,
      ref,
      appearance: const NarratorAppearance(
        trigger: NarratorTrigger.dailyInsight,
        shellText:
            "Here's what I've been noticing.\n\n"
            "You complete habits more consistently in the morning. "
            "Evening sessions are where momentum stalls.\n\n"
            "One shift: move your hardest habit to before 10 AM.",
        buttonA: "I'll try that",
        buttonB: "Show me my patterns",
      ),
      archetypeColor: archetypeColor,
    );
  }
}

class _SummaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _SummaryButton({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7.2: Swap `AiCoachCard` for `NarratorSummaryCard` in Timeline**

In `lib/features/timeline/presentation/screens/timeline_screen.dart`:

**Remove** lines 404–466 (the entire `ref.watch(isPremiumProvider).when(...)` block that renders `AiCoachCard`).

**Remove** these imports (lines ~18–19):
```dart
import 'package:emerge_app/features/timeline/presentation/widgets/ai_coach_card.dart';
```

**Add** this import at the top:
```dart
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_summary_card.dart';
```

**Add** this `SliverToBoxAdapter` where the `AiCoachCard` block was:
```dart
SliverToBoxAdapter(
  child: NarratorSummaryCard(
    archetypeColor: EmergeColors.teal, // TODO: pass user's archetype color
  ),
),
```

- [ ] **Step 7.3: Remove `ReflectionCard` from Timeline**

**Remove** lines 471–475 (the `ReflectionCard` sliver):
```dart
SliverToBoxAdapter(
  child: ReflectionCard(
    onLogReflection: (value, note) => _saveReflection(value, note),
  ),
),
```

**Remove** the import:
```dart
import 'package:emerge_app/features/timeline/presentation/widgets/reflection_card.dart';
```

**Remove** the `_saveReflection` method (lines ~768–799 in the original) — this data now flows through `NarratorRepository.saveNote()` inside the Narrator sheet.

**Remove** the `FeatureCoachMark` block (lines 187–204) and the `_showFirstVisitGuide` state variable + its `setState` call:
```dart
// DELETE this from build():
if (_showFirstVisitGuide)
  FeatureCoachMark(
    title: "Your Timeline Command Center",
    ...
    onDismiss: () => setState(() => _showFirstVisitGuide = false),
  ),

// DELETE this state variable:
bool _showFirstVisitGuide = false;
```

**Remove** the companion provider calls in `initState()` (lines 68–79):
```dart
// DELETE:
final repo = ref.read(companionRepositoryProvider);
if (!repo.hasVisited('/timeline')) {
  repo.markVisited('/timeline');
  ref.read(companionEngineProvider.notifier).triggerEvent(...);
  setState(() => _showFirstVisitGuide = true);
}
```

**Remove** these imports from `timeline_screen.dart`:
```dart
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';
import 'package:emerge_app/core/presentation/widgets/feature_coach_mark.dart';
```

- [ ] **Step 7.4: Run and verify**

```bash
flutter run
```

Navigate to Timeline:
- [ ] `NarratorSummaryCard` appears where AiCoachCard was
- [ ] "Hear more" opens the Narrator sheet with typewriter text
- [ ] "Add a habit" navigates to habit creation
- [ ] No ReflectionCard slider below
- [ ] No coach mark overlay on first visit
- [ ] No compile errors

```bash
dart analyze lib/
```
Expected: 0 errors.

- [ ] **Step 7.5: Commit**

```bash
git add lib/features/narrator/presentation/widgets/narrator_summary_card.dart
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "feat(timeline): replace AiCoachCard + ReflectionCard with NarratorSummaryCard"
```

---

## Task 8: Replace Node Guide in `level_immersive_screen.dart`

**Files:**
- Modify: `lib/features/world_map/presentation/screens/level_immersive_screen.dart`

- [ ] **Step 8.1: Delete `_showCompanionGuide()` and `_guideRow()`**

Open the file. Delete:
- The entire `_showCompanionGuide()` method (lines 85–144)
- The entire `_guideRow()` helper (lines 146–175)
- The `ref.listen(tutorialSettingProvider, ...)` block in `build()` (lines 181–185)
- Any call to `_checkFirstNodeVisit()` that triggers `_showCompanionGuide()`

- [ ] **Step 8.2: Find where `_checkFirstNodeVisit()` is called**

Search the file for `_checkFirstNodeVisit`. Find the call site (likely in `initState` or `_buildContent`). Note what condition triggers it (first visit check).

- [ ] **Step 8.3: Add Narrator trigger in its place**

Replace the `_checkFirstNodeVisit()` call with:

```dart
// Add these imports at top of level_immersive_screen.dart:
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_sheet.dart';

// Replace _checkFirstNodeVisit() call with:
void _triggerNodeNarrator(String nodeTitle, String nodeAttribute) {
  final notes = ref.read(recentNarratorNotesProvider).value ?? [];
  final trigger = NarratorTriggerEngine.shouldTrigger(
    stats: _buildNarratorStats(), // helper below
    context: AppOpenContext(
      currentRoute: '/world/node/${widget.nodeId}',
      now: DateTime.now(),
      isFirstAppOpen: false,
      daysSinceInstall: 10, // use real value if available
      daysSinceLastOpen: 0,
    ),
    recentNotes: notes,
  );

  if (trigger == NarratorTrigger.nodeFirstVisit) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showNarratorSheet(
        context,
        ref,
        appearance: NarratorAppearance(
          trigger: NarratorTrigger.nodeFirstVisit,
          shellText:
              "You've reached the $nodeTitle.\n\n"
              "Directives here build $nodeAttribute. "
              "Every one you complete shifts this region of your world.\n\n"
              "Complete the missions. Conquer the node.\n"
              "What happens after that is worth seeing.",
          buttonA: 'Begin the node',
          buttonB: 'What does $nodeAttribute unlock',
        ),
        archetypeColor: _archetypeColor, // use your existing color variable
      );
    });
  }
}
```

> **Note:** `_archetypeColor`, `widget.nodeId`, `nodeTitle`, and `nodeAttribute` must come from the existing node data already in the screen. Read the file to find the right variable names and pass them correctly.

- [ ] **Step 8.4: Run and verify**

```bash
flutter run
```

Navigate to a World Map node for the first time:
- [ ] Narrator sheet opens with typewriter text (not the AlertDialog)
- [ ] "NODE GUIDE" AlertDialog does NOT appear

```bash
dart analyze lib/
```

- [ ] **Step 8.5: Commit**

```bash
git add lib/features/world_map/presentation/screens/level_immersive_screen.dart
git commit -m "feat(worldmap): replace Node Guide AlertDialog with Narrator nodeFirstVisit"
```

---

## Task 9: Groq Cloud Function for slot-filling

**Files:**
- Create: `functions/src/narrator.ts`
- Modify: `functions/src/index.ts`

### Background
The Narrator shell text renders instantly from local templates. The `[SLOT: ...]` placeholders are filled asynchronously by this Cloud Function using Groq. Each slot is max 15 words. The function is intentionally simple.

- [ ] **Step 9.1: Create `functions/src/narrator.ts`**

```typescript
// functions/src/narrator.ts
import * as functions from 'firebase-functions/v2/https';
import Groq from 'groq-sdk';

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

interface SlotRequest {
  trigger: string;
  slotKeys: string[];
  userContext: {
    archetype: string;
    firstName: string;
    momentumScore: number;
    completedHabitsToday: number;
    totalHabitsToday: number;
    streakDays: number;
    dominantIdentity: string;
  };
}

interface SlotResponse {
  slots: Record<string, string>;
}

export const fillNarratorSlots = functions.onCall(
  { region: 'us-central1', timeoutSeconds: 10 },
  async (request): Promise<SlotResponse> => {
    const { trigger, slotKeys, userContext } = request.data as SlotRequest;

    if (!slotKeys || slotKeys.length === 0) {
      return { slots: {} };
    }

    const prompt = `You are the Narrator of Emerge, an identity-first habit app.
Fill each slot below with ≤15 words. Identity-language only. No fluff. No generic advice.
Be specific to this user's data. Speak as a wise, observant voice.

User context:
- Archetype: ${userContext.archetype}
- First name: ${userContext.firstName}
- Momentum score: ${userContext.momentumScore}/100
- Completed today: ${userContext.completedHabitsToday}/${userContext.totalHabitsToday}
- Streak days: ${userContext.streakDays}
- Dominant identity: ${userContext.dominantIdentity}
- Trigger: ${trigger}

Slots to fill (respond with a JSON object where keys are slot names and values are ≤15-word strings):
${slotKeys.join(', ')}

Respond ONLY with valid JSON. No explanation. No markdown.`;

    const completion = await groq.chat.completions.create({
      model: 'llama3-8b-8192',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 300,
      temperature: 0.7,
    });

    const raw = completion.choices[0]?.message?.content ?? '{}';

    try {
      const parsed = JSON.parse(raw) as Record<string, string>;
      return { slots: parsed };
    } catch {
      // Fallback: return empty slots (shell text renders fine without them)
      return { slots: {} };
    }
  },
);
```

- [ ] **Step 9.2: Register in `functions/src/index.ts`**

```typescript
// Add to functions/src/index.ts:
export { fillNarratorSlots } from './narrator';
```

- [ ] **Step 9.3: Set Groq API key in Firebase**

```bash
firebase functions:secrets:set GROQ_API_KEY
# Enter your Groq API key when prompted
```

- [ ] **Step 9.4: Deploy**

```bash
firebase deploy --only functions:fillNarratorSlots
```

Expected output: function deployed successfully.

- [ ] **Step 9.5: Commit**

```bash
git add functions/src/narrator.ts functions/src/index.ts
git commit -m "feat(functions): add fillNarratorSlots Groq Cloud Function"
```

---

## Verification Checklist (Plan B Complete)

```bash
flutter test test/features/narrator/
dart analyze lib/features/narrator/
dart analyze lib/features/timeline/
dart analyze lib/features/world_map/
```

Manual checks:
- [ ] Opening Timeline: `NarratorSummaryCard` shows (no skeleton, no lock icon)
- [ ] Tapping "Hear more": Narrator sheet opens, `◐` pulses, text types out character by character, pauses at `.`
- [ ] Action buttons only appear AFTER text finishes
- [ ] Swipe down always dismisses the sheet
- [ ] Visiting a new screen (e.g., `/social`): Narrator does NOT auto-trigger (screenFirstVisit is in Plan D)
- [ ] Visiting a World Map node first time: Narrator replaces the old AlertDialog
- [ ] After 5 days of no opens (simulate by changing `daysSinceLastOpen` in test): `longAbsence` fires
- [ ] `flutter test` shows 0 failures
