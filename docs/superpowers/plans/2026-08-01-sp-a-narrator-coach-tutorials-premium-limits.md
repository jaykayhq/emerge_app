# SP-A: Narrator-as-Coach, Tutorials, Premium Limits, Settings Refresh — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fold the AI coach into the narrator (avatar tap → coach ask dialog with a 3-asks/day free quota), re-establish first-visit tutorials (node guides) on all live front-facing screens gated by `tutorialsEnabled`, and replace the legacy Settings tutorial tiles with one unified Tutorials section.

**Architecture:** Complete the half-finished narrator redesign (mount `NarratorAvatar`, wire `pendingMilestoneProvider` producers, add coach ask mode to `NarratorSheet`) using the existing `NarratorLineResolver` free/premium split. Add a pure `CoachAskQuota` (3/day, premium bypass) as the limits-framework seed. Add a small `lib/features/tutorials/` feature: a pure `NodeGuideRegistry` + a reusable `NodeGuideHost` overlay widget driven by `LocalSettingsRepository`'s existing `tutorialsEnabled` + `hasSeenNodeGuide_<nodeId>` flags. Delete the orphaned Oracle screens (`AiReflectionsScreen`, `GoldilocksScreen`) and consolidate the duplicate `GroqAiService` classes.

**Tech Stack:** Flutter 3.x, Dart 3.10+, Riverpod 3.x (annotation + codegen), drift, fpdart, shared_preferences, fake_cloud_firestore, mocktail.

**Spec:** `docs/superpowers/specs/2026-08-01-narrator-coach-tutorials-premium-limits-design.md`

---

## ✅ HANDOFF NOTE — IMPLEMENTED 2026-08-01 (all 16 tasks complete)

**Status: all tasks implemented, whole-project `dart analyze` clean, 1,002 focused tests pass. One pre-existing failure unrelated to SP-A:** `test/features/social/domain/services/tribe_membership_service_test.dart` ("joinTribe enqueues Firestore sync operations") — fails identically at HEAD (confirmed via clean worktree twice); it belongs to SP-G (tribe membership/XP accounting).

**Commits (in order):**
| Task | SHA | Summary |
|---|---|---|
| T1 | `60b6671` | CoachAskQuota pure domain (3/day, premium bypass, rollover) |
| T2 | `2082ff8e` | Node guide registry (12→11 nodes; habit_advanced dropped in T12) |
| T3 | `3344cc0d` + `280ff21a` | migrateVisitedFlags + test-isolation fix (init() guard removed) |
| T4 | `245135cc` + `25e3959b` | CoachAskQuotaController provider (rollover at consume, sync state write) |
| T5 | `4ac81527` + `a58823ae` | NodeGuideController + NodeGuideHost (+ markSeen assertion) |
| T6 | `0f4e1331` | PremiumLimitType.coachAsk + dialog copy |
| T7 | `a427dcda` + `10d755b0` + `33009a5d` | GroqAiService consolidation + test re-point + throwing contract restored |
| T8 | `cfe03f79` + `382e8efb` | NarratorSheet coach mode + _isAsking serialization |
| T9 | `a3e3c299` | NarratorAvatar in timeline header → coach dialog |
| T10 | `0f5f4654` + `391a9bff` | Milestone producers + sequencing fixes (welcome card visible) |
| T11 | `be0d425a` | Node guides: timeline/challenges/all_tribes/tribe_lobby/discover; dead stubs removed |
| T12 | `31ec85be` + `413cfd41` | Node guides: habit create/streak recovery/world map/leveling/future self; NodeGuideOverlay for coach; world-map seed fix + overlay test + docs |
| T13 | `40a9a62e` | Companion visited-flag + migration APIs removed; migrateVisitedFlags wired in init_app |
| T14 | `3155f9e7` | Unified Tutorials settings section (toggle/replay guides/replay onboarding/quota row) |
| T15 | `6b1899bc` | Oracle screens + routes deleted |
| Fix | `40e3b63c` | challenges_screen_test companion mock dropped |

**Notable deviations from the plan (all approved during review):** dispose-clear removed in identity studio (ref-in-dispose StateError; autoDispose covers it); `ProviderScope.containerOf` instead of `context.read` (Riverpod 3); `habit_advanced` node dropped (no live surface); coach guide via full-screen `NodeGuideOverlay` before the sheet (dialog can't host the expand host); `await ref.watch(isPremiumProvider.future)` pattern (watch+.value hangs in riverpod 3.3.2); tribe_lobby guide copy adjusted (CTA becomes "Switch Tribes" only in SP-D).

**Deferred notes for later sub-projects:** `test/features/gamification/.../leveling_screen_test.dart:62` has an inert `companion_visited_/gamification` prefs seed (dead data, harmless — remove in a later cleanup); remote-config `goldilocks_threshold_*` keys are inert (deleted screen) — safe to remove; manual smoke checklist (Task 16 Step 3) still needs a device run by a human.

**Final review gate (Emerge-App-Code-Reviewer, 2026-08-01): READY.** All four must-fix items resolved in T17:

| T17 commit | SHA | Summary |
|---|---|---|
| T17a | `99250d03` | App-open metadata + trigger cooldown store (LocalSettingsRepository), pure `NarratorOpenEvaluator` (timeline-open ambient triggers: longAbsence/morningBrief/streakBreak/onFire, excluding weeklyRecap/eveningReflection), migration map dropped orphan '/profile'+'/tribes', coach-guide barrier locked (barrierDismissible: false) |
| T17b | `92c27768` | Timeline-open evaluation wired (post-frame, `_hasEvaluatedOpen` guard, persisted cooldowns); real level/counts in completion producer; data-grounded coach ask context (Level/XP/archetype/streak); `resolveAskNarratorTrigger` app-called |
| T17c | `b164af1b` | Settings Tutorials section widget tests (toggle, replay tiles, quota row 2/3 + premium unlimited) |

**Final state:** `dart analyze lib test` → 0 issues; 1,027 focused tests pass; only pre-existing `tribe_membership_service_test.dart` joinTribe fails (SP-G). Model-name adaptations: `UserProfile.archetype` non-nullable (`!= UserArchetype.none`), `UserAvatarStats.streak` (not currentStreak), `avatarStats.level`/`momentumScore`/`totalXp` confirmed.

**Deferred cleanup (reviewer-noted, not blocking):** dead AI surface after Oracle deletion (`ai_service.dart`/GroqAiServiceImpl/`aiServiceProvider`, `ai_personalization_service.dart`, `get_coach_advice.dart` usecase + AiRepository/AiRepositoryImpl — only their own tests consume them) and the companion presentation layer (CompanionPanel/Overlay/InlineCard/AskMentorButton — no app consumers) — a dedicated cleanup PR. Minor: `_narratorTriggerFor` mirrors `_evaluateNarratorTrigger` — extract a shared pure function.

---



## ⚠️ Pre-flight (read first)

1. **The working tree is dirty** (pre-existing uncommitted changes across ~30 files from earlier sessions). **Commit only the files each task names** — never `git add -A` or `git add lib` wholesale.
2. **Run `dart analyze lib` before starting** to establish the baseline error count. Only SP-A-introduced errors are this plan's responsibility.
3. `NarratorAvatar`, `NarratorMilestoneCard`, `lineResolverProvider`, `PendingMilestone`, and the timeline's milestone overlay **already exist and compile**. This plan wires them up; it does not rebuild them.
4. The `narrator_notes` drift table + `daily_reflections` table already exist. No Drift schema changes in this plan.

## File structure

### New files

| Path | Responsibility |
|---|---|
| `lib/features/monetization/domain/services/coach_ask_quota.dart` | Pure daily quota (3/day, premium bypass, rollover) |
| `lib/features/monetization/presentation/providers/coach_ask_quota_provider.dart` | Riverpod controller persisting the counter in shared_prefs |
| `lib/features/tutorials/domain/node_guide_registry.dart` | Pure static registry of all node guides |
| `lib/features/tutorials/presentation/providers/node_guide_controller.dart` | Riverpod controller: `shouldShow` / `markSeen` |
| `lib/features/tutorials/presentation/widgets/node_guide_host.dart` | Reusable first-visit overlay wrapping any screen/dialog body |
| Tests mirroring each (see tasks) | TDD |

### Modified files

| Path | Change |
|---|---|
| `lib/features/onboarding/data/repositories/local_settings_repository.dart` | Add `migrateVisitedFlags()` |
| `lib/features/monetization/presentation/widgets/premium_limit_dialog.dart` | Add `PremiumLimitType.coachAsk` + copy |
| `lib/features/ai/data/services/groq_ai_service.dart` | Add `fillNarratorSlots` (kept class) |
| `lib/features/ai/data/repositories/ai_repository_impl.dart`, `lib/features/ai/domain/services/ai_personalization_service.dart`, `lib/features/narrator/presentation/providers/narrator_providers.dart` | Re-point imports to `data/services` |
| `lib/features/narrator/presentation/widgets/narrator_sheet.dart` | Coach ask mode (text field + quota + response) |
| `lib/features/narrator/presentation/providers/narrator_providers.dart` | `PendingMilestoneLine {line, trigger}` state |
| `lib/features/habits/presentation/providers/habit_providers.dart` | Compute `narratorTrigger` on completion |
| `lib/features/timeline/presentation/screens/timeline_screen.dart` | Avatar in header, coach open, producer consume, trigger-aware overlay |
| `lib/features/onboarding/presentation/screens/identity_studio_screen.dart` | `onboardingPostArchetype` milestone card + overlay host |
| `lib/features/settings/presentation/screens/settings_screen.dart` | Unified Tutorials section |
| `lib/core/router/router.dart` | Remove `reflections` + `goldilocks` routes |
| 12 screens (tasks 11–12) | Wrap in `NodeGuideHost` |
| `lib/features/social/presentation/screens/social_discover_tab.dart`, `tribe_tab_content.dart` | Replace/remove companion coach marks |
| `lib/features/companion/data/repositories/companion_repository.dart`, `lib/features/companion/presentation/providers/companion_providers.dart` | Remove visited-flag + migration APIs |
| `lib/main.dart` | Call `migrateVisitedFlags()` once after settings init |

### Deleted files

| Path | Reason |
|---|---|
| `lib/features/ai/data/datasources/groq_ai_service.dart` | Duplicate of `data/services` (after porting `fillNarratorSlots`) |
| `lib/features/ai/presentation/screens/ai_reflections_screen.dart` | Oracle folded into narrator |
| `lib/features/ai/presentation/screens/goldilocks_screen.dart` | Oracle folded into narrator |

---

# Phase 1 — Pure foundations (TDD)

## Task 1: `CoachAskQuota` pure domain + tests

**Files:**
- Create: `lib/features/monetization/domain/services/coach_ask_quota.dart`
- Test: `test/features/monetization/domain/coach_ask_quota_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/monetization/domain/services/coach_ask_quota.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoachAskQuota', () {
    test('free user starts with 3 remaining', () {
      const quota = CoachAskQuota(
        dateKey: '2026-08-01',
        usedToday: 0,
        isPremium: false,
      );
      expect(quota.canAsk, isTrue);
      expect(quota.remaining, 3);
    });

    test('free user is blocked at the daily limit', () {
      const quota = CoachAskQuota(
        dateKey: '2026-08-01',
        usedToday: 3,
        isPremium: false,
      );
      expect(quota.canAsk, isFalse);
      expect(quota.remaining, 0);
    });

    test('premium user is never blocked', () {
      const quota = CoachAskQuota(
        dateKey: '2026-08-01',
        usedToday: 100,
        isPremium: true,
      );
      expect(quota.canAsk, isTrue);
      expect(quota.remaining, -1);
    });

    test('consume increments for free users only', () {
      const before = CoachAskQuota(
        dateKey: '2026-08-01',
        usedToday: 1,
        isPremium: false,
      );
      final after = before.consume();
      expect(after.usedToday, 2);

      const premium = CoachAskQuota(
        dateKey: '2026-08-01',
        usedToday: 5,
        isPremium: true,
      );
      expect(premium.consume().usedToday, 5);
    });

    test('fromStorage resets the counter when the date rolls over', () {
      final quota = CoachAskQuota.fromStorage(
        storedKey: '2026-07-31',
        used: 3,
        isPremium: false,
        now: DateTime(2026, 8, 1, 9),
      );
      expect(quota.usedToday, 0);
      expect(quota.dateKey, '2026-08-01');
    });

    test('fromStorage keeps the counter on the same day', () {
      final quota = CoachAskQuota.fromStorage(
        storedKey: '2026-08-01',
        used: 2,
        isPremium: false,
        now: DateTime(2026, 8, 1, 20),
      );
      expect(quota.usedToday, 2);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/monetization/domain/coach_ask_quota_test.dart`
Expected: FAIL with "Target of URI doesn't exist: '...coach_ask_quota.dart'"

- [ ] **Step 3: Implement the quota**

```dart
/// Pure daily quota for free-tier narrator-coach asks.
///
/// Free users get [freeDailyLimit] asks per local calendar day; premium
/// users bypass the quota entirely. Deliberately free of storage/UI so it
/// can be unit-tested without Firebase (mirrors `decideRedirect`).
class CoachAskQuota {
  static const int freeDailyLimit = 3;

  /// Local calendar day key, e.g. '2026-08-01'.
  final String dateKey;

  /// Number of asks consumed today (free users only).
  final int usedToday;

  /// Whether the user is premium (bypasses the quota).
  final bool isPremium;

  const CoachAskQuota({
    required this.dateKey,
    required this.usedToday,
    required this.isPremium,
  });

  /// -1 for premium (unlimited); otherwise asks left today (0..limit).
  int get remaining =>
      isPremium ? -1 : (freeDailyLimit - usedToday).clamp(0, freeDailyLimit);

  bool get canAsk => isPremium || usedToday < freeDailyLimit;

  /// Returns a copy with the counter incremented. Premium users are
  /// unaffected so their stored counter can never grow unbounded.
  CoachAskQuota consume() => isPremium
      ? this
      : CoachAskQuota(
          dateKey: dateKey,
          usedToday: usedToday + 1,
          isPremium: isPremium,
        );

  static String dateKeyFor(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Rebuilds the quota from storage. If [storedKey] is not today's key,
  /// the counter resets to 0 (rollover).
  static CoachAskQuota fromStorage({
    required String storedKey,
    required int used,
    required bool isPremium,
    required DateTime now,
  }) {
    final today = dateKeyFor(now);
    return CoachAskQuota(
      dateKey: today,
      usedToday: storedKey == today ? used : 0,
      isPremium: isPremium,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/monetization/domain/coach_ask_quota_test.dart`
Expected: PASS — 6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/monetization/domain/services/coach_ask_quota.dart test/features/monetization/domain/coach_ask_quota_test.dart
git commit -m "feat(monetization): add CoachAskQuota pure domain (3/day, premium bypass, rollover)"
```

---

## Task 2: Node guide registry + tests

**Files:**
- Create: `lib/features/tutorials/domain/node_guide_registry.dart`
- Test: `test/features/tutorials/domain/node_guide_registry_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/tutorials/domain/node_guide_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NodeGuideRegistry', () {
    test('every registered node has a definition', () {
      for (final d in NodeGuideRegistry.all) {
        expect(d.nodeId, isNotEmpty);
        expect(d.title, isNotEmpty);
        expect(d.items, isNotEmpty, reason: '${d.nodeId} has no items');
      }
    });

    test('node ids are unique', () {
      final ids = NodeGuideRegistry.all.map((d) => d.nodeId).toSet();
      expect(ids.length, NodeGuideRegistry.all.length);
    });

    test('forNode finds known nodes and misses unknown ones', () {
      expect(NodeGuideRegistry.forNode('timeline'), isNotNull);
      expect(NodeGuideRegistry.forNode('does_not_exist'), isNull);
    });

    test('every item has title and body', () {
      for (final d in NodeGuideRegistry.all) {
        for (final item in d.items) {
          expect(item.title, isNotEmpty);
          expect(item.body, isNotEmpty);
        }
      }
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/tutorials/domain/node_guide_registry_test.dart`
Expected: FAIL with "Target of URI doesn't exist"

- [ ] **Step 3: Implement the registry**

```dart
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:flutter/material.dart';

/// One explanatory bullet inside a node guide.
class NodeGuideItem {
  final IconData icon;
  final String title;
  final String body;

  const NodeGuideItem({
    required this.icon,
    required this.title,
    required this.body,
  });
}

/// Static configuration for a first-visit tutorial on one screen.
class NodeGuideDefinition {
  final String nodeId;
  final String title;
  final Color primaryColor;
  final IconData titleIcon;
  final List<NodeGuideItem> items;

  const NodeGuideDefinition({
    required this.nodeId,
    required this.title,
    required this.primaryColor,
    required this.titleIcon,
    required this.items,
  });
}

/// Pure registry of all node guides.
///
/// One entry per live, front-facing screen. Screens that no longer exist
/// must not be added here — when a screen dies (e.g. the blueprints page
/// in SP-F), its node entry dies with it.
class NodeGuideRegistry {
  static const List<NodeGuideDefinition> all = [
    NodeGuideDefinition(
      nodeId: 'timeline',
      title: 'Your Daily Timeline',
      primaryColor: EmergeColors.teal,
      titleIcon: Icons.view_timeline_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.touch_app_outlined,
          title: 'Log habits in one tap',
          body: 'Tap any habit to complete it. Tap again to undo.',
        ),
        NodeGuideItem(
          icon: Icons.ring_volume_outlined,
          title: 'Watch the ring fill',
          body: "The FAB ring shows today's completion. Green is on track.",
        ),
        NodeGuideItem(
          icon: Icons.auto_awesome_outlined,
          title: 'Meet your narrator',
          body: 'The avatar top-right is your coach. Tap it to ask anything.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'habit_create',
      title: 'Create a Habit',
      primaryColor: EmergeColors.violet,
      titleIcon: Icons.add_task,
      items: [
        NodeGuideItem(
          icon: Icons.schedule_outlined,
          title: 'Anchor it to a time',
          body: 'Habits stick when they live at the same moment every day.',
        ),
        NodeGuideItem(
          icon: Icons.bolt_outlined,
          title: 'Start tiny',
          body: 'A 2-minute version is easier to keep than a 2-hour one.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'habit_advanced',
      title: 'Advanced Habit Setup',
      primaryColor: EmergeColors.teal,
      titleIcon: Icons.tune,
      items: [
        NodeGuideItem(
          icon: Icons.anchor_outlined,
          title: 'Anchor habits',
          body: 'Stack a new habit onto one you already never miss.',
        ),
        NodeGuideItem(
          icon: Icons.sports_score_outlined,
          title: 'Attribute XP',
          body: 'Each habit feeds an attribute that shapes your avatar.',
        ),
        NodeGuideItem(
          icon: Icons.thermostat_outlined,
          title: 'Lower the friction',
          body: 'Reduce the 2-minute rule for hard days — showing up counts.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'streak_recovery',
      title: 'Streak Recovery',
      primaryColor: EmergeColors.warmGold,
      titleIcon: Icons.healing_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.replay_outlined,
          title: 'One miss is not a fall',
          body: 'Get back in today — momentum rebuilds fast.',
        ),
        NodeGuideItem(
          icon: Icons.stairs_outlined,
          title: 'Small step first',
          body: 'Pick the easiest habit to restart your streak.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'world_map',
      title: 'Your Living World',
      primaryColor: EmergeColors.teal,
      titleIcon: Icons.public_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.eco_outlined,
          title: 'Your world mirrors your habits',
          body: 'Complete habits to keep it thriving; misses decay it.',
        ),
        NodeGuideItem(
          icon: Icons.travel_explore_outlined,
          title: 'Explore as you grow',
          body: 'New regions unlock as your world heals.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'leveling',
      title: 'Leveling & XP',
      primaryColor: EmergeColors.violet,
      titleIcon: Icons.workspace_premium_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.stars_outlined,
          title: 'Earn XP from habits',
          body: 'Harder habits and longer streaks pay more.',
        ),
        NodeGuideItem(
          icon: Icons.control_point_outlined,
          title: 'Attributes shape your avatar',
          body: 'XP flows into strength, intellect, vitality and more.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'future_self',
      title: 'Future Self Studio',
      primaryColor: EmergeColors.violet,
      titleIcon: Icons.face_retouching_natural_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.edit_outlined,
          title: 'Set your motive',
          body: 'Write the why that keeps you going on hard days.',
        ),
        NodeGuideItem(
          icon: Icons.architecture_outlined,
          title: 'Shape your future self',
          body: 'Attribute XP and base avatars evolve as you grow.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'challenges',
      title: 'Challenges',
      primaryColor: EmergeColors.warmGold,
      titleIcon: Icons.emoji_events_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.flag_outlined,
          title: 'Join a public challenge',
          body: 'Compete on progress, not perfection.',
        ),
        NodeGuideItem(
          icon: Icons.leaderboard_outlined,
          title: 'Track the leaderboard',
          body: 'See where you stand and earn completion badges.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'all_tribes',
      title: 'All Tribes',
      primaryColor: EmergeColors.teal,
      titleIcon: Icons.groups_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.handshake_outlined,
          title: 'Find your people',
          body: 'Join an archetype tribe that matches how you grow.',
        ),
        NodeGuideItem(
          icon: Icons.swap_horiz_outlined,
          title: 'Switch freely',
          body: 'You can leave and join another tribe anytime.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'tribe_lobby',
      title: 'Your Tribe',
      primaryColor: EmergeColors.warmGold,
      titleIcon: Icons.diversity_3_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.people_alt_outlined,
          title: 'Members & partners',
          body: 'Your circle, your partners, and the tribe pulse live here.',
        ),
        NodeGuideItem(
          icon: Icons.auto_stories_outlined,
          title: 'Tribe blueprints',
          body: 'Curated blueprints for your tribe appear in this section.',
        ),
        NodeGuideItem(
          icon: Icons.swap_horiz_outlined,
          title: 'Switch tribes',
          body: 'Use the bottom button to browse and switch tribes.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'coach',
      title: 'Your Coach',
      primaryColor: EmergeColors.teal,
      titleIcon: Icons.auto_awesome_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.forum_outlined,
          title: 'Ask anything',
          body: 'Type a question and the narrator answers as your coach.',
        ),
        NodeGuideItem(
          icon: Icons.local_fire_department_outlined,
          title: '3 free asks a day',
          body: 'Premium unlocks unlimited personal, data-grounded advice.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'discover',
      title: 'Blueprints',
      primaryColor: EmergeColors.violet,
      titleIcon: Icons.auto_stories_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.category_outlined,
          title: 'Browse by category',
          body: 'Morning, productivity, fitness, mindfulness, learning.',
        ),
        NodeGuideItem(
          icon: Icons.preview_outlined,
          title: 'Preview before adopting',
          body: 'Open a blueprint to see its habit stack and adopt it.',
        ),
      ],
    ),
  ];

  static NodeGuideDefinition? forNode(String nodeId) {
    for (final d in all) {
      if (d.nodeId == nodeId) return d;
    }
    return null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/tutorials/domain/node_guide_registry_test.dart`
Expected: PASS — 4 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tutorials test/features/tutorials
git commit -m "feat(tutorials): add node guide registry (12 live screens)"
```

---

## Task 3: `migrateVisitedFlags` in `LocalSettingsRepository` + tests

**Files:**
- Modify: `lib/features/onboarding/data/repositories/local_settings_repository.dart`
- Test: `test/features/onboarding/data/local_settings_repository_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('migrates companion visited flags to node-guide flags', () async {
    SharedPreferences.setMockInitialValues({
      'companion_visited_/timeline': true,
      'companion_visited_/challenges': true,
      'companion_visited_/discover': true,
      'companion_visited_/tribes': false,
    });
    final repo = LocalSettingsRepository();
    await repo.init();
    await repo.migrateVisitedFlags();

    expect(await repo.getHasSeenNodeGuide('timeline'), isTrue);
    expect(await repo.getHasSeenNodeGuide('challenges'), isTrue);
    expect(await repo.getHasSeenNodeGuide('discover'), isTrue);
    // False legacy flags do not migrate.
    expect(await repo.getHasSeenNodeGuide('tribes'), isFalse);
  });

  test('does not overwrite an existing seen flag', () async {
    SharedPreferences.setMockInitialValues({
      'companion_visited_/timeline': true,
      'hasSeenNodeGuide_timeline': true,
    });
    final repo = LocalSettingsRepository();
    await repo.init();
    await repo.migrateVisitedFlags();
    expect(await repo.getHasSeenNodeGuide('timeline'), isTrue);
  });

  test('is idempotent — second run is a no-op', () async {
    SharedPreferences.setMockInitialValues({
      'companion_visited_/challenges': true,
    });
    final repo = LocalSettingsRepository();
    await repo.init();
    await repo.migrateVisitedFlags();
    await repo.migrateVisitedFlags();
    expect(await repo.getHasSeenNodeGuide('challenges'), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/onboarding/data/local_settings_repository_test.dart`
Expected: FAIL — `migrateVisitedFlags` is not defined.

- [ ] **Step 3: Implement the migration**

Add to `lib/features/onboarding/data/repositories/local_settings_repository.dart`, after `resetTutorials()`:

```dart
  /// Migrates legacy companion visited flags into the node-guide system.
  /// Idempotent: only migrates keys that exist; never overwrites already-seen
  /// node flags. The `discover` flag migrates too — its node dies with the
  /// blueprints page in SP-F.
  Future<void> migrateVisitedFlags() async {
    final keys = _getKeys().where((k) => k.startsWith('companion_visited_'));
    if (keys.isEmpty) return;

    const routeToNode = {
      '/timeline': 'timeline',
      '/world-map': 'world_map',
      '/profile': 'profile',
      '/tribes': 'tribes',
      '/profile/reflections': 'coach',
      '/challenges': 'challenges',
      '/discover': 'discover',
    };

    for (final key in keys) {
      final route = key.substring('companion_visited_'.length);
      final nodeId = routeToNode[route];
      final keyWasSeen = _getBool(key);
      final nodeAlreadySeen =
          nodeId != null && _getBool('hasSeenNodeGuide_$nodeId');
      if (nodeId != null && keyWasSeen && !nodeAlreadySeen) {
        await _setBool('hasSeenNodeGuide_$nodeId', true);
      }
      await _remove(key);
    }
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/onboarding/data/local_settings_repository_test.dart`
Expected: PASS — 3 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/data/repositories/local_settings_repository.dart test/features/onboarding/data/local_settings_repository_test.dart
git commit -m "feat(settings): add migrateVisitedFlags for companion -> node guide flags"
```

---

# Phase 2 — Providers & reusable UI

## Task 4: `CoachAskQuotaController` provider + tests

**Files:**
- Create: `lib/features/monetization/presentation/providers/coach_ask_quota_provider.dart`
- Test: `test/features/monetization/presentation/coach_ask_quota_provider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/monetization/domain/services/coach_ask_quota.dart';
import 'package:emerge_app/features/monetization/presentation/providers/coach_ask_quota_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeIsPremium extends IsPremium {
  _FakeIsPremium(this._premium);
  final bool _premium;

  @override
  Future<bool> build() async => _premium;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer makeContainer({bool premium = false}) {
    return ProviderContainer(
      overrides: [
        isPremiumProvider.overrideWith(() => _FakeIsPremium(premium)),
      ],
    );
  }

  test('free user starts at 3 remaining', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    final quota = await container.read(coachAskQuotaControllerProvider.future);
    expect(quota.remaining, 3);
  });

  test('consume persists the counter to shared_prefs', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    final before = await container.read(coachAskQuotaControllerProvider.future);

    await container.read(coachAskQuotaControllerProvider.notifier).consume();

    final after = await container.read(coachAskQuotaControllerProvider.future);
    expect(after.usedToday, 1);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('coach_asks_${before.dateKey}'), 1);
  });

  test('premium user consume never increments the counter', () async {
    final container = makeContainer(premium: true);
    addTearDown(container.dispose);
    final before = await container.read(coachAskQuotaControllerProvider.future);

    final after =
        await container.read(coachAskQuotaControllerProvider.notifier).consume();

    expect(after.usedToday, 0);
    expect(before.usedToday, 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/monetization/presentation/coach_ask_quota_provider_test.dart`
Expected: FAIL — `coachAskQuotaControllerProvider` doesn't exist.

- [ ] **Step 3: Implement the provider**

```dart
import 'package:emerge_app/features/monetization/domain/services/coach_ask_quota.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'coach_ask_quota_provider.g.dart';

/// Daily coach-ask quota controller.
///
/// Persists the free-tier counter in shared_prefs under
/// `coach_asks_<yyyy-MM-dd>`; the pure [CoachAskQuota] handles rollover and
/// the premium bypass. Storage failure defaults to 0 used — never hard-block
/// a user because storage hiccuped.
@Riverpod(keepAlive: true)
class CoachAskQuotaController extends _$CoachAskQuotaController {
  @override
  Future<CoachAskQuota> build() async {
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    final today = CoachAskQuota.dateKeyFor(DateTime.now());
    int used = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      used = prefs.getInt('coach_asks_$today') ?? 0;
    } catch (_) {
      used = 0;
    }
    return CoachAskQuota(
      dateKey: today,
      usedToday: used,
      isPremium: isPremium,
    );
  }

  /// Records one ask. Free users persist the incremented counter;
  /// premium counters never change.
  Future<CoachAskQuota> consume() async {
    final current = state.value ??
        CoachAskQuota(
          dateKey: CoachAskQuota.dateKeyFor(DateTime.now()),
          usedToday: 0,
          isPremium: false,
        );
    final next = current.consume();
    if (!current.isPremium) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('coach_asks_${next.dateKey}', next.usedToday);
      } catch (_) {
        // Permit by default on storage failure.
      }
    }
    state = AsyncValue.data(next);
    return next;
  }
}
```

- [ ] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: BUILD SUCCESSFUL — generates `coach_ask_quota_provider.g.dart`.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/monetization/presentation/coach_ask_quota_provider_test.dart`
Expected: PASS — 3 tests.

- [ ] **Step 6: Commit**

```bash
git add lib/features/monetization/presentation/providers/coach_ask_quota_provider.dart lib/features/monetization/presentation/providers/coach_ask_quota_provider.g.dart test/features/monetization/presentation/coach_ask_quota_provider_test.dart
git commit -m "feat(monetization): add CoachAskQuotaController provider (prefs-backed)"
```

---

## Task 5: `NodeGuideController` + `NodeGuideHost` + tests

**Files:**
- Create: `lib/features/tutorials/presentation/providers/node_guide_controller.dart`
- Create: `lib/features/tutorials/presentation/widgets/node_guide_host.dart`
- Test: `test/features/tutorials/presentation/node_guide_host_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/tutorials/presentation/widgets/node_guide_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettings extends LocalSettingsRepository {
  _FakeSettings({required this.tutorialsEnabled, this.seen = const {}});
  final bool tutorialsEnabled;
  final Set<String> seen;

  @override
  bool isTutorialsEnabled() => tutorialsEnabled;

  @override
  Future<bool> getHasSeenNodeGuide(String nodeId) async => seen.contains(nodeId);

  @override
  Future<void> setHasSeenNodeGuide(String nodeId) async {}
}

void main() {
  Widget host({required _FakeSettings settings}) {
    return ProviderScope(
      overrides: [
        localSettingsRepositoryProvider.overrideWithValue(settings),
      ],
      child: const MaterialApp(
        home: Scaffold(body: NodeGuideHost(nodeId: 'timeline', child: Text('content'))),
      ),
    );
  }

  testWidgets('shows the guide on first visit when tutorials are enabled',
      (tester) async {
    await tester.pumpWidget(host(settings: _FakeSettings(tutorialsEnabled: true)));
    await tester.pumpAndSettle();
    expect(find.text('Your Daily Timeline'), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('does not show when tutorials are disabled', (tester) async {
    await tester.pumpWidget(host(settings: _FakeSettings(tutorialsEnabled: false)));
    await tester.pumpAndSettle();
    expect(find.text('Your Daily Timeline'), findsNothing);
  });

  testWidgets('does not show when the node was already seen', (tester) async {
    await tester.pumpWidget(
      host(settings: _FakeSettings(tutorialsEnabled: true, seen: {'timeline'})),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your Daily Timeline'), findsNothing);
  });

  testWidgets('dismiss marks the node as seen', (tester) async {
    final seen = <String>{};
    final settings = _FakeSettings(tutorialsEnabled: true);
    await tester.pumpWidget(host(settings: settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text("GOT IT — LET'S GO"));
    await tester.pumpAndSettle();
    expect(find.text('Your Daily Timeline'), findsNothing);
    expect(seen, isEmpty); // Fake does not persist; compile-level check only.
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/tutorials/presentation/node_guide_host_test.dart`
Expected: FAIL — `NodeGuideHost` doesn't exist.

- [ ] **Step 3: Implement the controller**

```dart
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'node_guide_controller.g.dart';

/// Stateless controller for the node-guide tutorial system.
///
/// Screens ask [shouldShow] on first frame and call [markSeen] when the
/// guide is dismissed. Reads the existing `tutorialsEnabled` toggle so the
/// Settings switch governs all guides app-wide.
@Riverpod(keepAlive: true)
NodeGuideController nodeGuideController(Ref ref) {
  return NodeGuideController(ref: ref);
}

class NodeGuideController {
  NodeGuideController({required this.ref});
  final Ref ref;

  LocalSettingsRepository get _repo => ref.read(localSettingsRepositoryProvider);

  Future<bool> shouldShow(String nodeId) async {
    if (!_repo.isTutorialsEnabled()) return false;
    return !(await _repo.getHasSeenNodeGuide(nodeId));
  }

  Future<void> markSeen(String nodeId) async {
    await _repo.setHasSeenNodeGuide(nodeId);
  }
}
```

- [ ] **Step 4: Implement the host widget**

```dart
import 'package:emerge_app/core/presentation/widgets/feature_coach_mark.dart';
import 'package:emerge_app/features/tutorials/domain/node_guide_registry.dart';
import 'package:emerge_app/features/tutorials/presentation/providers/node_guide_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps a screen (or dialog body) and shows the node guide for [nodeId]
/// on its first visit while tutorials are enabled.
///
/// Overlays a [FeatureCoachMark] on top of [child]; dismissing marks the
/// node as seen so the guide never reappears.
class NodeGuideHost extends ConsumerStatefulWidget {
  final String nodeId;
  final Widget child;

  const NodeGuideHost({super.key, required this.nodeId, required this.child});

  @override
  ConsumerState<NodeGuideHost> createState() => _NodeGuideHostState();
}

class _NodeGuideHostState extends ConsumerState<NodeGuideHost> {
  bool _showGuide = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (_checked || !mounted) return;
    _checked = true;
    final controller = ref.read(nodeGuideControllerProvider);
    if (await controller.shouldShow(widget.nodeId) && mounted) {
      setState(() => _showGuide = true);
    }
  }

  void _dismiss() {
    ref.read(nodeGuideControllerProvider).markSeen(widget.nodeId);
    setState(() => _showGuide = false);
  }

  @override
  Widget build(BuildContext context) {
    final definition = NodeGuideRegistry.forNode(widget.nodeId);
    return Stack(
      children: [
        widget.child,
        if (_showGuide && definition != null)
          Positioned.fill(
            child: FeatureCoachMark(
              title: definition.title,
              primaryColor: definition.primaryColor,
              titleIcon: definition.titleIcon,
              items: definition.items,
              onDismiss: _dismiss,
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 5: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: BUILD SUCCESSFUL — generates `node_guide_controller.g.dart`.

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/tutorials/presentation/node_guide_host_test.dart`
Expected: PASS — 4 tests. (Note: the fake does not persist; the 4th test asserts dismissal hides the guide.)

- [ ] **Step 7: Commit**

```bash
git add lib/features/tutorials/presentation test/features/tutorials/presentation
git commit -m "feat(tutorials): add NodeGuideController + NodeGuideHost overlay widget"
```

---

## Task 6: `PremiumLimitType.coachAsk` + dialog copy

**Files:**
- Modify: `lib/features/monetization/presentation/widgets/premium_limit_dialog.dart`

- [ ] **Step 1: Extend the enum**

`lib/features/monetization/presentation/widgets/premium_limit_dialog.dart:19`:

```dart
enum PremiumLimitType { habit, club, coachAsk }
```

- [ ] **Step 2: Add the factory case**

In `PremiumLimitDialog.forLimit`, add after the `club` case:

```dart
      case PremiumLimitType.coachAsk:
        return const PremiumLimitDialog(
          title: "You've used your 3 free coach asks today",
          message:
              "That's the free limit — a focused start. Premium unlocks "
              "unlimited personal coach guidance, grounded in your own "
              "habit data.",
          icon: Icons.auto_awesome,
        );
```

- [ ] **Step 3: Verify**

Run: `dart analyze lib/features/monetization/presentation/widgets/premium_limit_dialog.dart`
Expected: 0 issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/monetization/presentation/widgets/premium_limit_dialog.dart
git commit -m "feat(monetization): add coachAsk premium limit type + dialog copy"
```

---

# Phase 3 — Narrator coach

## Task 7: Consolidate duplicate `GroqAiService`

**Files:**
- Modify: `lib/features/ai/data/services/groq_ai_service.dart` (keep)
- Modify: `lib/features/ai/data/repositories/ai_repository_impl.dart`
- Modify: `lib/features/ai/domain/services/ai_personalization_service.dart`
- Modify: `lib/features/narrator/presentation/providers/narrator_providers.dart`
- Delete: `lib/features/ai/data/datasources/groq_ai_service.dart`

- [ ] **Step 1: Port `fillNarratorSlots` to the kept service**

Add to `lib/features/ai/data/services/groq_ai_service.dart` (after `getCoachAdvice`):

```dart
  /// Calls the `fillNarratorSlots` Cloud Function to get Groq-generated
  /// narrator slot text for a given trigger and user context.
  Future<Map<String, String>> fillNarratorSlots({
    required String trigger,
    required Map<String, dynamic> context,
  }) async {
    final result = await _functions
        .httpsCallable('fillNarratorSlots')
        .call({'trigger': trigger, 'context': context});
    final data = result.data as Map<String, dynamic>?;
    final slots = data?['slots'] as Map<String, dynamic>?;
    if (slots == null) return {};
    return slots.map((k, v) => MapEntry(k, v.toString()));
  }
```

- [ ] **Step 2: Re-point the three imports**

```bash
# ai_repository_impl.dart:1
#   from: package:emerge_app/features/ai/data/datasources/groq_ai_service.dart
#   to:   package:emerge_app/features/ai/data/services/groq_ai_service.dart
# ai_personalization_service.dart:2  — same change
# narrator_providers.dart:2          — same change
```

- [ ] **Step 3: Delete the duplicate**

```bash
rm lib/features/ai/data/datasources/groq_ai_service.dart
```

- [ ] **Step 4: Verify no references remain + analyze**

```bash
grep -rn "data/datasources/groq_ai_service" lib --include="*.dart"   # expect nothing
dart analyze lib/features/ai lib/features/narrator
```

Expected: 0 errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/ai lib/features/narrator
git commit -m "refactor(ai): consolidate duplicate GroqAiService into data/services"
```

---

## Task 8: `NarratorSheet` coach mode (ask field + quota + responses)

**Files:**
- Modify: `lib/features/narrator/presentation/widgets/narrator_sheet.dart`
- Test: `test/features/narrator/narrator_sheet_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
import 'package:emerge_app/features/monetization/domain/services/coach_ask_quota.dart';
import 'package:emerge_app/features/monetization/presentation/providers/coach_ask_quota_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeIsPremium extends IsPremium {
  _FakeIsPremium(this._premium);
  final bool _premium;

  @override
  Future<bool> build() async => _premium;
}

class _FakeQuota extends CoachAskQuotaController {
  _FakeQuota(this._quota);
  final CoachAskQuota _quota;

  @override
  Future<CoachAskQuota> build() async => _quota;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const appearance = NarratorAppearance(
    trigger: NarratorTrigger.askNarrator,
    shellText: 'Ask your coach anything.',
    buttonA: 'Later',
    buttonB: 'Later',
    line: GenericLine('Ask your coach anything.'),
  );

  Widget harness({bool premium = false, CoachAskQuota? quota}) {
    return ProviderScope(
      overrides: [
        isPremiumProvider.overrideWith(() => _FakeIsPremium(premium)),
        coachAskQuotaControllerProvider.overrideWith(
          () => _FakeQuota(
            quota ??
                const CoachAskQuota(
                  dateKey: '2026-08-01',
                  usedToday: 0,
                  isPremium: false,
                ),
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => NarratorSheet.show(context, appearance,
                  showAskField: true),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('coach mode shows the ask field with quota hint', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('3 of 3 coach asks left today'), findsOneWidget);
  });

  testWidgets('submitting an ask shows a response and decrements the quota',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // Deterministic: pool[question.length % 5] with length 1 -> pool[1].
    expect(find.textContaining('future self'), findsOneWidget);
    expect(find.text('2 of 3 coach asks left today'), findsOneWidget);
  });

  testWidgets('exhausted quota shows the premium limit dialog', (tester) async {
    await tester.pumpWidget(
      harness(
        quota: const CoachAskQuota(
          dateKey: '2026-08-01',
          usedToday: 3,
          isPremium: false,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text("You've used your 3 free coach asks today"), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/narrator/narrator_sheet_test.dart`
Expected: FAIL — `showAskField` is not a parameter of `NarratorSheet.show`.

- [ ] **Step 3: Implement coach mode**

Replace the entire contents of `lib/features/narrator/presentation/widgets/narrator_sheet.dart` with:

```dart
import 'dart:ui';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/ai/data/services/groq_ai_service.dart';
import 'package:emerge_app/features/monetization/presentation/providers/coach_ask_quota_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/premium_limit_dialog.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_pulse_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the Narrator as a centered glassmorphic dialog.
///
/// Callers should use [NarratorSheet.show] to display it.
/// Renders instant text — no typewriter.
///
/// In coach mode ([showAskField] = true) the action buttons are replaced by
/// an ask field wired to the coach quota: free users get 3 asks/day,
/// premium users are unlimited.
class NarratorSheet extends ConsumerStatefulWidget {
  final NarratorAppearance appearance;
  final void Function(String buttonLabel, String? typedText)? onResponse;
  final bool showAskField;

  const NarratorSheet({
    super.key,
    required this.appearance,
    this.onResponse,
    this.showAskField = false,
  });

  /// Displays the Narrator as a centered dialog.
  static Future<void> show(
    BuildContext context,
    NarratorAppearance appearance, {
    void Function(String buttonLabel, String? typedText)? onResponse,
    bool showAskField = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => NarratorSheet(
        appearance: appearance,
        onResponse: onResponse,
        showAskField: showAskField,
      ),
    );
  }

  @override
  ConsumerState<NarratorSheet> createState() => _NarratorSheetState();
}

class _NarratorSheetState extends ConsumerState<NarratorSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  final TextEditingController _askController = TextEditingController();
  NarratorLine? _currentLine;
  bool _isAsking = false;

  static const List<String> _genericAskPool = [
    'Small steps compound. Pick the tiniest version of this and do it now.',
    'What would your future self thank you for today? Start there.',
    "One miss is a slip, not a fall. What's the smallest next move?",
    'Consistency beats intensity. Can you make this 2 minutes easier?',
    'Your habits are votes for the person you are becoming. Cast one today.',
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _askController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _submitAsk(String raw) async {
    final question = raw.trim();
    if (question.isEmpty || _isAsking) return;

    final quotaCtrl = ref.read(coachAskQuotaControllerProvider.notifier);
    final quota = await ref.read(coachAskQuotaControllerProvider.future);
    if (!quota.canAsk) {
      if (mounted) {
        showPremiumLimitDialog(
          context,
          limitType: PremiumLimitType.coachAsk,
        );
      }
      return;
    }

    setState(() => _isAsking = true);
    try {
      final isPremium = ref.read(isPremiumProvider).value ?? false;
      final NarratorLine line;
      if (isPremium) {
        final groq = GroqAiService();
        final advice = await groq.getCoachAdvice('', question);
        line = PersonalLine(text: advice, dataBasis: 'groq_coach');
      } else {
        line = GenericLine(_genericAskPool[question.length % _genericAskPool.length]);
      }
      await quotaCtrl.consume();
      if (mounted) {
        setState(() {
          _currentLine = line;
          _askController.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _currentLine = const GenericLine("I'm here — keep going."));
      }
    } finally {
      if (mounted) setState(() => _isAsking = false);
    }
  }

  String _quotaHint() {
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    if (isPremium) return 'Unlimited coach asks';
    final remaining =
        ref.watch(coachAskQuotaControllerProvider).value?.remaining ?? 3;
    return '$remaining of 3 coach asks left today';
  }

  @override
  Widget build(BuildContext context) {
    final appearance = widget.appearance;
    final isPersonal = _currentLine is PersonalLine || appearance.line is PersonalLine;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.85).clamp(0.0, 400.0);

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent dismiss when tapping inside card
            child: Container(
              width: cardWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2BEE79).withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              NarratorPulseIndicator(
                                color: EmergeColors.teal,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.showAskField ? 'COACH' : 'EMERGE',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: EmergeColors.teal,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3,
                                    ),
                              ),
                              const Spacer(),
                              if (isPersonal)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: EmergeColors.warmGold
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'DATA-GROUNDED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: EmergeColors.warmGold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Instant text (no typewriter)
                          Text(
                            _currentLine?.text ?? appearance.line.text,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  height: 1.6,
                                ),
                          ),

                          if (widget.showAskField) ...[
                            const SizedBox(height: 16),
                            TextField(
                              controller: _askController,
                              maxLines: 3,
                              minLines: 1,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: _isAsking
                                    ? 'Consulting your coach…'
                                    : 'Ask your coach anything…',
                                hintStyle: const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.06),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                              ),
                              onSubmitted: _submitAsk,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _quotaHint(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _isAsking
                                      ? null
                                      : () => _submitAsk(_askController.text),
                                  icon: const Icon(
                                    Icons.send,
                                    color: EmergeColors.teal,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 20),
                            // Action buttons (always visible)
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionButton(
                                    label: appearance.buttonA,
                                    color: EmergeColors.teal,
                                    onTap: () {
                                      _onButtonTap(appearance.buttonA);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ActionButton(
                                    label: appearance.buttonB,
                                    color: EmergeColors.violet,
                                    onTap: () {
                                      _onButtonTap(appearance.buttonB);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onButtonTap(String buttonLabel) {
    widget.onResponse?.call(buttonLabel, null);
    ref.read(narratorStateProvider.notifier).dismiss();
    Navigator.of(context).pop();
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run codegen (not needed — no new providers) and test**

Run: `flutter test test/features/narrator/narrator_sheet_test.dart`
Expected: PASS — 3 tests.

- [ ] **Step 5: Run the existing narrator tests**

Run: `flutter test test/features/narrator/`
Expected: all pass (update any test that asserted the old sheet layout only if it breaks for a legitimate reason).

- [ ] **Step 6: Commit**

```bash
git add lib/features/narrator/presentation/widgets/narrator_sheet.dart test/features/narrator/narrator_sheet_test.dart
git commit -m "feat(narrator): coach mode in NarratorSheet — ask field, quota hint, free/premium responses"
```

---

## Task 9: Mount `NarratorAvatar` on the timeline + open the coach

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

- [ ] **Step 1: Add imports + coach open method**

Add to the timeline's imports:

```dart
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_avatar.dart';
```

Add the method to `_TimelineScreenState` (near `_checkEveningReflection`):

```dart
  void _openCoach() {
    NarratorSheet.show(
      context,
      NarratorAppearance(
        trigger: NarratorTrigger.askNarrator,
        shellText: 'Ask your coach anything.',
        buttonA: 'Later',
        buttonB: 'Later',
        line: const GenericLine('Ask your coach anything.'),
      ),
      showAskField: true,
    );
  }
```

- [ ] **Step 2: Mount the avatar in the header**

In `_buildTimelineList` (timeline_screen.dart ~321-327), pass the avatar as the header's `trailing`:

```dart
        SliverToBoxAdapter(
          child: EmergeHeader(
            displayName: displayName,
            showToday: _isToday(_selectedDate),
            onAvatarTap: () => context.push('/profile'),
            onUpgradeTap: () => context.push('/paywall'),
            trailing: NarratorAvatar(onTap: _openCoach),
          ),
        ),
```

- [ ] **Step 3: Verify**

Run: `dart analyze lib/features/timeline`
Expected: 0 errors.

Run: `flutter test test/features/timeline/`
Expected: existing timeline tests pass (update only if a test asserted the header row had no trailing widget).

- [ ] **Step 4: Commit**

```bash
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "feat(timeline): mount NarratorAvatar in header — tap opens coach dialog"
```

---

## Task 10: Milestone producers (PendingMilestoneLine + habit trigger + timeline consume + onboarding)

**Files:**
- Modify: `lib/features/narrator/presentation/providers/narrator_providers.dart`
- Modify: `lib/features/habits/presentation/providers/habit_providers.dart`
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`
- Modify: `lib/features/onboarding/presentation/screens/identity_studio_screen.dart`

- [ ] **Step 1: Upgrade `PendingMilestone` state to carry the trigger**

In `lib/features/narrator/presentation/providers/narrator_providers.dart`, replace the `PendingMilestone` notifier block:

```dart
/// A narrator line awaiting display in the slide-up card, with the trigger
/// that produced it (drives the card label).
class PendingMilestoneLine {
  final NarratorLine line;
  final NarratorTrigger trigger;

  const PendingMilestoneLine({required this.line, required this.trigger});
}

/// Pending narrator line awaiting display in the slide-up card.
@riverpod
class PendingMilestone extends _$PendingMilestone {
  @override
  PendingMilestoneLine? build() => null;

  void set(PendingMilestoneLine line) => state = line;
  void clear() => state = null;
}
```

- [ ] **Step 2: Compute `narratorTrigger` on habit completion**

In `lib/features/habits/presentation/providers/habit_providers.dart`:

Add this top-level helper (near the top of the file, after imports):

```dart
/// Mirrors `HabitCompletionService._evaluateNarratorTrigger`: recovery and
/// weekly-streak milestones surface as narrator lines.
NarratorTrigger? _narratorTriggerFor({
  required bool isCompleted,
  required bool wasRecovery,
  required int newStreak,
}) {
  if (!isCompleted) return null;
  if (wasRecovery) return NarratorTrigger.streakBreakFirstMiss;
  if (newStreak >= 7 && newStreak % 7 == 0) return NarratorTrigger.onFireState;
  return null;
}
```

Add the import:

```dart
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
```

In the `if (isCompleted) { ... }` branch of `completeHabit` (habit_providers.dart ~200-272), immediately before `return HabitCompletionResult(...)`, add:

```dart
              final narratorTrigger = _narratorTriggerFor(
                isCompleted: true,
                wasRecovery: wasRecovery,
                newStreak: newStreak,
              );
```

and add `narratorTrigger: narratorTrigger,` to the `HabitCompletionResult(...)` constructor call.

- [ ] **Step 3: Consume the trigger on the timeline**

In `lib/features/timeline/presentation/screens/timeline_screen.dart`:

1. Replace `NarratorLine? _pendingOverlayLine;` with:

```dart
  PendingMilestoneLine? _pendingOverlayLine;
```

2. Replace `_onPendingMilestoneChange`:

```dart
  void _onPendingMilestoneChange(
    PendingMilestoneLine? prev,
    PendingMilestoneLine? next,
  ) {
    if (prev == null && next != null) {
      setState(() {
        _pendingOverlayLine = next;
        _showOverlay = true;
      });
    }
  }
```

3. In the overlay block (timeline_screen.dart ~277-293), replace `trigger: NarratorTrigger.askNarrator,` with `trigger: _pendingOverlayLine!.trigger,`.

4. In `_completeHabitSilently` (timeline_screen.dart ~576-600), inside `if (!result.isUndo && mounted)`, add the producer after the existing celebration/recovery branches:

```dart
        if (result.narratorTrigger != null) {
          final resolver = ref.read(lineResolverProvider);
          final line = await resolver.resolve(
            trigger: result.narratorTrigger!,
            stats: NarratorUserStats(
              momentumScore: (result.newMomentumScore / 100).clamp(0.0, 1.0),
              consecutiveActiveDays: 0,
              totalHabitsToday: 1,
              completedHabitsToday: 1,
              currentLevel: 1,
              previousLevel: 1,
              hasStreakBreak: result.wasRecovery,
              currentStreak: result.newStreak,
              longestStreak: result.newStreak,
              consecutiveMisses: 0,
              hasCompletedEveningReflectionToday: true,
              hasCompletedOnboarding: true,
              archetypeSelected: true,
            ),
          );
          if (mounted) {
            ref.read(pendingMilestoneProvider.notifier).set(
                  PendingMilestoneLine(
                    line: line,
                    trigger: result.narratorTrigger!,
                  ),
                );
          }
        }
```

Add imports to the timeline file:

```dart
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';
```

- [ ] **Step 4: Fire `onboardingPostArchetype` from Identity Studio**

In `lib/features/onboarding/presentation/screens/identity_studio_screen.dart`:

1. In `_completeIdentityStudio`, after `await notifier.completeMilestone(0);` and before navigating, add:

```dart
      // Narrator welcomes the newly-chosen archetype (non-blocking card).
      final resolver = ref.read(lineResolverProvider);
      final welcomeLine = await resolver.resolve(
        trigger: NarratorTrigger.onboardingPostArchetype,
        stats: const NarratorUserStats(
          momentumScore: 0,
          consecutiveActiveDays: 0,
          totalHabitsToday: 0,
          completedHabitsToday: 0,
          currentLevel: 1,
          previousLevel: 1,
          hasStreakBreak: false,
          currentStreak: 0,
          longestStreak: 0,
          consecutiveMisses: 0,
          hasCompletedEveningReflectionToday: true,
          hasCompletedOnboarding: false,
          archetypeSelected: true,
        ),
      );
      ref.read(pendingMilestoneProvider.notifier).set(
            PendingMilestoneLine(
              line: welcomeLine,
              trigger: NarratorTrigger.onboardingPostArchetype,
            ),
          );
```

2. Add a milestone overlay host so the card renders on this screen. Add state:

```dart
  PendingMilestoneLine? _pendingMilestone;
```

In `build`, add the listener (next to any existing `ref.listen` calls):

```dart
    ref.listen<PendingMilestoneLine?>(
      pendingMilestoneProvider,
      (prev, next) {
        if (prev == null && next != null) {
          setState(() => _pendingMilestone = next);
        }
      },
    );
```

3. Wrap the top-level `return` of `build` in a `Stack`:

```dart
    return Stack(
      children: [
        /* the widget that was previously returned */
        if (_pendingMilestone != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: NarratorMilestoneCard(
              line: _pendingMilestone!.line,
              trigger: _pendingMilestone!.trigger,
              onDismissed: () {
                setState(() => _pendingMilestone = null);
                ref.read(pendingMilestoneProvider.notifier).clear();
              },
            ),
          ),
      ],
    );
```

4. Clear any pending line when leaving the screen (in `dispose`):

```dart
  @override
  void dispose() {
    ref.read(pendingMilestoneProvider.notifier).clear();
    _carouselController.dispose();
    super.dispose();
  }
```

(Note: `dispose` already exists in this file — merge, don't duplicate.)

Add imports:

```dart
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_milestone_card.dart';
```

- [ ] **Step 5: Verify**

Run: `dart analyze lib/features/narrator lib/features/habits lib/features/timeline lib/features/onboarding`
Expected: 0 errors.

Run: `flutter test test/features/narrator test/features/habits/presentation/providers test/features/onboarding/presentation`
Expected: pass (fix tests that referenced `PendingMilestone` with `NarratorLine?` state).

- [ ] **Step 6: Commit**

```bash
git add lib/features/narrator lib/features/habits/presentation/providers/habit_providers.dart lib/features/timeline lib/features/onboarding
git commit -m "feat(narrator): wire milestone producers — habit triggers, onboardingPostArchetype, trigger-aware overlay"
```

---

# Phase 4 — Tutorials on screens

## Task 11: Node guides — timeline, challenges, all tribes, tribe lobby + discover port + tribe_tab removal

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`
- Modify: `lib/features/social/presentation/screens/challenges_screen.dart`
- Modify: `lib/features/social/presentation/screens/all_tribes_screen.dart`
- Modify: `lib/features/social/presentation/screens/tribe_lobby_screen.dart`
- Modify: `lib/features/social/presentation/screens/social_discover_tab.dart`
- Modify: `lib/features/social/presentation/screens/tribe_tab_content.dart`

- [ ] **Step 1: Timeline — wrap the build return**

In `timeline_screen.dart`, the `build` method ends with `return WorldBackground(...)`. Wrap it:

```dart
    return NodeGuideHost(
      nodeId: 'timeline',
      child: WorldBackground(
        /* existing arguments unchanged */
      ),
    );
```

Add imports:

```dart
import 'package:emerge_app/features/tutorials/presentation/widgets/node_guide_host.dart';
```

- [ ] **Step 2: Challenges — replace the dead stub with a real guide**

In `challenges_screen.dart`:
1. Delete the `_checkFirstVisit` method (the whole `Future<void> _checkFirstVisit() async {...}` block) and its `initState` call (`_checkFirstVisit();` inside `initState`). Keep `initState` (empty or with the remaining `_disposed` wiring).
2. Delete the now-unused `LocalSettingsRepository` import if nothing else uses it.
3. Wrap the final `return` of `build` in `NodeGuideHost(nodeId: 'challenges', child: ...)`.

- [ ] **Step 3: All Tribes — wrap**

In `all_tribes_screen.dart`, wrap the `build` return in `NodeGuideHost(nodeId: 'all_tribes', child: ...)` + import.

- [ ] **Step 4: Tribe lobby — wrap**

In `tribe_lobby_screen.dart`, wrap the `build` return in `NodeGuideHost(nodeId: 'tribe_lobby', child: ...)` + import.

- [ ] **Step 5: Social discover — port the companion mark to a node guide**

In `social_discover_tab.dart`:
1. Delete the `initState` body's delayed companion block (the `Future.delayed(...)` that calls `hasVisited('/discover')` / `markVisited('/discover')` / `triggerEvent(...)` / `setState(() => _showFirstVisitGuide = true)`), and the `_showFirstVisitGuide` field.
2. Delete the companion overlay block in `build` (the `if (_showFirstVisitGuide) Positioned.fill(child: FeatureCoachMark(...))` and its `FeatureCoachMark`/`CoachItemData` usage at ~104-120).
3. Delete the `companionRepositoryProvider` / `companionEngineProvider` / `feature_coach_mark` imports if now unused.
4. Wrap the `build` return in `NodeGuideHost(nodeId: 'discover', child: ...)` + import.

- [ ] **Step 6: Tribe tab content — remove the mark entirely**

In `tribe_tab_content.dart`:
1. Delete the `initState` delayed companion block (lines ~27-43).
2. Delete the `_showFirstVisitGuide` overlay block in `build` (lines ~153-169).
3. Delete now-unused companion/coach-mark imports.

- [ ] **Step 7: Verify**

Run: `dart analyze lib/features/social lib/features/timeline`
Expected: 0 errors.

Run: `flutter test test/features/social test/features/timeline`
Expected: pass (update tests that referenced the removed companion marks, e.g. any `_showFirstVisitGuide` assertions).

- [ ] **Step 8: Commit**

```bash
git add lib/features/timeline/presentation/screens/timeline_screen.dart lib/features/social
git commit -m "feat(tutorials): node guides on timeline, challenges, tribes; port discover mark; drop tribe_tab companion mark"
```

---

## Task 12: Node guides — habit create, streak recovery, world map, leveling, future self, coach sheet

**Files:**
- Modify: `lib/features/habits/presentation/screens/habit_create_screen.dart`
- Modify: `lib/features/habits/presentation/screens/streak_recovery_screen.dart`
- Modify: `lib/features/world_map/presentation/screens/world_map_screen.dart`
- Modify: `lib/features/gamification/presentation/screens/leveling_screen.dart`
- Modify: `lib/features/profile/presentation/screens/future_self_studio_screen.dart`
- Modify: `lib/features/narrator/presentation/widgets/narrator_sheet.dart`
- Modify: `lib/features/tutorials/domain/node_guide_registry.dart` — remove `habit_advanced`
- New: `lib/features/tutorials/presentation/widgets/node_guide_overlay.dart`

- [ ] **Step 1: Wrap the five full screens**

For each of `habit_create_screen.dart` (`nodeId: 'habit_create'`), `streak_recovery_screen.dart` (`'streak_recovery'`), `world_map_screen.dart` (`'world_map'`), `leveling_screen.dart` (`'leveling'`), `future_self_studio_screen.dart` (`'future_self'`):

1. Add the import:

```dart
import 'package:emerge_app/features/tutorials/presentation/widgets/node_guide_host.dart';
```

2. Wrap the single top-level `return` of `build`:

```dart
    return NodeGuideHost(
      nodeId: '<nodeId>',
      child: /* the widget that was previously returned */,
    );
```

- [ ] **Step 2: Drop `habit_advanced` (no live surface)**

`advanced_create_habit_dialog.dart` does NOT exist at HEAD — the advanced habit features live inside `habit_create_screen.dart`, whose content is covered by the `habit_create` guide. Per the registry contract (one entry per live screen), remove the `habit_advanced` entry from `node_guide_registry.dart`. The registry test only asserts non-empty/uniqueness — removal is safe.

Also in `streak_recovery_screen.dart`: its `initState` shows a hardcoded `NarratorSheet.show` on first visit (leftover pattern). Gate it so the legacy sheet only shows when the node guide is NOT due (`if (await ref.read(nodeGuideControllerProvider).shouldShow('streak_recovery')) return;`) — otherwise the sheet's dialog would sit awkwardly above the guide's scrim on first visit.

- [ ] **Step 3: Coach sheet — overlay gate, not a host wrap**

The coach sheet is a dialog and cannot host `NodeGuideHost`'s `SizedBox.expand` overlay. Add a full-screen-dialog variant `NodeGuideOverlay.show(context, nodeId)` (`lib/features/tutorials/presentation/widgets/node_guide_overlay.dart`): no-op when tutorials disabled or the node was seen; renders `FeatureCoachMark` and marks the node seen on dismiss.

Make `NarratorSheet.show` async and gate on coach mode (`showAskField`):

```dart
  static Future<void> show(
    BuildContext context,
    NarratorAppearance appearance, {
    void Function(String buttonLabel, String? typedText)? onResponse,
    bool showAskField = false,
  }) async {
    if (showAskField) {
      await NodeGuideOverlay.show(context, 'coach');
      if (!context.mounted) return;
    }
    return showDialog(...);
  }
```

Callers don't await the returned future (it was already `Future<void>`) — safe.

- [ ] **Step 4: Verify**

Run: `dart analyze lib/features/habits lib/features/world_map lib/features/gamification lib/features/profile lib/features/narrator lib/features/tutorials`
Expected: 0 errors.

Run: `flutter test test/features/habits test/features/world_map test/features/gamification test/features/profile test/features/narrator test/features/tutorials`
Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/habits lib/features/world_map lib/features/gamification lib/features/profile lib/features/narrator lib/features/tutorials
git commit -m "feat(tutorials): node guides on habit create, streak recovery, world map, leveling, future self; coach guide overlay"
```

---

# Phase 5 — Companion cleanup + Settings

## Task 13: Remove the companion visited-flag + migration APIs

**Files:**
- Modify: `lib/features/companion/data/repositories/companion_repository.dart`
- Modify: `lib/features/companion/presentation/providers/companion_providers.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Strip the visited-flag API**

In `companion_repository.dart`:
1. Delete `hasVisited` (line ~54) and `markVisited` (lines ~56-58) — the whole "Visit tracking" section.
2. In `setCompanionEnabled`, delete the `if (enabled) { ... }` block that clears `companion_visited_*` keys (lines ~96-101).
3. Delete `migrateFromTutorials` (lines ~106-139).

- [ ] **Step 2: Strip companion_providers usage**

In `companion_providers.dart`:
1. Delete the `markVisited` method (lines ~143-144) and its repository call.
2. Delete the `repo.migrateFromTutorials();` call (line ~62, inside the provider init).
3. Run `dart analyze lib/features/companion` and remove any now-unused imports.

- [ ] **Step 3: Call `migrateVisitedFlags()` from `main.dart`**

In `lib/main.dart`, find where `LocalSettingsRepository().init()` (or `localSettingsRepositoryProvider`) is initialized during app startup (near the other `seed*` calls / settings init), and after init add:

```dart
    await LocalSettingsRepository().migrateVisitedFlags();
```

(Use the already-initialized repository instance if one is held; do not create a second init.)

- [ ] **Step 4: Verify**

Run: `dart analyze lib/features/companion lib/main.dart`
Expected: 0 errors.

Run: `flutter test test/features/companion` (if present)
Expected: pass (update tests that exercised `migrateFromTutorials` — replace with `LocalSettingsRepository.migrateVisitedFlags` coverage from Task 3).

- [ ] **Step 5: Commit**

```bash
git add lib/features/companion lib/main.dart
git commit -m "refactor(companion): remove visited-flag system + tutorial migration (superseded by node guides)"
```

---

## Task 14: Unified Tutorials section in Settings

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`

- [ ] **Step 1: Replace the companion + node-guide tiles with the Tutorials section**

In `settings_screen.dart`:

1. Delete the `companionEnabled` watch (lines ~45-47).
2. Replace everything from the `// Companion section` block — the `SwitchListTile` with title `'Show Companion'` (line ~330) through the end of the `SwitchListTile` with title `'Show Node Guides'` (line ~397) — with the new section:

```dart
            // Tutorials Section
            _buildSectionHeader(context, 'Tutorials'),
            _buildSectionContainer(context, [
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EmergeColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.school_outlined, color: EmergeColors.teal),
                ),
                title: Text(
                  'Show first-visit guides',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMainDark,
                  ),
                ),
                subtitle: Text(
                  tutorialsEnabled
                      ? 'Guides shown once on each screen'
                      : 'Guides hidden',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
                value: tutorialsEnabled,
                onChanged: (value) async {
                  await ref
                      .read(tutorialSettingProvider.notifier)
                      .setEnabled(value);
                },
                activeThumbColor: EmergeColors.teal,
                activeTrackColor: EmergeColors.teal.withValues(alpha: 0.5),
              ),
              _buildListTile(
                context,
                Icons.replay_outlined,
                'Replay first-visit guides',
                subtitle: 'Shows every guide again on next visit',
                onTap: () => _showReplayGuidesDialog(context, ref),
              ),
              _buildListTile(
                context,
                Icons.restart_alt_outlined,
                'Replay onboarding',
                subtitle: 'Runs the 5-step onboarding flow again',
                onTap: () => _showReplayOnboardingDialog(context, ref),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final isPremium =
                      ref.watch(isPremiumProvider).value ?? false;
                  final remaining = ref
                      .watch(coachAskQuotaControllerProvider)
                      .value
                      ?.remaining;
                  return _buildListTile(
                    context,
                    Icons.auto_awesome_outlined,
                    'Coach asks',
                    subtitle: isPremium
                        ? 'Unlimited coach asks'
                        : '${remaining ?? 3} of 3 coach asks left today',
                    onTap: isPremium ? null : () => context.push('/paywall'),
                  );
                },
              ),
            ]),
```

3. Delete `_showResetCompanionDialog` and `_showResetTutorialsDialog`; add the two new dialogs (place them near the other dialog helpers):

```dart
  void _showReplayGuidesDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Replay first-visit guides?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'All first-visit guides will show again the next time you visit each screen.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(tutorialSettingProvider.notifier)
                  .resetTutorials();
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Guides will reappear on next visit!'),
                ),
              );
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: EmergeColors.teal),
            child: const Text(
              'RESET',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReplayOnboardingDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Replay onboarding?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This restarts the 5-step onboarding flow and clears local data.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(enhancedOnboardingProvider.notifier)
                  .resetOnboarding();
              ref.invalidate(onboardingControllerProvider);
              ref.invalidate(userStatsStreamProvider);
              if (!context.mounted) return;
              Navigator.pop(context);
              context.go('/timeline'); // redirect takes over from here
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: EmergeColors.teal),
            child: const Text(
              'REPLAY',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
```

4. Add imports:

```dart
import 'package:emerge_app/features/monetization/presentation/providers/coach_ask_quota_provider.dart';
```

(`isPremiumProvider`, `tutorialSettingProvider`, `enhancedOnboardingProvider`, `userStatsStreamProvider`, `onboardingControllerProvider` — add whichever are not already imported.)

- [ ] **Step 2: Verify**

Run: `dart analyze lib/features/settings`
Expected: 0 errors.

Run: `flutter test test/features/settings` (if present) — update any test asserting the old tiles.

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/presentation/screens/settings_screen.dart
git commit -m "feat(settings): unified Tutorials section — toggle, replay guides, replay onboarding, coach quota row"
```

---

# Phase 6 — Oracle deletion + final verification

## Task 15: Delete the Oracle screens and routes

**Files:**
- Modify: `lib/core/router/router.dart`
- Delete: `lib/features/ai/presentation/screens/ai_reflections_screen.dart`
- Delete: `lib/features/ai/presentation/screens/goldilocks_screen.dart`

- [ ] **Step 1: Remove the routes**

In `lib/core/router/router.dart`:
1. Remove the `GoRoute(path: 'reflections', ...)` block (lines ~599-603).
2. Remove the `GoRoute(path: 'goldilocks', ...)` block (lines ~609-612).
3. Remove the import of `goldilocks_screen.dart` (line ~11) and `ai_reflections_screen.dart` (wherever imported).

- [ ] **Step 2: Delete the screens**

```bash
rm lib/features/ai/presentation/screens/ai_reflections_screen.dart
rm lib/features/ai/presentation/screens/goldilocks_screen.dart
```

- [ ] **Step 3: Verify no dangling references**

```bash
grep -rn "AiReflectionsScreen\|GoldilocksScreen\|profile/reflections\|goldilocks" lib --include="*.dart" | grep -v "\.g\.dart"
```

Expected: only harmless hits (e.g. remote config keys, companion migration map is already deleted in Task 13). If any navigation call remains, retarget it to the coach sheet (`NarratorSheet.show(..., showAskField: true)`).

Run: `dart analyze lib`
Expected: 0 errors.

- [ ] **Step 4: Run the affected test suites**

Run: `flutter test test/features/ai test/features/narrator test/features/timeline`
Expected: pass (delete/fix any tests that pumped the removed screens).

- [ ] **Step 5: Commit**

```bash
git add -u lib/core/router lib/features/ai
git commit -m "refactor(ai): delete Oracle screens (AiReflections, Goldilocks) + orphaned routes"
```

---

## Task 16: Final verification

- [ ] **Step 1: Full static analysis**

Run: `dart analyze lib`
Expected: 0 errors. (Compare against the pre-flight baseline; only SP-A-introduced issues are in scope.)

- [ ] **Step 2: Focused test sweep (no full suite)**

Run:

```bash
flutter test test/features/monetization
flutter test test/features/tutorials
flutter test test/features/narrator
flutter test test/features/onboarding
flutter test test/features/habits/presentation/providers
flutter test test/features/timeline
flutter test test/features/settings
flutter test test/features/social/presentation/screens
```

Expected: all pass. Fix any failures introduced by SP-A (tests asserting removed UI/state) — never `skip` them.

- [ ] **Step 3: Manual smoke checklist (device/web)**

1. Fresh install → timeline shows the node guide on first visit; Settings → Tutorials toggle off → guides stop appearing; toggle on → still seen (not shown again).
2. Avatar tap → coach dialog with ask field; free user: ask 3 times → 4th ask shows the premium limit dialog; Settings quota row shows 2/3 after one ask.
3. Complete a habit to a 7-day streak (or recover from a miss) → slide-up milestone card with the correct label.
4. Onboarding: pick an archetype → welcome milestone card; identity studio skip buttons still work.
5. Web: paywall untouched (SP-B), coach quota still works (premium false on web — expected).
6. `/profile/reflections` and `/goldilocks` now 404 (routes removed).

- [ ] **Step 4: Update the plan's task checkboxes + record handoff notes**

Mark every task `[x]` in this file; add a HANDOFF NOTE at the top documenting anything deferred.

- [ ] **Step 5: Final commit (any leftovers from SP-A only)**

```bash
git status --short   # review — only SP-A files should remain dirty
```

---

## Self-review notes (author)

- **Spec coverage:** §4.1 (avatar/coach/milestones/Oracle) → Tasks 7–10, 15; §4.2 (quota) → Tasks 1, 4, 6; §4.3 (tutorials + migration) → Tasks 2, 3, 5, 11, 12; §4.4 (settings) → Task 14; companion cleanup → Task 13; §6 inventory → all tasks. The `discover` node is ported (not dropped) because the blueprints page still lives until SP-F — the node entry documents that it dies with the page.
- **Consistency:** `PendingMilestoneLine` is introduced once (Task 10) and consumed consistently in timeline + identity studio; `coachAskQuotaControllerProvider` naming is used identically across Tasks 4, 8, 14; `NodeGuideHost` API (`nodeId` + `child`) is stable across Tasks 5, 11, 12.
- **Test updates:** tasks call out which existing tests to fix when removing UI (companion marks, old sheet layout, `PendingMilestone` state type, removed screens).
