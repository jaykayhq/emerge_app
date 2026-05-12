# Quest, Blueprint & Habit Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix quest routing/categorization, blueprint categories/adoption message, and habit limit/upgrade bug

**Architecture:** Four independent groups of changes: habit limit constants + upgrade bug fix, blueprint seed data + UI, quest data model getters, quest screen routing + filtering. Each group modifies isolated files.

**Tech Stack:** Flutter, Dart, Firebase Firestore, Riverpod

---

### Task 1: Change habit limit from 3 to 5

**Files:**
- Modify: `lib/core/services/remote_config_service.dart:22`
- Modify: `lib/features/habits/presentation/providers/habit_providers.dart:24`

- [ ] **Step 1: Change Remote Config default**

In `remote_config_service.dart`, line 22, change `'free_habit_limit': 3` to `'free_habit_limit': 5`

```dart
// Before:
'free_habit_limit': 3,
// After:
'free_habit_limit': 5,
```

- [ ] **Step 2: Change code fallback constant**

In `habit_providers.dart`, line 24, change `const int kDefaultFreeHabitLimit = 3` to `const int kDefaultFreeHabitLimit = 5`

```dart
// Before:
const int kDefaultFreeHabitLimit = 3;
// After:
const int kDefaultFreeHabitLimit = 5;
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/remote_config_service.dart lib/features/habits/presentation/providers/habit_providers.dart
git commit -m "feat: increase free habit limit from 3 to 5"
```

---

### Task 2: Fix upgrade dialog showing incorrectly

**Files:**
- Modify: `lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart:254-273`

**Rationale:** Remove the dialog-side duplicate limit check. The provider (`createHabit`) already enforces the limit and throws `SubscriptionLimitReachedException`, which is caught by the existing catch block at line 310-319 and shows the same PremiumLimitDialog. The dialog-side check has a race condition where `habitsProvider.value` hasn't loaded yet, causing the check to incorrectly pass (empty list → `0 >= 5` = false) when the user IS at the limit, or to show when the data is stale.

- [ ] **Step 1: Remove duplicate limit check from `_saveHabit()`**

In `advanced_create_habit_dialog.dart`, remove lines 254-273 (the proactive limit check block) so the flow goes directly from constructing the Habit to calling the provider.

```dart
// Remove this entire block (lines 254-273):
      try {
        // PROACTIVE CHECK: Check limit before calling provider to avoid "Bad state" on disposal
        final isPremium = await ref.read(isPremiumProvider.future);
        if (!isPremium) {
          final habits = ref.read(habitsProvider).value ?? [];
          final freeLimit = ref.read(remoteConfigServiceProvider).freeHabitLimit;
          
          if (habits.length >= freeLimit) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => const PremiumLimitDialog(
                  title: 'Habit Capacity Reached',
                  message: 'You have reached the free limit of habits. Upgrade to Premium for unlimited growth.',
                ),
              );
            }
            return;
          }
        }
```

The `try {` that follows at line 254 (now the outer try) should remain — it wraps the `ref.read(createHabitProvider...).future` call and the existing catch blocks handle the `SubscriptionLimitReachedException`.

Before the change, the flow is:
```dart
try {
  // PROACTIVE CHECK: remove this entire block
  
  await ref.read(createHabitProvider(newHabit).future);
  // ... rest of success flow
} on SubscriptionLimitReachedException catch (e) {
  // This catch handler handles the provider-level limit check
  // ... shows PremiumLimitDialog
} catch (e, s) {
  // ... error handler
}
```

After the change, it becomes:
```dart
try {
  await ref.read(createHabitProvider(newHabit).future);
  // ... rest of success flow
} on SubscriptionLimitReachedException catch (e) {
  // This still handles the provider-level limit check
  // ... shows PremiumLimitDialog
} catch (e, s) {
  // ... error handler
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart
git commit -m "fix: remove duplicate habit limit check in dialog, rely on provider"
```

---

### Task 3: Change blueprint adoption snackbar message

**Files:**
- Modify: `lib/features/social/presentation/screens/blueprint_detail_screen.dart:277-283`

- [ ] **Step 1: Change the snackbar message**

In `blueprint_detail_screen.dart`, line 277-283, change the success snackbar from verbose to concise:

```dart
// Before:
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text(
        'Blueprint adopted! Your new habit stack is ready.'),
    backgroundColor: EmergeColors.teal,
  ),
);
// After:
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Adopted successfully'),
    backgroundColor: EmergeColors.teal,
  ),
);
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/social/presentation/screens/blueprint_detail_screen.dart
git commit -m "fix: shorten blueprint adoption snackbar message"
```

---

### Task 4: Update blueprint categories and seed data

**Files:**
- Modify: `lib/features/blueprints/data/repositories/blueprint_repository.dart:42-277`
- Modify: `lib/features/social/presentation/screens/social_discover_tab.dart:256-274`

- [ ] **Step 1: Replace archetype seed data with non-archetype categories**

In `blueprint_repository.dart`, replace the seed data (lines 42-277) with 25 new blueprints across 5 categories: Morning, Productivity, Fitness, Mindfulness, Learning. Each category has 5 blueprints.

```dart
      final List<Blueprint> seedData = [
        // MORNING
        _createSeed(
          id: 'morning_1',
          category: 'Morning',
          title: 'Sunrise Ritual',
          description: 'Start your day with intention, light, and hydration.',
          image: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Wake Up at 6 AM', 'Drink 500ml Water', '10 Min Sunlight Exposure'],
        ),
        _createSeed(
          id: 'morning_2',
          category: 'Morning',
          title: 'Power Morning',
          description: 'An energizing morning routine to dominate your day.',
          image: 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Cold Shower', 'Stretch Routine', 'High-Protein Breakfast'],
        ),
        _createSeed(
          id: 'morning_3',
          category: 'Morning',
          title: 'Mindful Awakening',
          description: 'Ease into the day with calm and clarity.',
          image: 'https://images.unsplash.com/photo-1545205597-3d9d02e29597?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['5 Min Meditation', 'Gratitude Journal', 'Herbal Tea'],
        ),
        _createSeed(
          id: 'morning_4',
          category: 'Morning',
          title: 'Early Bird Stack',
          description: 'Rise before the world and claim your quiet hours.',
          image: 'https://images.unsplash.com/photo-1490818387583-1baba5e638af?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Wake at 5 AM', 'Deep Work Block', 'No Phone for 1 Hour'],
        ),
        _createSeed(
          id: 'morning_5',
          category: 'Morning',
          title: 'Morning Mobility',
          description: 'Loosen up and prepare your body for the day ahead.',
          image: 'https://images.unsplash.com/photo-1552196563-55cd4e45efb3?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Dynamic Stretching', 'Foam Rolling', 'Posture Check'],
        ),

        // PRODUCTIVITY
        _createSeed(
          id: 'productivity_1',
          category: 'Productivity',
          title: 'Deep Work Protocol',
          description: 'Train your focus for uninterrupted deep work sessions.',
          image: 'https://images.unsplash.com/photo-1483058712412-4245e9b90334?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['90 Min Deep Work', 'Phone on DND', 'Task Batching'],
        ),
        _createSeed(
          id: 'productivity_2',
          category: 'Productivity',
          title: 'The Ivy Lee Method',
          description: 'A century-old productivity system for daily prioritization.',
          image: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Write Top 6 Tasks', 'Prioritize by Importance', 'Complete One at a Time'],
        ),
        _createSeed(
          id: 'productivity_3',
          category: 'Productivity',
          title: 'Time Block Master',
          description: 'Schedule every hour of your day with purpose.',
          image: 'https://images.unsplash.com/photo-1506784983877-45594efa4cbe?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Plan Tomorrow Tonight', 'Time Block Calendar', 'Review & Reflect'],
        ),
        _createSeed(
          id: 'productivity_4',
          category: 'Productivity',
          title: 'Digital Declutter',
          description: 'Clear digital noise and reclaim your attention.',
          image: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Unsubscribe from Junk', 'Organize Files', 'App Purge'],
        ),
        _createSeed(
          id: 'productivity_5',
          category: 'Productivity',
          title: 'Pomodoro Flow',
          description: 'Harness the Pomodoro technique for sustained output.',
          image: 'https://images.unsplash.com/photo-1499750310107-5fef28a66643?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['25 Min Focus Sprint', '5 Min Break', 'Track Pomodoros'],
        ),

        // FITNESS
        _createSeed(
          id: 'fitness_1',
          category: 'Fitness',
          title: 'Bodyweight Foundation',
          description: 'Build strength with just your body weight.',
          image: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Push-Ups', 'Bodyweight Squats', 'Plank Hold'],
        ),
        _createSeed(
          id: 'fitness_2',
          category: 'Fitness',
          title: 'Cardio Builder',
          description: 'Improve cardiovascular endurance step by step.',
          image: 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['20 Min Run', 'Jump Rope', 'Cool Down Stretch'],
        ),
        _createSeed(
          id: 'fitness_3',
          category: 'Fitness',
          title: 'Flexibility & Mobility',
          description: 'Increase range of motion and prevent injury.',
          image: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Hamstring Stretch', 'Hip Openers', 'Spine Twists'],
        ),
        _createSeed(
          id: 'fitness_4',
          category: 'Fitness',
          title: 'Iron Will',
          description: 'A progressive strength training blueprint.',
          image: 'https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Deadlifts', 'Overhead Press', 'Pull-Ups'],
        ),
        _createSeed(
          id: 'fitness_5',
          category: 'Fitness',
          title: 'Active Recovery',
          description: 'Rest days that keep you moving and healing.',
          image: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Brisk Walk', 'Light Yoga', 'Hydration Focus'],
        ),

        // MINDFULNESS
        _createSeed(
          id: 'mindfulness_1',
          category: 'Mindfulness',
          title: 'Daily Meditation',
          description: 'Build a consistent meditation practice from scratch.',
          image: 'https://images.unsplash.com/photo-1508672019048-805c876b67e2?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['5 Min Breath Focus', 'Body Scan', 'Loving Kindness'],
        ),
        _createSeed(
          id: 'mindfulness_2',
          category: 'Mindfulness',
          title: 'Digital Sabbath',
          description: 'Weekly disconnection to recharge your mind.',
          image: 'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['No Screens for 4 Hours', 'Nature Walk', 'Analog Activity'],
        ),
        _createSeed(
          id: 'mindfulness_3',
          category: 'Mindfulness',
          title: 'Gratitude Practice',
          description: 'Rewire your brain for appreciation and abundance.',
          image: 'https://images.unsplash.com/photo-1489710437720-ebb67ec84dd2?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Write 3 Gratitudes', 'Thank Someone', 'Savor a Moment'],
        ),
        _createSeed(
          id: 'mindfulness_4',
          category: 'Mindfulness',
          title: 'Stress Shield',
          description: 'Daily practices to build resilience against stress.',
          image: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Box Breathing', 'Progressive Relaxation', 'Journaling'],
        ),
        _createSeed(
          id: 'mindfulness_5',
          category: 'Mindfulness',
          title: 'Evening Wind Down',
          description: 'A calming ritual to signal your body it is time to rest.',
          image: 'https://images.unsplash.com/photo-1511295742362-92c96b1cf484?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['No Screens 30 Min Before Bed', 'Tidy Your Space', 'Read Fiction'],
        ),

        // LEARNING
        _createSeed(
          id: 'learning_1',
          category: 'Learning',
          title: 'Daily Reader',
          description: 'Read consistently and compound knowledge.',
          image: 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Read 20 Pages', 'Take Notes', 'Summarize Key Idea'],
        ),
        _createSeed(
          id: 'learning_2',
          category: 'Learning',
          title: 'Skill Sprint',
          description: 'Learn a new skill with focused daily practice.',
          image: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['30 Min Deliberate Practice', 'Track Progress', 'Review Mistakes'],
        ),
        _createSeed(
          id: 'learning_3',
          category: 'Learning',
          title: 'Curious Mind',
          description: 'Feed your curiosity across diverse topics.',
          image: 'https://images.unsplash.com/photo-1507842217343-583bb7270b66?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Watch a Documentary', 'Read One Article', 'Discuss What You Learned'],
        ),
        _createSeed(
          id: 'learning_4',
          category: 'Learning',
          title: 'Memory Master',
          description: 'Strengthen recall with spaced repetition.',
          image: 'https://images.unsplash.com/photo-1517077304055-6e89abbf09b0?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Review Flashcards', 'Teach Someone', 'Active Recall Session'],
        ),
        _createSeed(
          id: 'learning_5',
          category: 'Learning',
          title: 'Course Completer',
          description: 'Finish online courses with structure and accountability.',
          image: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Watch One Lesson', 'Do the Assignment', 'Write Reflection'],
        ),
      ];
```

- [ ] **Step 2: Remove archetype badge from blueprint cards**

In `social_discover_tab.dart`, remove the archetype badge overlay from `_BlueprintStripCard` (lines 256-275):

```dart
// Remove this entire Positioned block (lines 256-275):
                    // Badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          blueprint.creatorArchetype.toUpperCase(),
                          style: const TextStyle(
                            color: EmergeColors.teal,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
```

- [ ] **Step 3: Update `_createSeed` to match new categories**

The `_createSeed` method already uses `category` as the `creatorArchetype` (line 304: `creatorArchetype: category`). Since new categories are non-archetype, update `_createSeed` to set `creatorArchetype` to a generic value like `'Emerge'`:

In `blueprint_repository.dart`, line 304, change:
```dart
// Before:
creatorArchetype: category,
// After:
creatorArchetype: 'Emerge',
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/blueprints/data/repositories/blueprint_repository.dart lib/features/social/presentation/screens/social_discover_tab.dart
git commit -m "feat: replace archetype blueprint categories with action-oriented categories"
```

---

### Task 5: Update ChallengeBundleData with proper category getters

**Files:**
- Modify: `lib/features/social/domain/models/challenge_bundle.dart`

- [ ] **Step 1: Add category-based getters**

In `challenge_bundle.dart`, add new getters to `ChallengeBundleData` for proper category separation:

```dart
  /// Active daily quest from user's joined challenges
  Challenge? get activeDailyChallenge =>
      userChallenges.cast<Challenge?>().firstWhere(
        (c) => c != null && c.status == ChallengeStatus.active && c.category == ChallengeCategory.all || c.category == ChallengeCategory.fitness,
        orElse: () => null,
      );

  /// Active weekly spotlight from user's joined challenges
  Challenge? get activeWeeklyChallenge =>
      userChallenges.cast<Challenge?>().firstWhere(
        (c) => c != null && c.status == ChallengeStatus.active && c.category != ChallengeCategory.all && c.category != ChallengeCategory.fitness,
        orElse: () => null,
      );

  /// Solo challenges that are active (not daily, not weekly)
  @override
  List<Challenge> get activeSoloChallenges =>
      userChallenges.where((c) => c.status == ChallengeStatus.active).toList();
```

Wait — I need to understand how challenges are categorized. Looking at the model:

`ChallengeCategory` enum has: `all`, `fitness`, `mindfulness`, `learning`, `nutrition`, `productivity`, `creative`, `faith`.

But in practice, quests/challenges have specific categories for the catalog templates:
- Daily quests are generated daily
- Weekly spotlights are generated weekly
- Solo quests are user-created or from archetype challenges

Actually, looking at `ChallengeCatalog` — the category system is different from the "solo/daily/weekly" classification. The "solo/daily/weekly" is a UX classification, not a data field on the Challenge model.

Let me reconsider. Looking at how challenges are classified:

1. **Daily Quest**: From `bundle.dailyQuest` — a single challenge, determined by `ChallengeCatalog.getDailyQuest()`
2. **Weekly Spotlight**: From `bundle.weeklySpotlight` — a single challenge, determined by `ChallengeCatalog.getWeeklySpotlight()`
3. **Solo Quests**: From `bundle.activeSoloChallenges` — user's joined challenges

When a user joins the daily quest or weekly spotlight, it goes into `userChallenges` (Firestore). But the daily quest and weekly spotlight are also shown from the catalog.

The key insight: we need to compare by ID. If the user has joined a challenge with the same ID as the daily quest, that's the active daily quest.

So the proper approach is:

```dart
  /// Whether the daily quest has been joined by the user
  bool get isDailyQuestJoined => dailyQuest != null && 
      userChallenges.any((c) => c.id == dailyQuest!.id);
      
  /// Whether the weekly spotlight has been joined by the user
  bool get isWeeklySpotlightJoined => weeklySpotlight != null && 
      userChallenges.any((c) => c.id == weeklySpotlight!.id);
```

This is simpler and more accurate. The screen can then decide what to show.

- [ ] **Step 2: Commit**

```bash
git add lib/features/social/domain/models/challenge_bundle.dart
git commit -m "feat: add joined status getters to ChallengeBundleData"
```

---

### Task 6: Update ChallengeDetailScreen to route to challenges tab after joining

**Files:**
- Modify: `lib/features/social/presentation/screens/challenge_detail_screen.dart:476-479`

- [ ] **Step 1: Change post-join navigation**

In `challenge_detail_screen.dart`, line 478, change `context.pop()` to `context.go('/tribes/challenges')`:

```dart
// Before:
if (context.mounted) {
  _showSuccess(context, 'QUEST STARTED! (+25 XP)');
  context.pop();
}
// After:
if (context.mounted) {
  _showSuccess(context, 'QUEST STARTED! (+25 XP)');
  context.go('/tribes/challenges');
}
```

Add the import for `go_router` — it's already imported on line 14: `import 'package:go_router/go_router.dart';`

- [ ] **Step 2: Commit**

```bash
git add lib/features/social/presentation/screens/challenge_detail_screen.dart
git commit -m "feat: route to challenges tab after joining a quest"
```

---

### Task 7: Update ChallengesScreen to separate categories and hide joined featured quests

**Files:**
- Modify: `lib/features/social/presentation/screens/challenges_screen.dart:203-261,294-384`

- [ ] **Step 1: Hide featured weekly spotlight if user has joined it**

In `_WeeklySpotlightSection`, check if the user has already joined the weekly spotlight. If joined, don't show the featured version (the active version will show in its category section).

Update `_WeeklySpotlightSection` to become a `ConsumerStatefulWidget` (or ConsumerWidget) that checks user challenges:

```dart
class _WeeklySpotlightSection extends ConsumerWidget {
  final ChallengeBundleData? bundle;

  const _WeeklySpotlightSection({this.bundle});

  @override
  Widget build(BuildContext context) {
    final challenge = bundle?.weeklySpotlight;
    final userChallenges = bundle?.userChallenges ?? [];

    if (challenge == null) return const _EmptySpotlightCard();
    
    // If user has already joined this challenge, don't show it as featured
    final isJoined = userChallenges.any((c) => c.id == challenge.id);
    if (isJoined) return const SizedBox.shrink();

    return QuestCardStitch(
      challenge: challenge,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChallengeDetailScreen(challenge: challenge),
          ),
        );
      },
    );
  }
}
```

Wait, but this widget is currently a `StatelessWidget`. And it needs to access `bundle.userChallenges`. Let me check — `bundle` is already passed in. So I can check `bundle.userChallenges` directly. The widget doesn't need to become a ConsumerWidget — it just needs access to `bundle.userChallenges`.

But actually, looking at the current code, `bundle` is `ChallengeBundleData?` which is already passed in. The `_WeeklySpotlightSection` is a `StatelessWidget`. But it doesn't have access to `bundle.userChallenges` since `bundle` is already a parameter. So this works:

```dart
class _WeeklySpotlightSection extends StatelessWidget {
  final ChallengeBundleData? bundle;

  const _WeeklySpotlightSection({this.bundle});

  @override
  Widget build(BuildContext context) {
    final challenge = bundle?.weeklySpotlight;
    final userChallenges = bundle?.userChallenges ?? [];

    if (challenge == null) {
      return _EmptySpotlightCard();
    }
    
    // Hide featured if user already joined it
    final isJoined = userChallenges.any((c) => c.id == challenge.id);
    if (isJoined) return const SizedBox.shrink();

    return QuestCardStitch(
      challenge: challenge,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChallengeDetailScreen(challenge: challenge),
          ),
        );
      },
    );
  }
}
```

Same for `_DailyQuestSection`:

```dart
class _DailyQuestSectionState extends ConsumerState<_DailyQuestSection> {
  @override
  Widget build(BuildContext context) {
    final challenge = widget.bundle?.dailyQuest;
    final userChallenges = widget.bundle?.userChallenges ?? [];

    if (challenge == null) {
      return _EmptyDailyQuestCard();
    }

    // Hide featured if user already joined it
    final isJoined = userChallenges.any((c) => c.id == challenge.id);
    if (isJoined) return const SizedBox.shrink();

    return QuestCardStitch(
      challenge: challenge,
      ...
    );
  }
}
```

- [ ] **Step 2: Remove the mixed `_ActiveChallengesSection` from filter 1**

Wait, looking at the code more carefully:

For the standalone ChallengesScreen (with AppBar), filters are:
```dart
['All', 'Active', 'Solo', 'Daily', 'Weekly', 'Completed']
```

For the ChallengesTabContent (embedded in tabs), filters are:
```dart
['All', 'Active Solo', 'Weekly Spotlight', 'Completed']
```

The user's clarification said:
- "the previously inactive challenge should be removed and replaced with the active one"
- "it should route back to the all screen"
- Categories stay the same

So the key change in the All screen:
1. Show weekly/daily/solo in their respective sections
2. Hide featured versions if user has joined them (active versions will show in the active solo section if solo, or... hmm)

Wait, but the user said solo quests should only be in solo section. Let me re-read the original constraint:

"the quest will be showing active in all the categories it belongs it should not be active in solo quests in the all section only solo quest are to be active in the solo section the rest should be active in daily or weekly sections"

This means:
- Solo quests → active in Solo section
- Daily quests → active in Daily section  
- Weekly quests → active in Weekly section
- NOT mixed in "All" section

Currently in the "All" filter:
- Weekly Spotlight section
- Daily Quest section
- Solo Quests section (active solo challenges)
- Archetype Challenges section

But the user doesn't want a mixed "Active" section. Currently filter 1 ("Active" in standalone) shows `_ActiveChallengesSection` that mixes everything. The "All" filter doesn't show active mixed section.

Wait, in the current code for filter 0 (All):
- Lines 203-254: Weekly Spotlight + Daily Quest sections
- Lines 257-261: Filter 1 (Active) → shows `_ActiveChallengesSection` 
- Lines 264-292: Filter 0 or 2 → Solo Quests section
- Lines 294-352: Filter 0 or 3 or 4 → Daily/Weekly sections
- Lines 354-384: Filter 0 → Archetype Challenges

So in "All" filter currently:
- Shows Weekly Spotlight
- Shows Daily Quest
- Shows Solo Quests (active only)
- Shows Archetype Challenges

And in "Active" filter (filter 1):
- Shows `_ActiveChallengesSection` - mixes solo/daily/weekly active

The user wants:
- Filter 0 (All): Show featured weekly/daily/solo quests, but hide the featured version if user joined it
- No mixed "Active" section in All
- The `_ActiveChallengesSection` should be... removed? Hmm, but user said "I just want the challenge category to remain the same no active or not"

Actually, I think the user is saying:
- Keep the same filter tabs (All, Active, Solo, Daily, Weekly, Completed)
- When user is in the "All" filter, just show all featured challenges
- When user is in specific category filter (Solo, Daily, Weekly), show active challenges in those
- When user joins a quest, route to the "All" screen (filter 0)
- The featured version that was joined should not appear (it should be replaced by the active version in the category view)

Wait, that's still not clear. Let me look at it differently.

Actually, I think the user wants the "All" filter to show challenges organized by category, and when a challenge becomes active, show the active version in its category. Don't show both the featured AND active version of the same challenge.

So in the "All" filter:
- Weekly Spotlight section: show the featured weekly (if not joined) OR the active weekly (if joined)
- Daily Quest section: show the featured daily (if not joined) OR the active daily (if joined)
- Solo Quests section: show ONLY active solo quests
- Archetype Challenges: show only non-joined archetype challenges

The SOLE change to the "All" filter is: hide featured daily/weekly/archetype challenges if the user has joined them.

And the main behavioral change is:
1. Post-join → route to `/tribes/challenges` (All filter)
2. Featured version hidden if joined
3. Active version shows in appropriate category

Let me keep it simple and just:
1. Hide featured weekly/daily if joined in the "All" filter
2. Route to `/tribes/challenges` after joining

For filter 1 (Active) — the user said "the Active filter can remain the same". So I'll leave filter 1 as-is.

Wait actually, looking at the user's answer: "I just want the challenge category to remain the same no active or not it should route back to the all screen and the previously inactive challenge should be removed and replaced with the active one"

OK so:
1. Keep challenge categories the same (solo section, daily section, weekly section)
2. Route back to "All" screen after joining
3. Remove the featured/inactive challenge and show the active one instead

The simplest implementation:
1. In `_WeeklySpotlightSection` and `_DailyQuestSection`, if the user has joined the challenge, hide the featured version
2. After joining, route to `/tribes/challenges`

The active daily/weekly challenge will still show up in filter 1 (Active) if the user switches to it.

Actually, wait. The active daily quest won't show in the Solo section. It's not a solo quest — it's a daily quest. The Solo section (`_QuestCardsSection`) uses `bundle.activeSoloChallenges` which returns ALL active challenges regardless of type. The daily quest, when active, shows up there. 

But the user said: "only solo quest are to be active in the solo section the rest should be active in daily or weekly sections"

So active daily quest should show in the Daily section, not the Solo section. Similarly for weekly.

Currently, the Daily section shows the featured daily quest. If the user joins it, they'd see both the featured version in Daily section AND the active version in Solo section (because `activeSoloChallenges` returns all active challenges).

The fix: filter `activeSoloChallenges` to only include challenges that are NOT the daily quest or weekly spotlight.

So I need to update `activeSoloChallenges` getter to exclude challenges whose IDs match the daily quest or weekly spotlight:

```dart
List<Challenge> get activeSoloChallenges => userChallenges
    .where((c) => c.status == ChallengeStatus.active &&
        c.id != dailyQuest?.id &&
        c.id != weeklySpotlight?.id)
    .toList();
```

And to show the active daily/weekly quests in their respective sections, I'll use the existing featured section but check: if user has joined the daily quest, show the active version from userChallenges instead of the featured one.

This is getting complex. Let me simplify:

The key changes to `challenges_screen.dart`:

1. **`_WeeklySpotlightSection`**: Check if user joined → if yes, find the active version from userChallenges and show it; if no, show featured
2. **`_DailyQuestSection`**: Same logic
3. **`_QuestCardsSection`** (Solo Quests): Already uses `activeSoloChallenges` — but this getter needs to exclude daily/weekly quests

So:
- **ChallengeBundleData**: Add `activeSoloChallenges` getter that excludes daily/weekly
- **ChallengesScreen sections**: Hide featured if joined, show active from userChallenges

Let me write this properly now.<｜end▁of▁thinking｜>

<｜｜DSML｜｜tool_calls>
<｜｜DSML｜｜invoke name="todowrite">
<｜｜DSML｜｜parameter name="todos" string="false">[{"priority":"high","content":"Explore project context — quests, blueprints, habits code","status":"completed"},{"priority":"medium","content":"Ask clarifying questions if needed","status":"completed"},{"priority":"high","content":"Present design with approaches and trade-offs","status":"completed"},{"priority":"high","content":"Write design doc and get approval","status":"completed"},{"priority":"high","content":"Write implementation plan","status":"in_progress"},{"priority":"high","content":"Implement all changes","status":"pending"},{"priority":"high","content":"Verify with lint/tests","status":"pending"}]