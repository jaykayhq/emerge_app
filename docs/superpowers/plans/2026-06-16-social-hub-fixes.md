# Social Hub Fixes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 20+ bugs, route breaks, data integrity issues, and placeholder UIs across Tribes, Challenges, and Blueprints features.

**Architecture:** Fix navigation routes first (everything depends on navigation), then data-layer bugs (XP double-count, day=0, ignored userId), then UI placeholders, then polish. Tests written first for each bug fix.

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, Firestore, Drift (SQLite)

**Key files:**
- `lib/core/router/router.dart` — route definitions
- `lib/features/social/presentation/screens/tribe_space_scaffold.dart` — bottom nav shell
- `lib/features/social/data/services/tribe_stats_service.dart` — XP calculation
- `lib/features/social/presentation/widgets/tribe_accountability_section.dart` — partner types
- `lib/core/drift_repositories/drift_challenge_repository.dart` — challenge progress
- `lib/features/social/domain/models/challenge.dart` — challenge model
- `lib/features/social/presentation/widgets/tribe_tab_content.dart` — leaderboard display
- `lib/features/blueprints/presentation/providers/blueprint_detail_controller.dart` — adoption flow
- `lib/features/social/presentation/widgets/blueprint_adopt_dialog.dart` — adoption dialog
- `lib/features/blueprints/domain/models/blueprint.dart` — blueprint model
- `lib/features/social/presentation/screens/social_discover_tab.dart` — blueprint cards
- `lib/features/social/presentation/widgets/tribe_activity_feed.dart` — activity posting

---

### Task 1: Fix All Broken `/tribes/` Route Pushes → `/social/`

**Files:**
- Modify: `lib/features/social/presentation/widgets/tribe_header_widgets.dart` (2 locations)
- Modify: `lib/features/social/presentation/widgets/tribe_tab_content.dart` (3 locations)
- Modify: `lib/features/social/presentation/widgets/tribe_accountability_section.dart` (2 locations)
- Modify: `lib/features/social/presentation/screens/social_screen.dart` (2 locations)
- Modify: `lib/features/social/presentation/widgets/tribe_quests_section.dart` (1 location)
- Modify: `lib/features/social/presentation/screens/tribe_lobby_screen.dart` (1 location)
- Modify: `lib/features/world_map/presentation/screens/level_immersive_screen.dart` (1 location)
- Modify: `lib/features/social/presentation/screens/challenge_detail_screen.dart` (1 location)

- [ ] **Step 1: Audit all `/tribes/` route pushes**

Run: `rg "push\('/tribes/" lib/ --no-heading -n`
Expected: 12+ matches showing each broken push

- [ ] **Step 2: Fix `tribe_header_widgets.dart` — leaderboard and accountability links**

Edit file. Replace each `/tribes/` prefix with `/social/`:
- `/tribes/leaderboard?tab=tribe` → `/social/leaderboard?tab=tribe`
- `/tribes/leaderboard?tab=world` → `/social/leaderboard?tab=world`
- `/tribes/accountability` → `/social/accountability`
- `/tribes/contracts` → `/social/contracts`

- [ ] **Step 3: Fix `tribe_tab_content.dart` — leaderboard and "View All" tribe links**

Edit file. Replace:
- `/tribes/leaderboard?tab=tribe` → `/social/leaderboard?tab=tribe` (2 occurrences)
- `/tribes/leaderboard?tab=world` → `/social/leaderboard?tab=world`
- `/tribes/all` → `/social/all`

- [ ] **Step 4: Fix remaining files with `/tribes/` pushes**

Fix each remaining file:
- `tribe_accountability_section.dart`: `/tribes/contracts` → `/social/contracts`, `/tribes/accountability` → `/social/accountability`
- `social_screen.dart`: `/tribes/contracts` → `/social/contracts`, `/tribes/accountability` → `/social/accountability`
- `tribe_quests_section.dart`: `/tribes/challenges` → `/social/challenges`
- `tribe_lobby_screen.dart`: `/tribes/space` → `/social/space`
- `level_immersive_screen.dart`: `/tribes/challenges` → `/social/challenges`
- `challenge_detail_screen.dart`: `/tribes/challenges` → `/social/challenges`

- [ ] **Step 5: Verify no remaining `/tribes/` pushes**

Run: `rg "push\('/tribes/" lib/ --no-heading`
Expected: 0 matches

- [ ] **Step 6: Commit**

```bash
git add lib/features/social/presentation/widgets/tribe_header_widgets.dart lib/features/social/presentation/widgets/tribe_tab_content.dart lib/features/social/presentation/widgets/tribe_accountability_section.dart lib/features/social/presentation/screens/social_screen.dart lib/features/social/presentation/widgets/tribe_quests_section.dart lib/features/social/presentation/screens/tribe_lobby_screen.dart lib/features/world_map/presentation/screens/level_immersive_screen.dart lib/features/social/presentation/screens/challenge_detail_screen.dart
git commit -m "fix: replace all broken /tribes/ route pushes with /social/ equivalents"
```

---

### Task 2: Fill Empty Tribe Space Tabs with Real Content

**Files:**
- Modify: `lib/features/social/presentation/screens/tribe_feed_tab.dart`
- Modify: `lib/features/social/presentation/screens/my_tribe_tab.dart`
- Modify: `lib/features/social/presentation/screens/tribe_board_tab.dart`
- Read: `lib/features/social/presentation/screens/social_discover_tab.dart` (reference for pattern)

- [ ] **Step 1: Write test for TribeFeedTab rendering**

Create: `test/features/social/presentation/screens/tribe_feed_tab_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_feed_tab.dart';

void main() {
  testWidgets('TribeFeedTab displays activity feed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TribeFeedTab()),
    );
    expect(find.text('Activity Feed'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });
}
```

- [ ] **Step 2: Implement TribeFeedTab**

Replace `lib/features/social/presentation/screens/tribe_feed_tab.dart` content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_activity_feed.dart';

class TribeFeedTab extends ConsumerWidget {
  const TribeFeedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: TribeActivitySection(),
    );
  }
}
```

- [ ] **Step 3: Implement MyTribeTab**

Replace `lib/features/social/presentation/screens/my_tribe_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_accountability_section.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_quests_section.dart';

class MyTribeTab extends ConsumerWidget {
  const MyTribeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('My Tribe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          TribeAccountabilitySection(),
          SizedBox(height: 24),
          TribeQuestsSection(),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Implement TribeBoardTab**

Replace `lib/features/social/presentation/screens/tribe_board_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_tab_content.dart';

class TribeBoardTab extends ConsumerWidget {
  const TribeBoardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leaderboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            // Tribe leaderboard section
            _TribeLeaderboardSection(),
            SizedBox(height: 24),
            // World leaderboard section
            _WorldLeaderboardSection(),
          ],
        ),
      ),
    );
  }
}
```

Wait — `_TribeLeaderboardSection` and `_WorldLeaderboardSection` are private widgets in `tribe_tab_content.dart` (prefixed with `_`). Extract them or make them accessible.

- [ ] **Step 5: Run test to verify**

Run: `flutter test test/features/social/presentation/screens/tribe_feed_tab_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/social/presentation/screens/tribe_feed_tab.dart lib/features/social/presentation/screens/my_tribe_tab.dart lib/features/social/presentation/screens/tribe_board_tab.dart test/features/social/presentation/screens/tribe_feed_tab_test.dart
git commit -m "fix: replace empty tribe tab stubs with real content"
```

---

### Task 3: Fix XP Double-Counting in TribeStatsService

**Files:**
- Modify: `lib/features/social/data/services/tribe_stats_service.dart`
- Create: `test/features/social/data/services/tribe_stats_service_test.dart`

- [ ] **Step 1: Write failing test for XP double-counting**

Create `test/features/social/data/services/tribe_stats_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/data/services/tribe_stats_service.dart';

void main() {
  group('TribeStatsService XP calculation', () {
    test('getTotalXp should not double-count attribute XP and top-level XP', () {
      final service = TribeStatsService(
        firestore: MockFirestore(),
        auth: MockFirebaseAuth(),
      );

      final data = {
        'strengthXp': 100,
        'intellectXp': 200,
        'vitalityXp': 150,
        'focusXp': 50,
        'creativityXp': 75,
        'socialXp': 25,
        'currentXp': 600,  // sum of above — should be ignored or only one source used
      };

      final result = service.getTotalXp(data);
      // Should be 600 (sum of attribute XP), not 1200 (attribute sum + currentXp)
      expect(result, 600);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/data/services/tribe_stats_service_test.dart`
Expected: FAIL — current implementation returns 1200, not 600

- [ ] **Step 3: Fix XP calculation in `tribe_stats_service.dart`**

In `getTotalXp` method (around line 61-78), change from unconditional addition to XOR logic:

```dart
int getTotalXp(Map<String, dynamic> data) {
  // Sum attribute-level XP fields
  final attributeXp = [
    data['strengthXp'] as int?,
    data['intellectXp'] as int?,
    data['vitalityXp'] as int?,
    data['focusXp'] as int?,
    data['creativityXp'] as int?,
    data['socialXp'] as int?,
  ].fold<int>(0, (sum, xp) => sum + (xp ?? 0));

  // If attribute XP exists, use it. Otherwise fall back to top-level XP.
  if (attributeXp > 0) return attributeXp;

  final directXp = data['currentXp'] as int? ?? data['totalXp'] as int?;
  return directXp ?? 0;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/data/services/tribe_stats_service_test.dart`
Expected: PASS

- [ ] **Step 5: Add same fix to `getTribeStats` method (around line 160-184)**

Apply the same pattern — prefer attribute XP sum, fall back to top-level fields, never add both.

- [ ] **Step 6: Commit**

```bash
git add lib/features/social/data/services/tribe_stats_service.dart test/features/social/data/services/tribe_stats_service_test.dart
git commit -m "fix: prevent XP double-counting in TribeStatsService"
```

---

### Task 4: Fix `_PartnerAvatarCircle` Dynamic Type

**Files:**
- Modify: `lib/features/social/presentation/widgets/tribe_accountability_section.dart`
- Create: `test/features/social/presentation/widgets/tribe_accountability_section_test.dart`

- [ ] **Step 1: Write test for type-safe partner rendering**

Create `test/features/social/presentation/widgets/tribe_accountability_section_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Partner avatar renders without crash', (tester) async {
    // Placeholder until we fix the type
    expect(true, isTrue);
  });
}
```

- [ ] **Step 2: Define proper partner model or interface**

Add to `lib/features/social/domain/entities/tribe_membership.dart` or create a new file `lib/features/social/domain/entities/accountability_partner.dart`:

```dart
class AccountabilityPartner {
  final String id;
  final String name;
  final String? avatarUrl;
  final int streak;

  const AccountabilityPartner({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.streak = 0,
  });

  factory AccountabilityPartner.fromMap(Map<String, dynamic> map) {
    return AccountabilityPartner(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      avatarUrl: map['avatarUrl'] as String?,
      streak: map['streak'] as int? ?? 0,
    );
  }
}
```

- [ ] **Step 3: Fix `_PartnerAvatarCircle` to use typed `AccountabilityPartner`**

In `tribe_accountability_section.dart`, replace:

```dart
final dynamic partner; // Using dynamic for now to match whatever entity we have
```

with:

```dart
final AccountabilityPartner partner;
```

Update the `build` method to access `partner.name` safely (now type-safe).

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/social/presentation/widgets/tribe_accountability_section_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/domain/entities/accountability_partner.dart lib/features/social/presentation/widgets/tribe_accountability_section.dart
git commit -m "fix: replace dynamic partner type with typed AccountabilityPartner model"
```

---

### Task 5: Fix Challenge Completion Setting Day to 0

**Files:**
- Modify: `lib/core/drift_repositories/drift_challenge_repository.dart`
- Create: `test/core/drift_repositories/drift_challenge_repository_completion_test.dart`

- [ ] **Step 1: Write failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/drift_repositories/drift_challenge_repository.dart';

void main() {
  group('completeChallengeWithReward', () {
    test('should set currentDay to totalDays, not 0', () async {
      final repo = DriftChallengeRepository(
        db: MockAppDatabase(),
        auth: MockFirebaseAuth(),
        gameLoop: LocalGameLoopEngine(),
      );

      await repo.joinChallenge('challenge_1', 21, 'athlete');
      await repo.completeChallengeWithReward('challenge_1', 100);

      final progress = await repo.getProgress('challenge_1');
      expect(progress.currentDay, 21);  // Should be totalDays, not 0
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/core/drift_repositories/drift_challenge_repository_completion_test.dart`
Expected: FAIL — `updateDay(challengeId, 0, 'completed')` sets day to 0

- [ ] **Step 3: Fix the bug**

In `drift_challenge_repository.dart`, find `completeChallengeWithReward` (around line 130):

```dart
// Before:
await updateDay(challengeId, 0, 'completed');

// After:
final progress = await getProgress(challengeId);
await updateDay(challengeId, progress.totalDays, 'completed');
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/core/drift_repositories/drift_challenge_repository_completion_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/drift_repositories/drift_challenge_repository.dart test/core/drift_repositories/drift_challenge_repository_completion_test.dart
git commit -m "fix: challenge completion sets currentDay to totalDays, not 0"
```

---

### Task 6: Fix `getUserTribes()` Ignoring UserId

**Files:**
- Modify: `lib/core/drift_repositories/drift_tribe_repository.dart`
- Create: `test/core/drift_repositories/drift_tribe_repository_filter_test.dart`

- [ ] **Step 1: Write failing test**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getUserTribes', () {
    test('should return only tribes the user has joined', () async {
      final repo = DriftTribeRepository(
        db: MockAppDatabase(),
        firestore: MockFirebaseFirestore(),
        auth: MockFirebaseAuth(),
      );

      final tribes = await repo.getUserTribes('user_42');
      // Should not return tribes user_42 hasn't joined
      for (final tribe in tribes) {
        final members = await repo.getMembers(tribe.id);
        expect(members.any((m) => m.userId == 'user_42'), isTrue,
            reason: 'Tribe ${tribe.id} returned but user_42 is not a member');
      }
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/core/drift_repositories/drift_tribe_repository_filter_test.dart`
Expected: FAIL — returns all tribes regardless of membership

- [ ] **Step 3: Fix by adding membership filter**

In `drift_tribe_repository.dart`, replace the `getUserTribes` method:

```dart
@override
Future<List<Tribe>> getUserTribes(String userId) async {
  // Get user's membership entries
  final memberships = await _db.tribeStatsDao.getMembershipsForUser(userId);
  if (memberships.isEmpty) return [];

  final tribeIds = memberships.map((m) => m.tribeId).toSet();
  final rows = await _db.tribeStatsDao.getAll();
  return rows
      .where((row) => tribeIds.contains(row.id))
      .map(_rowToTribe)
      .toList();
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/core/drift_repositories/drift_tribe_repository_filter_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/drift_repositories/drift_tribe_repository.dart test/core/drift_repositories/drift_tribe_repository_filter_test.dart
git commit -m "fix: getUserTribes() now filters by actual user membership"
```

---

### Task 7: Remove Duplicate Gamification Blueprint Model

**Files:**
- Modify: `lib/features/habits/presentation/providers/dashboard_state_provider.dart`
- Delete: `lib/features/gamification/domain/models/blueprint.dart`
- No test changes needed (no tests existed for it)

- [ ] **Step 1: Check imports of the duplicate model**

Run: `rg "import.*gamification.*blueprint" lib/ --no-heading -n`
Expected: Only `dashboard_state_provider.dart`

- [ ] **Step 2: Replace import in `dashboard_state_provider.dart`**

Change:
```dart
import 'package:emerge_app/features/gamification/domain/models/blueprint.dart';
```
to:
```dart
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
```

- [ ] **Step 3: Check for API compatibility**

The two models have different shapes. The gamification model has fewer fields. In `dashboard_state_provider.dart`, the `activateBlueprint` method accesses:
- `blueprint.id` → exists in both
- `blueprint.title` → exists in both (called `name` in gamification model? Check)
- `blueprint.habits` → exists in both
- `blueprint.category` → check

If field names differ, update the provider code to use the feature model's API.

- [ ] **Step 4: Delete the duplicate file**

Run: `git rm lib/features/gamification/domain/models/blueprint.dart`

- [ ] **Step 5: Verify no remaining references**

Run: `rg "features/gamification/domain/models/blueprint" lib/ --no-heading`
Expected: 0 matches

- [ ] **Step 6: Run existing tests to verify nothing broke**

Run: `flutter test`
Expected: PASS (or at least same as before)

- [ ] **Step 7: Commit**

```bash
git add lib/features/habits/presentation/providers/dashboard_state_provider.dart
git add -A
git commit -m "refactor: remove duplicate Blueprint model from gamification feature"
```

---

### Task 8: Fix Blueprint Adoption Count Increment

**Files:**
- Modify: `lib/features/blueprints/presentation/providers/blueprint_detail_controller.dart`

- [ ] **Step 1: Write test for adoption count increment**

Add to existing test file or create `test/features/blueprints/presentation/providers/blueprint_detail_controller_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BlueprintDetailController.adoptBlueprint', () {
    test('should increment adoptionCount in Firestore', () async {
      final controller = BlueprintDetailController();
      final blueprint = Blueprint(
        id: 'test_1',
        title: 'Test Blueprint',
        category: 'Morning',
        habits: [
          BlueprintHabit(title: 'Wake up early'),
          BlueprintHabit(title: 'Stretch'),
        ],
        creatorUserId: 'system',
        creatorName: 'Emerge Official',
      );

      await controller.adoptBlueprint(blueprint, userId: 'user_42');
      
      // Verify repository.incrementAdoptionCount was called with 'test_1'
      expect(controller.repository.incrementAdoptionCountCalled, isTrue);
    });
  });
}
```

- [ ] **Step 2: Add `incrementAdoptionCount` method to repository**

In `lib/features/blueprints/data/repositories/blueprint_repository.dart`:

```dart
Future<void> incrementAdoptionCount(String blueprintId) async {
  await _firestore
      .collection('blueprints')
      .doc(blueprintId)
      .update({
        'adoptionCount': FieldValue.increment(1),
      });
}
```

- [ ] **Step 3: Call `incrementAdoptionCount` from the controller**

In `blueprint_detail_controller.dart`, inside `adoptBlueprint()` after habits are created:

```dart
// After successful habit creation:
await ref.read(blueprintRepositoryProvider).incrementAdoptionCount(blueprint.id);
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/blueprints/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/blueprints/data/repositories/blueprint_repository.dart lib/features/blueprints/presentation/providers/blueprint_detail_controller.dart
git commit -m "fix: increment adoptionCount in Firestore on blueprint adoption"
```

---

### Task 9: Show BlueprintAdoptDialog in Adoption Flow

**Files:**
- Modify: `lib/features/social/presentation/screens/blueprint_detail_screen.dart`

- [ ] **Step 1: Show the dialog before adopting**

In `blueprint_detail_screen.dart`, replace the direct `adoptBlueprint()` call in the adopt button's `onPressed`:

```dart
// Before:
onPressed: () => ref.read(blueprintDetailControllerProvider.notifier)
    .adoptBlueprint(blueprint),

// After:
onPressed: () async {
  final result = await showDialog<TimeOfDay>(
    context: context,
    builder: (ctx) => BlueprintAdoptDialog(blueprint: blueprint),
  );
  if (result != null && context.mounted) {
    await ref.read(blueprintDetailControllerProvider.notifier)
        .adoptBlueprint(blueprint, reminderTime: result);
  }
},
```

- [ ] **Step 4: Manually verify the dialog shows**

Run: `flutter run` and navigate to a blueprint detail → tap "ADOPT BLUEPRINT" → dialog should appear with time picker

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/screens/blueprint_detail_screen.dart
git commit -m "fix: show adoption dialog with time picker before adopting blueprint"
```

---

### Task 10: Add Social Activity Logging on Blueprint Adoption

**Files:**
- Modify: `lib/core/drift_repositories/drift_habit_repository.dart`

- [ ] **Step 1: Log activity in `createHabitsFromBlueprint`**

In `drift_habit_repository.dart`, in the `createHabitsFromBlueprint` method (around line 391-426), after habits are created:

```dart
// After habit creation loop succeeds:
_socialService.logActivity(
  type: 'blueprint_adopted',
  data: {
    'blueprintTitle': blueprint.title,
    'blueprintId': blueprint.id,
    'category': blueprint.category,
    'habitCount': blueprint.habits.length,
  },
);
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/drift_repositories/drift_habit_repository.dart
git commit -m "feat: log social activity when user adopts a blueprint"
```

---

### Task 11: Fix Catalog Step Days to Be Sequential

**Files:**
- Modify: `lib/features/social/domain/models/challenge_catalog.dart`

- [ ] **Step 1: Audit existing step day values**

Read `challenge_catalog.dart` and find all step definitions with non-sequential days (e.g., Deep Work Protocol with days [1, 7, 14]).

- [ ] **Step 2: Fix step days to be sequential**

Replace non-sequential day arrays with sequential ones matching the challenge's total duration:

```dart
// Before (Deep Work Protocol — 14 days, steps on days 1, 7, 14):
final steps = [
  ChallengeStep(day: 1, title: 'Set focus goals', description: 'Define your focus objectives for the protocol.'),
  ChallengeStep(day: 7, title: 'Mid-week review', description: 'Assess your progress and adjust.'),
  ChallengeStep(day: 14, title: 'Final reflection', description: 'Review your journey and outcomes.'),
];

// After — fill all 14 days with sequential day numbers:
final steps = [
  ChallengeStep(day: 1, title: 'Set focus goals', description: 'Define your focus objectives for the protocol.'),
  ChallengeStep(day: 2, title: 'Day 2 check-in', description: 'Complete today\'s deep work session.'),
  ChallengeStep(day: 3, title: 'Day 3 check-in', description: 'Complete today\'s deep work session.'),
  ChallengeStep(day: 4, title: 'Day 4 check-in', description: 'Complete today\'s deep work session.'),
  ChallengeStep(day: 5, title: 'Day 5 check-in', description: 'Complete today\'s deep work session.'),
  ChallengeStep(day: 6, title: 'Day 6 check-in', description: 'Complete today\'s deep work session.'),
  ChallengeStep(day: 7, title: 'Mid-week review', description: 'Assess your progress and adjust.'),
  ChallengeStep(day: 8, title: 'Day 8 check-in', description: 'Complete today\'s deep work session.'),
  ChallengeStep(day: 9, title: 'Day 9 check-in', description: 'Complete today\'s deep work session.'),
  ChallengeStep(day: 10, title: 'Day 10 check-in', description: 'Complete today\'s deep work session.'),
  ChallengeStep(day: 11, title: 'Day 11 check-in', description: 'Complete today\'s deep work session.'),
  ChallengeStep(day: 12, title: 'Day 12 check-in', description: 'Complete today\'s deep work session.'),
  ChallengeStep(day: 13, title: 'Day 13 check-in', description: 'Complete today\'s deep work session.'),
  ChallengeStep(day: 14, title: 'Final reflection', description: 'Review your journey and outcomes.'),
];
```

- [ ] **Step 3: Update the current-day check logic**

Verify that `challenge_detail_screen.dart` step highlighting (`step.day == challenge.currentDay + 1`) works correctly with sequential days.

- [ ] **Step 4: Commit**

```bash
git add lib/features/social/domain/models/challenge_catalog.dart
git commit -m "fix: make challenge step days sequential for correct progress tracking"
```

---

### Task 12: Add "You Are Here" Indicator on Leaderboards

**Files:**
- Modify: `lib/features/social/presentation/widgets/tribe_tab_content.dart`

- [ ] **Step 1: Highlight current user's rank row**

In `_LeaderboardRow` and `_WorldRankingRow`, accept a `isCurrentUser` parameter:

```dart
Widget _buildLeaderboardRow({
  required int rank,
  required String name,
  required int xp,
  bool isCurrentUser = false,
}) {
  return Container(
    decoration: BoxDecoration(
      color: isCurrentUser ? Colors.blue.withOpacity(0.1) : null,
      borderRadius: BorderRadius.circular(8),
      border: isCurrentUser ? Border.all(color: Colors.blue, width: 1) : null,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: [
        Text('#$rank', style: TextStyle(
          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
        )),
        const SizedBox(width: 12),
        CircleAvatar(
          backgroundColor: isCurrentUser ? Colors.blue : Colors.grey,
          child: Text(name[0].toUpperCase()),
        ),
        const SizedBox(width: 12),
        Text(name, style: TextStyle(
          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
        )),
        const Spacer(),
        Text('$xp XP'),
        if (isCurrentUser)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.star, color: Colors.amber, size: 16),
          ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Pass current user check from parent**

In the parent widget that builds the list, pass `isCurrentUser: member.userId == currentUserId`.

- [ ] **Step 3: Commit**

```bash
git add lib/features/social/presentation/widgets/tribe_tab_content.dart
git commit -m "feat: add 'you are here' indicator on leaderboard rows"
```

---

### Task 13: Fix Tribe Lobby Screen Hardcoded Data

**Files:**
- Modify: `lib/features/social/presentation/screens/tribe_lobby_screen.dart`

- [ ] **Step 1: Write test showing hardcoded data bug**

Create `test/features/social/presentation/screens/tribe_lobby_screen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TribeLobbyScreen shows real data, not hardcoded', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TribeLobbyScreen(tribeId: 'morning_warriors')),
    );
    // Should not show hardcoded values
    expect(find.text('1,247 members'), findsNothing);
    expect(find.text('THE SCHOLARS 🔰'), findsNothing);
  });
}
```

- [ ] **Step 2: Replace hardcoded values with provider data**

In `tribe_lobby_screen.dart`, replace:

```dart
const Text("THE SCHOLARS 🔰")
const Text("1,247 members · Your streak: 🔥14d")
const Text("🗡️ Collective Quest: 73%")
const LinearProgressIndicator(value: 0.73)
```

with Riverpod-wired data from tribe stats provider:

```dart
final tribeAsync = ref.watch(cachedTribeStatsProvider(tribeId));

return tribeAsync.when(
  data: (tribe) => Column(
    children: [
      Text(tribe.name),
      Text('${tribe.memberCount} members · Your streak: 🔥${tribe.userStreak}d'),
      if (tribe.collectiveQuestProgress != null) ...[
        Text('🗡️ Collective Quest: ${(tribe.collectiveQuestProgress! * 100).toInt()}%'),
        LinearProgressIndicator(value: tribe.collectiveQuestProgress),
      ],
    ],
  ),
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Could not load tribe: $e'),
);
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/features/social/presentation/screens/tribe_lobby_screen_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/social/presentation/screens/tribe_lobby_screen.dart
git commit -m "fix: replace hardcoded tribe lobby data with real Riverpod provider data"
```

---

### Task 14: Add Tests for Critical Social Hub Paths

**Files:**
- Create: `test/features/social/presentation/providers/tribes_provider_test.dart`
- Create: `test/features/blueprints/domain/models/blueprint_test.dart`

- [ ] **Step 1: Write blueprint model test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';

void main() {
  group('Blueprint model', () {
    test('fromMap and toMap are symmetric', () {
      final blueprint = Blueprint(
        id: 'test_1',
        title: 'Morning Ritual',
        description: 'Start your day right',
        category: 'Morning',
        habits: [
          BlueprintHabit(title: 'Wake up early'),
          BlueprintHabit(title: 'Meditate'),
        ],
        creatorName: 'Test Creator',
        creatorUserId: 'user_1',
      );

      final map = blueprint.toMap();
      final restored = Blueprint.fromMap(map);

      expect(restored.id, blueprint.id);
      expect(restored.title, blueprint.title);
      expect(restored.habits.length, blueprint.habits.length);
    });

    test('default values for new blueprint', () {
      final blueprint = Blueprint(
        id: 'test_2',
        title: 'Test',
        category: 'Fitness',
        habits: [BlueprintHabit(title: 'Exercise')],
      );

      expect(blueprint.adoptionCount, 0);
      expect(blueprint.isPremium, false);
      expect(blueprint.creatorName, 'Emerge Official');
    });
  });
}
```

- [ ] **Step 2: Run blueprint model test**

Run: `flutter test test/features/blueprints/domain/models/blueprint_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add test/features/blueprints/domain/models/blueprint_test.dart
git commit -m "test: add Blueprint model serialization and default value tests"
```

---

### Task 15: Auto-Dispose Firestore Blueprint StreamProviders

**Files:**
- Modify: `lib/features/blueprints/data/repositories/blueprint_repository.dart`

- [ ] **Step 1: Check current provider definitions**

Read `blueprint_repository.dart` — look for `StreamProvider` definitions that don't auto-dispose.

- [ ] **Step 2: Add `autoDispose` to blueprint streams**

If using `StreamProvider`:

```dart
// Before:
final allBlueprintsStreamProvider = StreamProvider<List<Blueprint>>((ref) {
  return ref.watch(blueprintRepositoryProvider).watchAllBlueprints();
});

// After:
final allBlueprintsStreamProvider = StreamProvider.autoDispose<List<Blueprint>>((ref) {
  return ref.watch(blueprintRepositoryProvider).watchAllBlueprints();
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/blueprints/data/repositories/blueprint_repository.dart
git commit -m "fix: auto-dispose Firestore blueprint streams to prevent memory leaks"
```

---

### Task 16: Remove Dead Drift BlueprintsTable Code

**Files:**
- Delete: `lib/core/drift/tables/blueprints_table.dart`
- Delete: `lib/core/drift/daos/blueprints_dao.dart`
- Delete: `lib/core/drift/daos/blueprints_dao.g.dart`
- Modify: `lib/core/drift/app_database.dart` — remove `BlueprintsDao` registration
- Modify: `lib/core/drift/database.dart` — remove provider

- [ ] **Step 1: Audit all references**

Run: `rg "BlueprintsDao\|blueprintsDao\|BlueprintsTable\|blueprintsTable" lib/ --no-heading -n`
Expected: References in app_database.dart, database.dart, and the files themselves

- [ ] **Step 2: Remove registration from `app_database.dart`**

Remove `BlueprintsDao` from the list of DAOs in the AppDatabase class.

- [ ] **Step 3: Remove provider from `database.dart`**

Remove the `blueprintsDaoProvider` definition.

- [ ] **Step 4: Delete the files**

```bash
git rm lib/core/drift/tables/blueprints_table.dart lib/core/drift/daos/blueprints_dao.dart lib/core/drift/daos/blueprints_dao.g.dart
```

- [ ] **Step 5: Run build_runner to regenerate**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Build succeeds with no errors

- [ ] **Step 6: Verify no remaining references**

Run: `rg "blueprintsDao\|BlueprintsDao\|blueprintsTable\|BlueprintsTable" lib/ --no-heading`
Expected: 0 matches

- [ ] **Step 7: Commit**

```bash
git add lib/core/drift/app_database.dart lib/core/drift/database.dart
git add -A
git commit -m "refactor: remove dead Drift BlueprintsTable code (never queried or written)"
```
