# Challenges, World Map & Animation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix confirmation sheet spam on multi-day challenges, remove redundant world map node dialog for unlocked nodes, and add animation micro-interactions across 6 priority areas.

**Architecture:** Three independent workstreams — (A) Challenge model extension with `joinedAt` + sheet guard, (B) World map conditional dialog skip + companion guide, (C) Animation additions across 6 files. Phases 1-2 sequential; 3-10 independent.

**Tech Stack:** Flutter/Dart, Riverpod, Drift (SQLite), flutter_animate, SharedPreferences via LocalSettingsRepository, CustomPainter

---

### Task 1: Add `joinedAt` to Challenge Model + Drift Table

**Files:**
- Modify: `lib/features/social/domain/models/challenge.dart`
- Modify: `lib/core/drift/tables/challenge_progress_table.dart`
- Modify: `lib/core/drift/daos/challenge_progress_dao.dart`

- [ ] **Step 1: Add `joinedAt` field to Challenge model**

In `lib/features/social/domain/models/challenge.dart`, add `final DateTime? joinedAt;` field after `currentDay`:

```dart
  final int currentDay;
  final DateTime? joinedAt;
  final ChallengeStatus status;
```

Add to constructor:
```dart
    this.joinedAt,
```

Add to `props`:
```dart
  @override
  List<Object?> get props => [
    // ...existing fields...,
    joinedAt,
  ];
```

Add to `copyWith` if it exists — add `DateTime? joinedAt` parameter.

- [ ] **Step 2: Add `joined_at` column to Drift table**

In `lib/core/drift/tables/challenge_progress_table.dart`, add column:

```dart
  DateTime? get joinedAt => text().nullable()();
```

- [ ] **Step 3: Update ChallengeProgressDao**

In `lib/core/drift/daos/challenge_progress_dao.dart`, update `insertFromData` and `updateDay` methods to handle `joinedAt` field. Map between `ChallengeProgressTable` and `Challenge` model.

- [ ] **Step 4: Run `dart run build_runner build --delete-conflicting-outputs`**

Ensure Drift generates updated code.

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(challenges): add joinedAt field to Challenge model and drift table"
```

---

### Task 2: Update Repository — Set `joinedAt` on Join + Calendar Day Computation

**Files:**
- Modify: `lib/core/drift_repositories/drift_challenge_repository.dart`

- [ ] **Step 1: Set joinedAt on joinChallenge**

In `joinChallenge()` method, set `joinedAt` to `DateTime.now()` when inserting new progress:

```dart
// Inside joinChallenge, where progress is inserted
final progress = ChallengeProgress(
  challengeId: challenge.id,
  userId: userId,
  title: challenge.title,
  currentDay: 0,
  totalDays: challenge.totalDays,
  status: 'active',
  xpReward: challenge.xpReward,
  joinedAt: DateTime.now().toIso8601String(),
);
```

- [ ] **Step 2: Add `computeAvailableDay()` helper method**

```dart
int computeAvailableDay(String? joinedAt, int totalDays) {
  if (joinedAt == null) return 0;
  final joined = DateTime.parse(joinedAt);
  final daysSince = DateTime.now().difference(joined).inDays;
  return daysSince.clamp(0, totalDays - 1);
}
```

- [ ] **Step 3: Return joinedAt from getChallenge and list methods**

In methods that return `Challenge` objects, parse `joinedAt` from the database and pass it through. Ensure `getChallengeById` and `getActiveChallenges` include joinedAt.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(challenges): set joinedAt on join, add calendar day computation"
```

---

### Task 3: Sheet Guard + Calendar-Based Content Display

**Files:**
- Modify: `lib/features/social/presentation/screens/challenge_detail_screen.dart`

- [ ] **Step 1: Guard sheet to only show on join (featured status)**

In challenge_detail_screen.dart, modify `_showConfirmation` method (around line 552). Add early return or conditional:

```dart
void _showConfirmation(
  BuildContext screenContext,
  WidgetRef ref,
  Challenge challenge,
) {
  // If already active (joined), skip sheet and execute directly
  if (challenge.status == ChallengeStatus.active) {
    _executeDayCompletion(screenContext, ref, challenge);
    return;
  }
  // Only show sheet for featured (join) flow
  showModalBottomSheet(
    context: screenContext,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => QuestConfirmationSheet(
      challenge: challenge,
      onConfirm: () async {
        final user = ref.read(authStateChangesProvider).value;
        if (user == null) return;
        final repo = ref.read(challengeRepositoryProvider);
        final result = await repo.joinChallenge(user.id, challenge.id);
        result.fold(
          (failure) => _showError(screenContext, failure.message),
          (_) async {
            ref.invalidate(userChallengesProvider);
            ref.invalidate(archetypeChallengesProvider);
            ref.invalidate(challengeBundleProvider);
            if (screenContext.mounted) {
              _showSuccess(screenContext, 'QUEST STARTED! (+25 XP)');
              screenContext.go('/tribes/challenges');
            }
          },
        );
      },
    ),
  );
}
```

- [ ] **Step 2: Add `_executeDayCompletion` method**

```dart
void _executeDayCompletion(
  BuildContext screenContext,
  WidgetRef ref,
  Challenge challenge,
) async {
  final user = ref.read(authStateChangesProvider).value;
  if (user == null) return;
  final repo = ref.read(challengeRepositoryProvider);
  final newProgress = challenge.currentDay + 1;
  final result = await repo.updateProgress(
    user.id,
    challenge.id,
    newProgress,
  );
  result.fold(
    (failure) => _showError(screenContext, failure.message),
    (_) {
      ref.invalidate(userChallengesProvider);
      ref.invalidate(challengeBundleProvider);
      ref.invalidate(userStatsStreamProvider);
      ref.invalidate(recapRefreshCounterProvider);
      final isCompleted = newProgress >= challenge.totalDays;
      _showSuccess(
        screenContext,
        isCompleted
            ? 'QUEST COMPLETE! (+${challenge.xpReward} XP)'
            : 'PROGRESS SAVED!',
      );
      screenContext.pop();
    },
  );
}
```

- [ ] **Step 3: Update step timeline to show available day content**

Find the step timeline rendering code. Change what's displayed so steps up to `availableDay` (computed from joinedAt) are visible, not just up to `currentDay`. If `joinedAt` is available, compute:

```dart
final availableDay = challenge.joinedAt != null
    ? DateTime.now().difference(challenge.joinedAt!).inDays.clamp(0, challenge.totalDays - 1)
    : challenge.currentDay;
```

Use `availableDay` for determining visibility of step content, while `currentDay` remains the logged progress.

- [ ] **Step 4: Verify the app builds**

```bash
flutter analyze lib/features/social/presentation/screens/challenge_detail_screen.dart
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(challenges): guard confirmation sheet for join only, calendar-day step visibility"
```

---

### Task 4: World Map — Conditional Dialog Skip

**Files:**
- Modify: `lib/features/world_map/presentation/screens/world_map_screen.dart`
- Modify: `lib/features/world_map/presentation/widgets/node_quest_dialog.dart`

- [ ] **Step 1: Update `_showNodeDetail` to conditional navigation**

In `world_map_screen.dart`, replace `_showNodeDetail` body:

```dart
void _showNodeDetail(
  BuildContext context,
  WorldNode node,
  ArchetypeMapConfig config,
) {
  if (node.state == NodeState.locked) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => NodeQuestDialog(
        node: node,
        primaryColor: config.primaryColor,
        userLevel: ref.read(userStatsStreamProvider).value?.effectiveLevel ?? 1,
        onEnterLevel: null, // disabled for locked
        onAction: null,
      ),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LevelImmersiveScreen(node: node, config: config),
      ),
    );
  }
}
```

- [ ] **Step 2: Simplify NodeQuestDialog for locked-only display**

In `node_quest_dialog.dart`, make `onEnterLevel` and `onAction` nullable. When both are null (locked state), show only lock info and a "CLOSE" button. Remove the "ENTER LEVEL" / "COMPLETE" buttons when locked.

- [ ] **Step 3: Verify build**

```bash
flutter analyze lib/features/world_map/presentation/screens/world_map_screen.dart lib/features/world_map/presentation/widgets/node_quest_dialog.dart
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(world-map): skip node quest dialog for unlocked nodes, navigate directly to level"
```

---

### Task 5: World Map — Companion Guide Brief on First Visit

**Files:**
- Modify: `lib/features/world_map/presentation/screens/level_immersive_screen.dart`
- Modify: `lib/features/onboarding/data/repositories/local_settings_repository.dart`

- [ ] **Step 1: Add `hasSeenNodeGuide` storage method to LocalSettingsRepository**

In `local_settings_repository.dart`, add:

```dart
Future<bool> getHasSeenNodeGuide(String nodeId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hasSeenNodeGuide_$nodeId') ?? false;
}

Future<void> setHasSeenNodeGuide(String nodeId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('hasSeenNodeGuide_$nodeId', true);
}
```

- [ ] **Step 2: Add companion guide brief overlay in LevelImmersiveScreen**

In `initState` of `_LevelImmersiveScreenState`, check if guide has been seen:

```dart
@override
void initState() {
  super.initState();
  _checkFirstVisit();
}

Future<void> _checkFirstVisit() async {
  final repo = LocalSettingsRepository();
  final hasSeen = await repo.getHasSeenNodeGuide(widget.node.id);
  if (!hasSeen && mounted) {
    await repo.setHasSeenNodeGuide(widget.node.id);
    _showCompanionGuide();
  }
}
```

- [ ] **Step 3: Build the guide overlay widget**

Add a method that shows a glassmorphic overlay card with section tips:

```dart
void _showCompanionGuide() {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("NODE GUIDE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 16),
                _guideRow("1", "Complete directives to earn attribute XP"),
                _guideRow("2", "Check in with quest challenges daily"),
                _guideRow("3", "Complete missions to conquer the node"),
                SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text("GOT IT",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
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

Widget _guideRow(String num, String text) {
  return Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          child: Center(child: Text(num, style: TextStyle(color: Colors.white, fontSize: 12))),
        ),
        SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: Colors.white70, fontSize: 14))),
      ],
    ),
  );
}
```

- [ ] **Step 4: Verify build**

```bash
flutter analyze lib/features/world_map/presentation/screens/level_immersive_screen.dart
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(world-map): add first-visit companion guide overlay to level immersive screen"
```

---

### Task 6: Animation P1 — StructureNode Tap Feedback

**Files:**
- Modify: `lib/features/world_map/presentation/widgets/structure_node.dart`

- [ ] **Step 1: Add scale-down press feedback**

Convert `StructureNode` from `StatelessWidget` to `StatefulWidget` (or use `GestureDetector` with `_onTapDown`/`_onTapUp` patterns). Add a `_scale` double state variable.

Add to the build method's `GestureDetector`:

```dart
GestureDetector(
  onTapDown: (_) => setState(() => _scale = 0.92),
  onTapUp: (_) => setState(() => _scale = 1.0),
  onTapCancel: () => setState(() => _scale = 1.0),
  onTap: () => widget.onTap(),
  child: AnimatedScale(
    scale: _scale,
    duration: Duration(milliseconds: 150),
    curve: Curves.easeOut,
    child: // existing child widget
  ),
)
```

- [ ] **Step 2: Verify build**

```bash
flutter analyze lib/features/world_map/presentation/widgets/structure_node.dart
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat(animation): add scale-down tap feedback to structure node"
```

---

### Task 7: Animation P2 — LevelImmersiveScreen Entrance Stagger

**Files:**
- Modify: `lib/features/world_map/presentation/screens/level_immersive_screen.dart`

- [ ] **Step 1: Add staggered entrance with flutter_animate**

Wrap each content section in the scrollable column with `flutter_animate` calls. Add a visibility check so animations only play on first build:

```dart
class _LevelImmersiveScreenState extends ConsumerState<LevelImmersiveScreen> {
  bool _hasAnimated = false;
```

In the build method's content, wrap each section:

```dart
// Hero section
nodeEmojiAndName.animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),

// Directive card
directiveCard.animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

// Attribute chips
attributeChips.animate(delay: 300.ms).fadeIn().scale(begin: 0.95),

// Quest challenges (each card staggered)
for (var i = 0; i < questCards.length; i++)
  questCards[i].animate(delay: (400 + i * 100).ms).fadeIn().slideX(begin: 0.05),

// Action button
actionButton.animate(delay: 600.ms).fadeIn().slideY(begin: 0.1),
```

Set `_hasAnimated = true` after first build to prevent re-animation on rebuild.

- [ ] **Step 2: Verify build**

```bash
flutter analyze lib/features/world_map/presentation/screens/level_immersive_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat(animation): add staggered entrance animations to level immersive screen"
```

---

### Task 8: Animation P3 — ChallengeDetailScreen Staggered Entrance

**Files:**
- Modify: `lib/features/social/presentation/screens/challenge_detail_screen.dart`

- [ ] **Step 1: Add staggered entrance with flutter_animate**

The screen is a `ConsumerWidget` (stateless). Add an `_hasAnimated` state by converting to `ConsumerStatefulWidget`, or use a simpler pattern — wrap sections with `flutter_animate` in the build method. Since `flutter_animate` is already imported at line 13:

Wrap the hero image section:
```dart
heroSection.animate(delay: 0.ms).fadeIn()
```

Wrap title and badges:
```dart
titleBadges.animate(delay: 200.ms).fadeIn().slideY(begin: 0.05)
```

Wrap progress bar:
```dart
progressBar.animate(delay: 300.ms).scaleX(begin: 0, end: 1)
```

Wrap step timeline:
```dart
Column(
  children: challenge.steps.asMap().entries.map((entry) =>
    stepWidget(entry.value)
      .animate(delay: (400 + entry.key * 80).ms)
      .fadeIn()
      .slideX(begin: 0.03)
  ),
)
```

Wrap action button:
```dart
actionButton.animate(delay: 500.ms).fadeIn().slideY(begin: 0.1)
```

- [ ] **Step 2: Verify build**

```bash
flutter analyze lib/features/social/presentation/screens/challenge_detail_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat(animation): add staggered entrance animations to challenge detail screen"
```

---

### Task 9: Animation P4 — Social/Leaderboard Staggered Lists

**Files:**
- Modify: `lib/features/social/presentation/screens/friends_leaderboard.dart`
- Modify: `lib/features/social/presentation/screens/tribe_tab_content.dart`

- [ ] **Step 1: Add staggered list item entrance in friends_leaderboard.dart**

Find the list rendering code (likely a `ListView` or `Column` of items). Wrap each item:

```dart
// Before building the list
final items = leaderboardData;

// When rendering
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return items[index]
        .animate(delay: (index * 50).ms)
        .fadeIn()
        .slideX(begin: 0.03);
  },
)
```

- [ ] **Step 2: Add staggered list item entrance in tribe_tab_content.dart**

Same pattern — wrap list items with `animate().fadeIn().slideX()` using index-based delay.

- [ ] **Step 3: Verify build**

```bash
flutter analyze lib/features/social/presentation/screens/friends_leaderboard.dart lib/features/social/presentation/screens/tribe_tab_content.dart
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(animation): add staggered list entrance to leaderboard and tribe screens"
```

---

### Task 10: Animation P5 — Auth Screen Entrance Animations

**Files:**
- Locate auth screens: `lib/features/auth/presentation/screens/` — find `login_screen.dart` and `signup_screen.dart` or equivalent

- [ ] **Step 1: Add entrance stagger to login screen**

```dart
// Logo/title
logo.animate(delay: 0.ms).fadeIn().slideY(begin: -0.05),

// Form fields (sequential)
emailField.animate(delay: 150.ms).fadeIn().slideX(begin: 0.03),
passwordField.animate(delay: 250.ms).fadeIn().slideX(begin: 0.03),

// Action button
loginButton.animate(delay: 350.ms).fadeIn().scale(begin: 0.97),
```

- [ ] **Step 2: Same pattern for signup screen**

Apply similar stagger with appropriate field count delays.

- [ ] **Step 3: Verify build**

```bash
flutter analyze lib/features/auth/presentation/screens/
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(animation): add entrance animations to auth screens"
```

---

### Task 11: Animation P6 — AttributeRadarChart Animated Fill

**Files:**
- Modify: `lib/features/gamification/presentation/widgets/attribute_radar_chart.dart`

- [ ] **Step 1: Add AnimationController to radar chart**

Convert widget to `StatefulWidget` with `TickerProviderStateMixin`:

```dart
class _AttributeRadarChartState extends State<AttributeRadarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void didUpdateWidget(AttributeRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-trigger if attributes changed
    if (oldWidget.attributes != widget.attributes) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 2: Update CustomPainter to accept fill progress**

Pass `_fillAnimation.value` to the `CustomPainter`. The painter interpolates polygon vertices from center (0.0) to full extent (1.0):

```dart
class RadarChartPainter extends CustomPainter {
  final double fillProgress;
  // ...
}
```

When drawing the filled polygon, scale each vertex by `fillProgress`:
```dart
final scaledPoint = Offset(
  center.dx + (vertex.dx - center.dx) * fillProgress,
  center.dy + (vertex.dy - center.dy) * fillProgress,
);
```

Call `setState` or use `AnimatedBuilder` to repaint on animation ticks:

```dart
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) => CustomPaint(
    painter: RadarChartPainter(
      fillProgress: _fillAnimation.value,
      // ... other params
    ),
    size: Size.infinite,
  ),
)
```

- [ ] **Step 3: Verify build**

```bash
flutter analyze lib/features/gamification/presentation/widgets/attribute_radar_chart.dart
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(animation): add animated fill to attribute radar chart"
```
