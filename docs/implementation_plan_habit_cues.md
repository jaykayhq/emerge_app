# Emerge App Implementation Plan: Habit Creation, Progress, Completion & Cues System

## Executive Summary

This implementation plan addresses the complete habit lifecycle within the Emerge app—encompassing creation, progress tracking, completion mechanics, and the cues/triggers system that drives user engagement. The plan is structured to align with the existing architectural patterns defined in CLAUDE.md while incorporating industry best practices from behavioral science and habit formation research.

### Scope Definition

The implementation covers seven primary screens and their associated domain logic:

1. **Timeline Screen** (`lib/features/timeline/presentation/screens/timeline_screen.dart`) - Daily habit management and completion
2. **World Map Screen** (`lib/features/world_map/presentation/screens/world_map_screen.dart`) - Progression through archetype nodes
3. **Level Immersive Screen** (`lib/features/world_map/presentation/screens/level_immersive_screen.dart`) - Detailed node/challenge interaction
4. **Future Self Studio Screen** (`lib/features/profile/presentation/screens/future_self_studio_screen.dart`) - Profile, avatar, and identity progression
5. **Challenges Screen** (`lib/features/social/presentation/screens/challenges_screen.dart`) - Quest/challenge management
6. **Tribes Screen** (`lib/features/social/presentation/screens/tribes_screen.dart`) - Community features
7. **Friends Screen** (`lib/features/social/presentation/screens/friends_screen.dart`) - Accountability partners
8. **Cue Entity** (`lib/core/domain/entities/cue.dart`) - The trigger system foundation

### Design Philosophy Alignment

The implementation follows the "Identity-First Minimalism" philosophy from CLAUDE.md:

- **Anti-Generic**: Every widget reinforces identity votes through the habit loop (Cue–Craving–Response–Reward)
- **The "Why" Factor**: Each interaction serves a behavioral psychology purpose
- **Minimalism with Gamification**: Reduction plus clarity with evolving progression metaphors

---

## Part I: Analysis of Current State

### 1.1 Existing Architecture Overview

The current implementation demonstrates a sophisticated Clean Architecture approach with the following layers:

```
lib/
├── core/domain/entities/cue.dart          # Cue entity with triggers, intensity, channels
├── features/
│   ├── timeline/                          # Daily habit management
│   ├── world_map/                         # Progression system
│   ├── profile/                           # Identity and avatar
│   ├── social/                            # Challenges, tribes, friends
│   └── [other features]
```

### 1.2 Current Feature Implementation Status

| Feature | Screen | Implementation Status | Gaps Identified |
|---------|--------|----------------------|-----------------|
| Habit Creation | Timeline | Partial - habit entity exists, creation flow incomplete | No dedicated create-habit screen; time-of-day grouping exists but not fully utilized |
| Progress Tracking | Timeline/World Map | Partial - completion tracking, streak calculation | Heatmap visualization missing; attribute-based progress not surfaced |
| Completion | Timeline/Challenges | Partial - completion marking, XP calculation | Completion celebrations not implemented; variable rewards absent |
| Cues System | Cue Entity | Complete entity definition | No implementation; no triggers; no notification integration |
| World Map Progression | World Map/Level Immersive | Strong - section-based logic, node states | Visual decay effects need integration; AI background generation not connected |
| Challenges | Challenges Screen | Good - filters, streaks, categories | Challenge creation flow incomplete; progress sync with timeline missing |

### 1.3 Hook Model Compliance Analysis

The Hook Model (Trigger → Action → Variable Reward → Investment) provides the theoretical foundation for habit-forming products. Current compliance:

| Phase | Current Implementation | Compliance Level |
|-------|----------------------|------------------|
| **Trigger (Cue)** | Cue entity defined but not implemented | 20% |
| **Action** | Habit completion in Timeline | 80% |
| **Variable Reward** | XP rewards exist, no variability | 30% |
| **Investment** | World map progression, avatar evolution | 70% |

**Critical Finding**: The cues/triggers system is the primary gap in achieving full Hook Model compliance. The `cue.dart` entity provides the schema but requires complete implementation.

---

## Part II: Frontend Design Specifications

### 2.1 Habit Creation Flow

#### 2.1.1 UI/UX Specification

**Entry Point**: FAB on Timeline screen or dedicated route `/timeline/create-habit`

**Screen Flow**:

```
Timeline → Create Habit Screen → (Save) → Timeline
```

**Components Required**:

1. **HabitNameInput** - Text field with archetype-appropriate suggestions
2. **AttributeSelector** - Chip-based selection (Vitality, Intellect, Creativity, Focus, Strength, Spirit)
3. **DifficultySelector** - Three-tier toggle (Easy/Medium/Hard)
4. **TimeOfDaySelector** - Morning/Afternoon/Evening/Anytime chips
5. **ReminderConfig** - Time picker with cue type selector
6. **CueTypeSelector** - Trigger type selection (Time, Location, Context, Social, Habit Stacking, Energy, Milestone, Recovery, AI-Personalized)
7. **IntensitySelector** - Gentle/Moderate/Urgent/Critical slider

**Design Patterns** (per CLAUDE.md):

- Glassmorphism cards matching `EmergeColors.glassWhite`
- Archetype-specific accent colors via `ArchetypeTheme.forArchetype()`
- BackdropFilter with 12px blur for frosted glass effect

**State Management**:

```dart
// New provider structure
@riverpod
class CreateHabitNotifier extends _$CreateHabitNotifier {
  @override
  CreateHabitState build() => const CreateHabitState();

  void setTitle(String title) => state = state.copyWith(title: title);
  void setAttribute(HabitAttribute attribute) => state = state.copyWith(attribute: attribute);
  void setDifficulty(HabitDifficulty difficulty) => state = state.copyWith(difficulty: difficulty);
  void setTimeOfDay(String timeOfDay) => state = state.copyWith(timeOfDay: timeOfDay);
  void setReminderTime(DateTime? time) => state = state.copyWith(reminderTime: time);
  void setCueType(CueTriggerType type) => state = state.copyWith(cueType: type);
  void setIntensity(CueIntensity intensity) => state = state.copyWith(intensity: intensity);

  Future<void> saveHabit() async {
    // Implementation
  }
}

class CreateHabitState {
  final String title;
  final HabitAttribute? attribute;
  final HabitDifficulty difficulty;
  final String timeOfDay;
  final DateTime? reminderTime;
  final CueTriggerType? cueType;
  final CueIntensity intensity;
  final bool isLoading;
  final String? error;
}
```

**Validation Rules**:

- Title: 3-50 characters, required
- Attribute: Required
- Difficulty: Default to Medium
- Time of Day: Default to Anytime
- Cue Type: Optional (defaults to Time-based)
- Reminder: Optional

#### 2.1.2 Behavioral Psychology Integration

The habit creation flow implements the "Make It Obvious" principle through:

1. **Default Cue Suggestions**: Pre-populate based on archetype
   - Athlete: Morning, post-workout context cues
   - Scholar: Evening, study-session context cues
   - Creator: Anytime, energy-based triggers

2. **Implementation**:

```dart
// Archetype-based cue defaults
Map<UserArchetype, List<CueTriggerType>> getDefaultCueTypes(UserArchetype archetype) {
  switch (archetype) {
    case UserArchetype.athlete:
      return [CueTriggerType.time, CueTriggerType.location, CueTriggerType.habitStacking];
    case UserArchetype.scholar:
      return [CueTriggerType.time, CueTriggerType.context, CueTriggerType.aiPersonalized];
    case UserArchetype.creator:
      return [CueTriggerType.energy, CueTriggerType.context, CueTriggerType.aiPersonalized];
    case UserArchetype.stoic:
      return [CueTriggerType.time, CueTriggerType.milestone, CueTriggerType.recovery];
    case UserArchetype.zealot:
      return [CueTriggerType.social, CueTriggerType.milestone, CueTriggerType.time];
  }
}
```

### 2.2 Progress Tracking Specification

#### 2.2.1 Timeline Progress Display

**Current Implementation**: Hierarchical display grouped by time-of-day (morning/afternoon/evening)

**Enhancement Requirements**:

1. **Streak Visualization** - Implement heatmap or streak flames
2. **Attribute Progress** - Show XP per attribute with visual bars
3. **Completion Rate** - Daily/weekly/monthly percentages
4. **Identity Votes** - Display cumulative habit completions by attribute

**Component: StreakFlameWidget**

```dart
class StreakFlameWidget extends StatelessWidget {
  final int streakCount;
  final bool isActive;
  final double size;

  // Visual: Animated flame icon with glow effect
  // Colors: Orange gradient for active, gray for broken
  // Animation: Subtle pulse when streak increases
}
```

**Component: AttributeProgressBar**

```dart
class AttributeProgressBar extends StatelessWidget {
  final HabitAttribute attribute;
  final double progress; // 0.0 - 1.0
  final int currentXp;
  final int maxXp;

  // Visual: Horizontal bar with attribute-specific color
  // Animation: Fill animation on load
  // Tooltip: Tap to show breakdown
}
```

**Component: IdentityVotesDisplay**

```dart
class IdentityVotesDisplay extends StatelessWidget {
  final Map<String, int> votesByAttribute;

  // Visual: Grid of attribute icons with vote counts
  // Psychology: "Every completion is a vote for who you want to become"
  // Animation: Increment animation when vote added
}
```

#### 2.2.2 World Map Progress Display

**Current Implementation**: Section-based node unlocking (5 levels per section)

**Enhancement Requirements**:

1. **Visual Decay Integration** - Connect `healthPercent` from `LevelImmersiveScreen` to background visuals
2. **Node Progress Overlay** - Show completion percentage on each node
3. **Section Progress** - Visual indicator of section completion

**Integration Point** (`world_map_screen.dart:132`):

```dart
// Current: hydration logic already exists
final hydratedNodes = _hydrateNodesWithSectionLogic(
  mapConfig.nodes,
  profile,
);

// Enhancement: Add decay-based visual state
Widget _buildNodeVisualState(WorldNode node, double worldHealth) {
  if (node.state == NodeState.completed) {
    return _buildCompletedNode(node, worldHealth);
  } else if (node.state == NodeState.inProgress) {
    return _buildInProgressNode(node, worldHealth);
  } else if (node.state == NodeState.locked) {
    return _buildLockedNode(node, worldHealth);
  }
  return _buildAvailableNode(node, worldHealth);
}
```

### 2.3 Completion Flow Specification

#### 2.3.1 Habit Completion UX

**Current Implementation**: Toggle in Timeline with XP calculation

**Enhancement Requirements**:

1. **Completion Celebration** - Animation and feedback
2. **Variable Reward System** - Random bonus rewards
3. **Streak Effects** - Visual streak maintenance/break
4. **Social Sharing** - Optional progress sharing

**Component: CompletionCelebration**

```dart
class CompletionCelebration extends StatefulWidget {
  final int xpEarned;
  final int newStreak;
  final bool isStreakMilestone; // 7, 14, 30, 60, 90, 180, 365 days
  final VoidCallback onComplete;

  // Animation sequence:
  // 1. Checkmark with scale + fade (300ms)
  // 2. XP increment with +1 animation (400ms)
  // 3. Streak flame intensifies (if milestone: confetti burst)
  // 4. Auto-dismiss after 2 seconds
}
```

**Variable Reward Implementation**:

```dart
class VariableRewardService {
  static const double baseRewardMultiplier = 1.0;
  static const double streakBonusMax = 0.5; // Max 50% bonus
  static const double randomBonusChance = 0.15; // 15% chance

  int calculateFinalXp(Habit habit, int baseXp, int currentStreak) {
    double xp = baseXp.toDouble();

    // Streak bonus
    double streakBonus = (currentStreak * 0.1).clamp(0.0, streakBonusMax);
    xp *= (1 + streakBonus);

    // Random bonus for variety
    if (Random().nextDouble() < randomBonusChance) {
      xp *= (1 + Random().nextDouble() * 0.3); // Up to 30% bonus
      // Track: "Lucky bonus!" trigger
    }

    // Milestone celebration
    if (_isStreakMilestone(currentStreak)) {
      xp *= 2; // Double XP for milestone streaks
    }

    return xp.toInt();
  }

  bool _isStreakMilestone(int streak) {
    return [7, 14, 30, 60, 90, 180, 365].contains(streak);
  }
}
```

#### 2.3.2 Challenge Completion UX

**Current Implementation**: Progress bar in `ChallengesScreen` and `LevelImmersiveScreen`

**Enhancement Requirements**:

1. **Challenge State Transitions** - Active → Completed → Archived
2. **Reward Claiming** - XP distribution on completion
3. **Completion Certificates** - Visual badge/sticker

### 2.4 Cues System Implementation

#### 2.4.1 Cue Trigger UI

**Trigger Configuration Screen** (part of habit creation/edit):

```
┌─────────────────────────────────────┐
│ Trigger Configuration              │
├─────────────────────────────────────┤
│                                     │
│ When should we remind you?         │
│                                     │
│ [Time] [Location] [Context]        │
│ [Social] [Habit Stacking]           │
│ [Energy] [Milestone] [Recovery]    │
│ [AI-Personalized]                  │
│                                     │
├─────────────────────────────────────┤
│ Intensity:                         │
│ ○ Gentle  ● Moderate  ○ Urgent     │
│                                     │
├─────────────────────────────────────┤
│ Channels:                          │
│ [✓] Push Notification              │
│ [✓] In-App Banner                  │
│ [ ] Haptic                         │
│ [ ] Sound                          │
│                                     │
├─────────────────────────────────────┤
│ Quiet Hours:                       │
│ 10:00 PM - 7:00 AM                 │
│                                     │
└─────────────────────────────────────┘
```

#### 2.4.2 Cue Display Components

**Component: CueBanner**

```dart
class CueBanner extends StatelessWidget {
  final Cue cue;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  // Visual: Glassmorphic banner at top of screen
  // Animation: Slide down + fade in (300ms)
  // Duration: Auto-dismiss after cue.category Duration
}
```

**Component: CueNotification**

```dart
class CueNotification extends StatelessWidget {
  final Cue cue;
  final VoidCallback onTap;

  // Maps to Flutter Local Notifications
  // Action buttons based on cue.category
  // Deep linking to relevant screen
}
```

#### 2.4.3 Cue Personalization Engine

**Frontend Integration**:

```dart
@riverpod
class CuePersonalization extends _$CuePersonalization {
  @override
  Future<List<Cue>> build() async {
    final userProfile = await ref.watch(userProfileProvider.future);
    final habits = await ref.watch(habitsProvider.future);

    return _generatePersonalizedCues(userProfile, habits);
  }

  List<Cue> _generatePersonalizedCues(UserProfile profile, List<Habit> habits) {
    final cues = <Cue>[];

    // Time-based cues
    cues.addAll(_generateTimeCues(profile, habits));

    // Habit stacking cues
    cues.addAll(_generateHabitStackingCues(habits));

    // AI-personalized cues (from backend)
    cues.addAll(await _fetchAiCues(profile));

    // Sort by relevance score
    cues.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return cues;
  }
}
```

### 2.5 Navigation & Flow Integration

**Route Structure** (aligned with existing GoRouter setup):

```
/timeline                    → TimelineScreen (default)
/timeline/create-habit       → CreateHabitScreen (new)
/timeline/detail/:id         → HabitDetailScreen (existing)
/timeline/edit/:id           → EditHabitScreen (new)
/world-map                   → WorldMapScreen (existing)
/world-map/level/:nodeId     → LevelImmersiveScreen (existing)
/profile                     → FutureSelfStudioScreen (existing)
/tribes/challenges           → ChallengesScreen (existing)
/tribes/tribes               → TribesScreen (existing)
/tribes/friends              → FriendsScreen (existing)
```

**Deep Link Handling**:

```dart
// Cues will trigger navigation via:
void handleCueAction(Cue cue) {
  switch (cue.category) {
    case CueCategory.initiation:
      if (cue.habitId != null) {
        context.push('/timeline/detail/${cue.habitId}');
      }
      break;
    case CueCategory.completion:
      context.push('/timeline');
      break;
    case CueCategory.celebration:
      context.push('/profile');
      break;
    case CueCategory.recovery:
      context.push('/timeline');
      break;
  }
}
```

---

## Part III: Backend Design Specifications

### 3.1 Firestore Data Model

#### 3.1.1 Collections Structure

```
users/{userId}
├── profile                    # User profile data
├── worldState                 # World map progression
├── avatarStats                # XP and level data
├── identityVotes              # Habit completion counts
├── settings
│   ├── notificationSettings   # Global notification prefs
│   ├── quietHours            # Do not disturb times
│   └── cuePreferences        # Personalized cue settings
├── habits/{habitId}           # User's habits
├── completions/{completionId} # Habit completion records
├── cues/{cueId}               # User's active cues
├── challenges/{challengeId}  # User's challenge progress
├── reflections               # Daily reflections
└── social
    ├── partners              # Accountability partners
    └── contracts             # Habit contracts
```

#### 3.1.2 Document Schemas

**habits/{habitId}**

```json
{
  "id": "string",
  "title": "string",
  "attribute": "string",  // "vitality", "intellect", "creativity", "focus", "strength", "spirit"
  "difficulty": "string", // "easy", "medium", "hard"
  "timelineSection": "string", // "morning", "afternoon", "evening", "anytime"
  "currentStreak": "number",
  "longestStreak": "number",
  "totalCompletions": "number",
  "lastCompletedDate": "timestamp",
  "createdAt": "timestamp",
  "reminderTime": "timestamp",
  "cueTrigger": {
    "type": "string",
    "intensity": "string",
    "channels": ["string"],
    "enabled": "boolean"
  },
  "isArchived": "boolean"
}
```

**cues/{cueId}**

```json
{
  "id": "string",
  "triggerType": "string",
  "category": "string",
  "intensity": "string",
  "channels": ["string"],
  "title": "string",
  "body": "string",
  "habitId": "string (optional)",
  "userArchetype": "string",
  "triggerData": {
    "time": "string (HH:mm)",
    "location": "string (optional)",
    "contextRule": "string (optional)",
    "linkedHabitId": "string (optional)"
  },
  "isShown": "boolean",
  "actionTaken": "boolean",
  "createdAt": "timestamp",
  "expiresAt": "timestamp (optional)",
  "priority": "number",
  "personalizationTokens": {
    "habitName": "string",
    "streak": "string"
  },
  "variantId": "string (optional)",
  "campaignId": "string (optional)"
}
```

**completions/{completionId}**

```json
{
  "id": "string",
  "habitId": "string",
  "userId": "string",
  "completedDate": "date",
  "xpEarned": "number",
  "streakAtCompletion": "number",
  "completedAt": "timestamp"
}
```

### 3.2 Firebase Functions Specification

#### 3.2.1 Cue Generation Functions

**Function: generateDailyCues**

```typescript
// functions/src/index.ts
export const generateDailyCues = functions.pubsub
  .schedule('0 * * * *') // Every hour
  .onRun(async (context) => {
    const users = await getActiveUsers();

    for (const user of users) {
      const cues = await generateCuesForUser(user);
      await saveUserCues(user.id, cues);
    }
  });
```

**Function: generateAiPersonalizedCues**

```typescript
export const generateAiPersonalizedCues = functions.https.onCall(
  async (data, context) => {
    const userId = context.auth?.uid;
    if (!userId) throw new functions.https.HttpsError('unauthenticated');

    const userProfile = await getUserProfile(userId);
    const habits = await getUserHabits(userId);
    const completionHistory = await getCompletionHistory(userId, 7);

    // AI analysis for optimal cue timing
    const optimalTimes = analyzeOptimalTimes(completionHistory);
    const contextPatterns = analyzeContextPatterns(completionHistory, habits);

    return {
      cues: buildPersonalizedCues(userProfile, habits, optimalTimes, contextPatterns),
      insights: generateInsights(userProfile, habits, completionHistory)
    };
  }
);
```

#### 3.2.2 Streak & Completion Functions

**Function: processHabitCompletion**

```typescript
export const processHabitCompletion = functions.https.onCall(
  async (data, context) => {
    const { habitId, userId } = data;
    const user = await getUserProfile(userId);
    const habit = await getHabit(habitId);

    // Calculate XP with variable reward
    const xpData = await calculateXp(user, habit);

    // Update streak
    const streakData = await updateStreak(user, habit);

    // Create completion record
    await createCompletion({
      habitId,
      userId,
      xpEarned: xpData.total,
      streakAtCompletion: streakData.newStreak
    });

    // Update identity votes
    await updateIdentityVotes(userId, habit.attribute);

    // Check for milestone achievements
    const achievements = await checkAchievements(user, streakData);

    // Queue celebration cue if milestone
    if (achievements.length > 0) {
      await queueCelebrationCue(user, achievements);
    }

    return { xpEarned: xpData.total, newStreak: streakData.newStreak, achievements };
  }
);
```

**Function: processStreakRecovery**

```typescript
export const processStreakRecovery = functions.pubsub
  .schedule('every 60 minutes')
  .onRun(async (context) => {
    // Find users with broken streaks
    const usersWithBrokenStreaks = await getUsersWithBrokenStreaks();

    for (const user of usersWithBrokenStreaks) {
      // Generate recovery cue (Never Miss Twice principle)
      const recoveryCue = buildRecoveryCue(user);
      await saveUserCue(user.id, recoveryCue);

      // Send push notification
      await sendPushNotification(user.id, recoveryCue);
    }
  });
```

#### 3.2.3 World Map Progression Functions

**Function: updateWorldState**

```typescript
export const updateWorldState = functions.https.onCall(
  async (data, context) => {
    const { userId, nodeId, action } = data; // action: "start" | "complete"

    const user = await getUserProfile(userId);
    const node = await getWorldNode(nodeId);

    if (action === 'start') {
      await addActiveNode(userId, nodeId);
    } else if (action === 'complete') {
      // Distribute XP boosts
      for (const [attribute, xp] of Object.entries(node.xpBoosts)) {
        await addAttributeXp(userId, attribute, xp);
      }

      // Update world health
      const healthUpdate = calculateHealthImpact(node);
      await updateWorldHealth(userId, healthUpdate);

      // Mark node as claimed
      await claimNode(userId, nodeId);

      // Check for section completion
      await checkSectionCompletion(userId, node.section);
    }

    return await getUpdatedWorldState(userId);
  }
);
```

### 3.3 Notification System Specification

#### 3.3.1 Firebase Cloud Messaging Setup

**Topics for User Segmentation**:

```
topics:
  - user-{userId}                      # User-specific notifications
  - archetype-{archetype}              # Archetype-based tips
  - streak-{streakLength}              # Streak-based motivation
  - level-{levelRange}                  # Level-based content
```

**Notification Templates**:

```json
{
  "habit_reminder": {
    "title": "Time for {habitName}!",
    "body": "Keep your {streak}-day streak alive 🔥",
    "data": { "habitId": "{habitId}", "type": "habit_reminder" },
    "actions": [
      { "title": "Complete", "action": "complete" },
      { "title": "Snooze", "action": "snooze" }
    ]
  },
  "streak_milestone": {
    "title": "🎉 {streak} Day Streak!",
    "body": "You've proven your commitment. Keep going!",
    "data": { "type": "streak_milestone" }
  },
  "recovery": {
    "title": "Don't break the chain!",
    "body": "Missed yesterday. One completion gets you back on track.",
    "data": { "type": "recovery", "habitId": "{habitId}" }
  },
  "challenge_complete": {
    "title": "🏆 Challenge Complete!",
    "body": "You finished {challengeTitle}. Claim your {xpReward} XP!",
    "data": { "challengeId": "{challengeId}", "type": "challenge_complete" }
  }
}
```

#### 3.3.2 Local Notifications (Flutter)

For immediate cue display without server round-trip:

```dart
class LocalCueScheduler {
  final FlutterLocalNotificationsPlugin _notifications;

  Future<void> scheduleHabitReminder(Habit habit, DateTime reminderTime) async {
    final androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Reminders for your daily habits',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('complete', 'Complete'),
        AndroidNotificationAction('snooze', 'Snooze 15min'),
      ],
    );

    await _notifications.zonedSchedule(
      habit.id.hashCode,
      'Time for ${habit.title}!',
      'Keep your streak going 🔥',
      _nextInstanceOfTime(reminderTime),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
```

### 3.4 Analytics & Metrics

#### 3.4.1 Cue Engagement Tracking

```typescript
export const trackCueEngagement = functions.https.onCall(
  async (data, context) => {
    const { cueId, action, timeToAction } = data;

    const metrics = {
      cueId,
      action, // "shown" | "dismissed" | "completed" | "snoozed"
      timeToAction,
      timestamp: Date.now(),
      userId: context.auth.uid
    };

    await logEngagementMetrics(metrics);

    // Update cue effectiveness score
    if (action === 'completed') {
      await updateCueEffectiveness(cueId, timeToAction);
    }
  }
);
```

#### 3.4.2 Analytics Dashboard Data

```typescript
export const getUserAnalytics = functions.https.onCall(
  async (data, context) => {
    const { userId, period } = data; // "week" | "month" | "year"

    return {
      completionRate: await calculateCompletionRate(userId, period),
      streakHistory: await getStreakHistory(userId, period),
      cueEffectiveness: await getCueEffectiveness(userId),
      attributeDistribution: await getAttributeXpDistribution(userId),
      engagementScore: await calculateEngagementScore(userId)
    };
  }
);
```

---

## Part IV: Feature Review & Spec Compliance

### 4.1 Feature Compliance Matrix

| Feature | Spec Requirement | Current Implementation | Gap | Priority |
|---------|-----------------|----------------------|-----|----------|
| **Habit Creation** | User can create habits with attribute, difficulty, time-of-day, cue configuration | Partial - entity exists but creation flow incomplete | No dedicated creation UI; cue config not surfaced | HIGH |
| **Progress Tracking** | Display streaks, attribute XP, completion rates, identity votes | Partial - basic tracking exists | Missing heatmap, attribute breakdown UI, vote visualization | HIGH |
| **Habit Completion** | Toggle completion, XP calculation, streak updates, rewards | Partial - completion marking works | No celebration animation; variable rewards not implemented | HIGH |
| **Cues System** | Time, location, context, social, habit stacking, energy, milestone, recovery, AI triggers | Entity defined but not implemented | Full implementation required | CRITICAL |
| **World Map Progression** | Section-based unlocking, node states, XP distribution | Strong implementation | Visual decay not connected to health data | MEDIUM |
| **Challenge System** | Quest creation, progress tracking, completion rewards | Good - filters and progress work | Creation flow incomplete; no social challenges | MEDIUM |
| **Social Features** | Tribes, friends, accountability, contracts | Partial - screens exist | Functionality incomplete | MEDIUM |

### 4.2 Behavioral Psychology Compliance

| Principle | Implementation | Compliance |
|-----------|---------------|------------|
| **Make It Obvious (1st Law)** | Cue triggers defined but not active | 30% |
| **Make It Attractive** | Archetype themes, visual design | 80% |
| **Make It Easy** | Timeline sectioning, one-tap completion | 70% |
| **Make It Satisfying** | XP rewards, streaks | 40% |
| **Variable Rewards** | Not implemented | 0% |
| **Investment (2nd Law)** | World map progression, avatar evolution | 70% |
| **Habit Stacking** | Defined in CueTriggerType but not active | 20% |

### 4.3 Technical Debt & Quality Issues

1. **State Management**: Mix of `ConsumerWidget` and `StatefulWidget` - standardize on Riverpod
2. **Error Handling**: Inconsistent error states across screens - establish patterns
3. **Loading States**: Various implementations - create shared skeleton components
4. **Animation**: Mix of manual and library-based - document approach

---

## Part V: Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)

**Priority: CRITICAL**

1. **Cue System Core**
   - Implement `CueScheduler` service
   - Create local notification integration
   - Build cue provider in Riverpod

2. **Habit Creation Flow**
   - Create `CreateHabitScreen`
   - Implement form validation
   - Connect to Firestore

### Phase 2: Progress & Completion (Weeks 3-4)

**Priority: HIGH**

1. **Progress Display**
   - Add streak visualization
   - Implement attribute progress bars
   - Build identity votes display

2. **Completion Enhancements**
   - Add celebration animations
   - Implement variable rewards
   - Create completion sound/haptic feedback

### Phase 3: World Map Integration (Weeks 5-6)

**Priority: MEDIUM**

1. **Visual Decay**
   - Connect world health to background visuals
   - Implement node state animations

2. **Progression Rewards**
   - Add section completion celebrations
   - Implement unlock animations

### Phase 4: Social Features (Weeks 7-8)

**Priority: MEDIUM**

1. **Challenge System**
   - Complete challenge creation flow
   - Add progress synchronization

2. **Accountability**
   - Implement partner notification triggers
   - Add contract progress tracking

---

## Part VI: Best Practices Integration

### 6.1 Hook Model Deep Integration

```
                    ┌─────────────────┐
                    │    TRIGGER     │
                    │  (Cue System)  │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │     ACTION      │
                    │ (Habit Complete)│
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ VARIABLE       │
                    │    REWARD      │
                    │ (XP, Streaks,  │
                    │  Celebrations) │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  INVESTMENT    │
                    │ (World Progress,│
                    │  Avatar, Votes) │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │    TRIGGER     │
                    │  (Next Cycle)  │
                    └─────────────────┘
```

### 6.2 UX Best Practices from Research

1. **Progressive Disclosure**: Don't overwhelm new users
   - First session: Just create a habit
   - Week 1: Add reminder configuration
   - Week 2+: Introduce advanced cues

2. **Celebration Timing**: Immediate feedback loop
   - Within 100ms: Visual checkmark
   - Within 500ms: XP increment animation
   - Within 2s: Streak update if applicable

3. **Notification Respect**: Honor quiet hours and preferences
   - Default: 9 AM, 12 PM, 6 PM
   - User-configurable
   - Archetype-specific optimal times

### 6.3 Flutter Best Practices (2025)

1. **Riverpod 3.0 Patterns**
   - Use `AsyncNotifier` for async operations
   - Use `Notifier` for synchronous state
   - Implement code generation with `riverpod_annotation`

2. **Performance**
   - Use `ref.select()` to limit rebuilds
   - Implement `const` constructors where possible
   - Lazy load heavy components

---

## Appendix A: File Locations Reference

| Feature | Primary File | Supporting Files |
|---------|-------------|------------------|
| Timeline | `timeline_screen.dart` | `week_calendar_strip.dart`, `habit_timeline_section.dart` |
| World Map | `world_map_screen.dart` | `level_immersive_screen.dart`, `curved_map_layout.dart` |
| Profile | `future_self_studio_screen.dart` | `evolving_silhouette_widget.dart`, `trajectory_timeline.dart` |
| Challenges | `challenges_screen.dart` | `challenge_detail_screen.dart`, `create_solo_challenge_dialog.dart` |
| Cues | `cue.dart` | (new files: cue_scheduler.dart, cue_provider.dart) |

## Appendix B: API Reference

### Riverpod Providers to Create

```dart
// cue_provider.dart
final cueSchedulerProvider = Provider<CueScheduler>((ref) => CueScheduler());
final activeCuesProvider = StreamProvider<List<Cue>>((ref) => /* ... */);
final cuePersonalizationProvider = FutureProvider<List<Cue>>((ref) => /* ... */);

// habit_creation_provider.dart
final createHabitNotifierProvider = NotifierProvider<CreateHabitNotifier, CreateHabitState>(
  CreateHabitNotifier.new,
);

// progress_providers.dart
final habitProgressProvider = Provider.family<HabitProgress, String>((ref, habitId) => /* ... */);
final attributeProgressProvider = Provider<Map<HabitAttribute, double>>((ref) => /* ... */);
```

### Firestore Indexes Required

```json
{
  "indexes": [
    {
      "collectionGroup": "cues",
      "fields": [
        { "fieldPath": "userId", "order": "ASC" },
        { "fieldPath": "isShown", "order": "ASC" },
        { "fieldPath": "priority", "order": "DESC" }
      ]
    },
    {
      "collectionGroup": "completions",
      "fields": [
        { "fieldPath": "userId", "order": "ASC" },
        { "fieldPath": "completedDate", "order": "DESC" }
      ]
    }
  ]
}
```

---

*Document Version: 1.0*
*Created: March 16, 2026*
*Target: Emerge App Production Release*
*Classification: Technical Specification*