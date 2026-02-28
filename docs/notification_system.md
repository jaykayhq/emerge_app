# Notification System Documentation

## Overview

Emerge's notification system is an **archetype-themed** notification platform that delivers personalized, identity-based notifications to reinforce habit formation. Each user receives notifications tailored to their chosen archetype (Athlete, Scholar, Creator, Stoic, Zealot, or Explorer), with unique messaging, timing, and visual styling that aligns with their identity journey.

The system uses a **hybrid architecture** combining local and cloud-based notifications to ensure reliability, cross-device synchronization, and minimal battery impact.

## Architecture

### Hybrid Approach

The notification system combines two complementary strategies:

#### 1. Local Notifications (`flutter_local_notifications`)
- **Purpose:** Immediate notifications, scheduled reminders
- **Use Cases:**
  - Welcome notifications when habits are created
  - Recurring habit reminders (daily, weekly, specific days)
  - Streak warnings (scheduled 1 hour after reminder time)
  - Level up notifications
  - Achievement unlocks
  - Weekly recap notifications
- **Advantages:**
  - Works offline
  - No server latency
  - Battery-efficient scheduling
  - Precise timing control

#### 2. Cloud Functions (Firebase Cloud Messaging)
- **Purpose:** Cross-device sync, AI-powered insights, community updates
- **Use Cases:**
  - Daily AI insights (scheduled 9 AM UTC)
  - Community/tribe activity notifications
  - Scheduled streak warnings via cloud
- **Advantages:**
  - Cross-device synchronization
  - Server-side personalization
  - Real-time updates
  - Centralized logging

#### 3. Cross-Device Synchronization
- FCM tokens stored in Firestore (`users/{userId}.fcmToken`)
- Notification schedules synced to `users/{userId}/notificationSchedules/{habitId}`
- Ensures consistent notification experience across devices

### Key Components

```
lib/core/services/
├── notification_service.dart          # Main notification service (local + FCM)
├── notification_templates.dart        # Archetype-themed message templates
└── archetype_theme.dart               # Visual theming (colors, icons)

lib/features/habits/
├── domain/entities/
│   └── habit_notification_schedule.dart  # Notification schedule entity
└── data/repositories/
    └── habit_notification_repository.dart # Firestore sync operations

functions/src/
└── habit_notifications.ts             # Cloud Functions for notifications
```

## Notification Types

### 1. Habit Reminders

**Purpose:** Daily/weekly reminders to complete habits

**Trigger:** Scheduled based on habit frequency and user-selected time

**Channel:** `{archetype}_habits` (e.g., `athlete_habits`, `scholar_habits`)

**Implementation:**
```dart
await notificationService.scheduleHabitReminder(
  habitId,
  habitTitle,
  UserArchetype.athlete,
  '06:00',  // 6:00 AM
  HabitFrequency.daily,
  [],  // Empty for daily
);
```

**Content Examples:**
- **Athlete:** "💪 Time to train! Your 'Morning Sprints' session awaits. Make yourself proud!"
- **Scholar:** "📚 Knowledge calls! Your 'Deep Reading' study session is ready. Begin the quest."
- **Creator:** "🎨 Inspiration strikes! Time for your 'Daily Sketch' creative flow. Create today."
- **Stoic:** "🏛️ Master yourself! Your 'Negative Visualization' practice awaits. Show your discipline."
- **Zealot:** "🔥 Stay the path! Your sacred 'Morning Prayer' devotion calls. Honor your commitment."
- **Explorer:** "⏰ Time to focus! Complete your habit to stay on track with your goals."

**Frequency Support:**
- **Daily:** Repeats every day at specified time
- **Weekly:** Repeats on specific day(s) of week
- **Specific Days:** Custom selection of days (e.g., Mon, Wed, Fri)

---

### 2. Streak Warnings

**Purpose:** Alert users when their habit streak is at risk

**Trigger:** 1 hour after reminder time if habit not completed (streak ≥ 3 days)

**Channel:** `streak_warnings`

**Implementation:**
```dart
await notificationService.scheduleStreakWarning(
  habitId,
  habitTitle,
  UserArchetype.athlete,
  '06:00',
  21,  // Current streak days
);
```

**Content Examples:**
- **Athlete:** "⚠️ 💪 Your 21-day training streak is at risk! Don't lose your momentum—train now!"
- **Scholar:** "⚠️ 📚 Your 21-day knowledge quest is fading! Protect your streak—learn now."
- **Zealot:** "⚠️ 🔥 Your 21-day sacred devotion wavers! Rekindle your flame—act now."

**Cloud Function:**
- Function: `sendStreakWarnings` (scheduled every 15 minutes)
- Checks for uncompleted habits with streaks ≥ 3 days
- Respects user's `streakWarnings` setting

---

### 3. AI Insights

**Purpose:** Daily personalized coaching and recommendations

**Trigger:** Daily at 9 AM UTC (via Cloud Functions)

**Channel:** `ai_insights`

**Importance:** Low (to avoid disruption)

**Implementation:**
```dart
await notificationService.sendDailyInsight(
  userId,
  'Based on your patterns, you perform best in the morning. Consider scheduling challenging habits before noon.',
  UserArchetype.scholar,
);
```

**Content Examples:**
- **Athlete:** "💪 Your training insights are ready! Optimize your performance today."
- **Scholar:** "📚 Wisdom awaits! Your personalized learning insights have arrived."
- **Creator:** "🎨 Creative inspiration delivered! Your muse has new insights for you."
- **Stoic:** "🏛️ Clarity awaits! Your daily reflection on mastery and discipline is here."
- **Zealot:** "🔥 Divine guidance! Your sacred insights for the path have been revealed."
- **Explorer:** "✨ Your daily insights are ready! Discover what's possible today."

**Content:** Generated by Groq AI service, personalized to user's habit patterns and archetype

---

### 4. Level Ups

**Purpose:** Celebrate when user advances to a new level

**Trigger:** Firestore `onUpdate` when `avatarStats.level` increases

**Channel:** `rewards`

**Importance:** High

**Implementation:**
```dart
await notificationService.notifyLevelUp(
  userId,
  5,  // New level
  UserArchetype.athlete,
);
```

**Content Examples:**
- **Athlete:** "🏆 💪 LEVEL UP! You've reached Level 5! Your training yields greatness!"
- **Scholar:** "🏆 📚 WISDOM GROWS! You've reached Level 5! Knowledge expands within you."
- **Creator:** "🏆 🎨 MUSE FAVORS YOU! You've reached Level 5! Your artistry elevates!"
- **Stoic:** "🏆 🏛️ MASTERY AWAITS! You've reached Level 5! Your discipline strengthens!"
- **Zealot:** "🏆 🔥 SACRED ASCENSION! You've reached Level 5! Your devotion burns brighter!"
- **Explorer:** "🏆 LEVEL UP! You've reached Level 5! Keep up the amazing work!"

**Visuals:** Archetype-themed colors and styling

---

### 5. Achievements

**Purpose:** Celebrate milestone achievements and badges

**Trigger:** When achievement is unlocked

**Channel:** `rewards`

**Importance:** High

**Implementation:**
```dart
await notificationService.notifyAchievement(
  userId,
  '7-Day Streak',
  UserArchetype.athlete,
);
```

**Content Examples:**
- **Athlete:** "🏅 💪 ACHIEVEMENT UNLOCKED: 7-Day Streak! Your dedication knows no bounds!"
- **Scholar:** "🏅 📚 KNOWLEDGE CONQUERED: Bookworm! Your quest for wisdom succeeds!"
- **Creator:** "🏅 🎨 MASTERPIECE CREATED: First Portfolio Piece! Your creative vision manifests!"
- **Stoic:** "🏅 🏛️ VIRTUE ATTAINED: Emotional Control! Your stoic practice bears fruit!"
- **Zealot:** "🏅 🔥 SACRED HONOR EARNED: 30-Day Devotion! Your devotion is recognized!"
- **Explorer:** "🏅 ACHIEVEMENT UNLOCKED: First Steps! You're making incredible progress!"

---

### 6. Community Updates

**Purpose:** Notify users about tribe activity, challenges, and social engagement

**Trigger:** Real-time events (tribe joins, challenge completions, etc.)

**Channel:** `community_updates`

**Importance:** Medium

**Examples:**
- "Your tribe member completed the 30-Day Meditation Challenge!"
- "New weekly challenge available: Morning Ritual Mastery"
- "Someone in your tribe just earned the 'Early Bird' badge"

---

### 7. Weekly Recap

**Purpose:** Summarize user's weekly progress and world evolution

**Trigger:** Every Monday at 9:00 AM

**Channel:** `weekly_recap`

**Importance:** High

**Implementation:**
```dart
await notificationService.scheduleWeeklyRecap();
```

**Content:** "Weekly Recap Ready - Check out how your world evolved this week!"

**Payload:** `/world/recap` (deep link to recap screen)

---

## Archetype Defaults Table

Each archetype has carefully chosen defaults aligned with its philosophy and typical daily routine:

| Archetype | Default Time | Icon Asset | Primary Color | Accent Color | Philosophy |
|-----------|--------------|------------|---------------|--------------|------------|
| **Athlete** | 6:00 AM | `icon_athlete` | `#FF5252` (Red) | `#FF8E72` (Orange-Red) | Early morning training for peak performance |
| **Scholar** | 8:00 AM | `icon_scholar` | `#7C3AED` (Purple) | `#B794F6` (Light Purple) | Mind is fresh after morning routine |
| **Creator** | 9:00 AM | `icon_creator` | `#FFD700` (Gold) | `#FFD93D` (Yellow-Gold) | Creative peak after morning warm-up |
| **Stoic** | 5:00 AM | `icon_stoic` | `#26A69A` (Teal) | `#4DD4AC` (Light Teal) | Early morning discipline before world wakes |
| **Zealot** | 6:00 AM | `icon_zealot` | `#991B1B` (Deep Red) | `#B45309` (Amber) | Morning devotion before daily distractions |
| **Explorer** | 7:00 AM | `icon_default` | `#009688` (Teal) | `#64FFDA` (Mint) | Balanced start for flexible exploration |

### Default Times Rationale

- **Stoic (5 AM):** Earliest start for disciplined self-mastery before dawn
- **Athlete (6 AM):** Training time when body is rested and world is quiet
- **Zealot (6 AM):** Morning devotion for spiritual focus before daily chaos
- **Explorer (7 AM):** Balanced start for flexible daily exploration
- **Scholar (8 AM):** Mind is fresh after morning routine and hydration
- **Creator (9 AM):** Creative peak after morning warm-up and inspiration gathering

### Color Mapping (Implementation)

Colors are defined in `lib/core/theme/archetype_theme.dart`:

```dart
class ArchetypeTheme {
  final IdentityThemeExtension darkColors;
  final IdentityThemeExtension lightColors;

  // Used in notification styling:
  final primaryColor = darkColors.primaryColor;
  final accentColor = darkColors.accentColor;
}
```

---

## Do Not Disturb (DND)

### Quiet Hours

**Time Range:** 10:00 PM - 7:00 AM UTC

**Purpose:** Prevent notification disruption during sleep hours

**Implementation:**

The DND setting is stored in the user's document:

```dart
// users/{userId}
{
  notificationSettings: {
    doNotDisturb: true,
    // ... other settings
  }
}
```

**Cloud Function Logic:**

```typescript
// Check if current time is within DND hours
const hour = new Date().getUTCHours();
const isDoNotDisturb = userSettings.doNotDisturb && (hour >= 22 || hour < 7);

if (isDoNotDisturb) {
  console.log('DND active: skipping notification');
  return;
}
```

**User Control:**

Users can toggle DND in Settings > Notifications > Do Not Disturb

---

## User Settings

All notification types respect user preferences stored in Firestore:

### Settings Structure

```dart
// users/{userId}
{
  notificationSettings: {
    // Master toggle
    notificationsEnabled: true,

    // Individual notification types
    habitReminders: true,
    streakWarnings: true,
    aiInsights: true,
    communityUpdates: true,
    rewardsUpdates: true,

    // Do Not Disturb
    doNotDisturb: false,
  }
}
```

### Settings Description

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `notificationsEnabled` | Boolean | `true` | Master toggle for all notifications |
| `habitReminders` | Boolean | `true` | Enable/disable habit reminder notifications |
| `streakWarnings` | Boolean | `true` | Enable/disable streak at-risk warnings |
| `aiInsights` | Boolean | `true` | Enable/disable daily AI coaching insights |
| `communityUpdates` | Boolean | `true` | Enable/disable tribe/social notifications |
| `rewardsUpdates` | Boolean | `true` | Enable/disable level-up and achievement notifications |
| `doNotDisturb` | Boolean | `false` | Enable quiet hours (10 PM - 7 AM UTC) |

### Settings Screen

**Location:** `lib/features/settings/presentation/screens/notification_settings_screen.dart`

**UI Controls:**
- Master toggle (switch)
- Individual notification type toggles (switches)
- Do Not Disturb toggle (switch)
- Time picker for custom quiet hours (future enhancement)

---

## Firestore Schema

### Collection: `users/{userId}/notificationSchedules/{habitId}`

Stores notification scheduling configuration for each habit.

#### Document Structure

```typescript
{
  // Identifiers
  habitId: string,           // ID of the habit this schedule belongs to
  userId: string,            // ID of the user who owns this schedule

  // Archetype & Timing
  archetype: 'athlete' | 'scholar' | 'creator' | 'stoic' | 'zealot' | 'none',
  reminderTime: "HH:MM",     // 24-hour format, e.g., "06:00"
  frequency: 'daily' | 'weekly' | 'specificDays',
  specificDays: [1,2,3,4,5,6,7],  // 1=Monday, 7=Sunday (for weekly/specific)

  // Status Tracking
  welcomeNotified: boolean,  // Whether the welcome notification has been sent
  lastReminderSent: ISO8601 timestamp | null,
  enabled: boolean,          // Whether notifications are enabled for this habit

  // Cloud Sync
  fcmToken: string | null,   // Current FCM token for push notifications

  // Streak Warning Tracking
  lastStreakWarningSent: ISO8601 timestamp | null,
  streakWarningCount: number,

  // Metadata
  createdAt: ISO8601 timestamp
}
```

#### Example Document

```json
{
  "habitId": "abc123xyz",
  "userId": "user789",
  "archetype": "athlete",
  "reminderTime": "06:00",
  "frequency": "daily",
  "specificDays": [],
  "welcomeNotified": true,
  "lastReminderSent": "2026-02-28T06:00:00.000Z",
  "enabled": true,
  "fcmToken": "dHJhc2g...",
  "lastStreakWarningSent": "2026-02-28T07:00:00.000Z",
  "streakWarningCount": 1,
  "createdAt": "2026-02-20T10:30:00.000Z"
}
```

#### Index Requirements

No composite indexes required for this collection.

Queries are simple document lookups by habit ID:
```dart
await firestore
  .collection('users')
  .doc(userId)
  .collection('notificationSchedules')
  .doc(habitId)
  .get();
```

---

## Implementation Details

### File: `lib/core/services/notification_service.dart`

**Key Methods:**

```dart
class NotificationService {
  // Initialize notification service (FCM + local)
  Future<void> initialize();

  // Habit Reminders
  Future<void> notifyHabitCreated(Habit habit, UserArchetype archetype);
  Future<void> scheduleHabitReminder(
    String habitId,
    String habitTitle,
    UserArchetype archetype,
    String reminderTime,
    HabitFrequency frequency,
    List<int> specificDays,
  );
  Future<void> cancelHabitNotifications(String habitId);
  Future<void> updateHabitNotification(...);

  // Streak Warnings
  Future<void> scheduleStreakWarning(
    String habitId,
    String habitTitle,
    UserArchetype archetype,
    String reminderTime,
    int currentStreak,
  );

  // Achievements & Level Ups
  Future<void> notifyLevelUp(
    String userId,
    int newLevel,
    UserArchetype archetype,
  );
  Future<void> notifyAchievement(
    String userId,
    String achievementName,
    UserArchetype archetype,
  );

  // AI Insights
  Future<void> sendDailyInsight(
    String userId,
    String insight,
    UserArchetype archetype,
  );

  // Weekly Recap
  Future<void> scheduleWeeklyRecap();
}
```

### File: `lib/core/services/notification_templates.dart`

**Key Methods:**

```dart
class NotificationTemplates {
  // Message generators
  static String welcomeMessage(UserArchetype archetype, String habitTitle);
  static String reminderMessage(UserArchetype archetype, String habitTitle);
  static String streakWarning(UserArchetype archetype, int streakDays);
  static String aiInsightGreeting(UserArchetype archetype);
  static String levelUp(UserArchetype archetype, int newLevel);
  static String achievement(UserArchetype archetype, String achievementName);

  // Default time getter
  static int getDefaultHour(UserArchetype archetype);
}

class NotificationChannels {
  static String channelForArchetype(UserArchetype archetype);
  static const String habitReminders = 'habit_reminders';
  static const String streakWarnings = 'streak_warnings';
  static const String aiInsights = 'ai_insights';
  static const String communityUpdates = 'community_updates';
  static const String rewards = 'rewards';
  static const String weeklyRecap = 'weekly_recap';
}
```

### File: `lib/features/habits/data/repositories/habit_notification_repository.dart`

**Key Methods:**

```dart
class HabitNotificationRepository {
  // Schedule management
  Future<void> scheduleHabitNotifications(Habit habit, UserArchetype archetype);
  Future<void> updateHabitNotifications(Habit habit, UserArchetype archetype);
  Future<void> cancelHabitNotifications(String habitId);

  // Special notifications
  Future<void> scheduleStreakWarning(...);
  Future<void> notifyLevelUp(int newLevel, UserArchetype archetype);
  Future<void> notifyAchievement(String achievementName, UserArchetype archetype);

  // Query schedules
  Stream<List<HabitNotificationSchedule>> getNotificationSchedules();
}
```

---

## Testing

### Unit Tests

**Location:** `test/core/services/notification_templates_test.dart`

**Run:**
```bash
flutter test test/core/services/notification_templates_test.dart
```

**Coverage:**
- Welcome messages for all archetypes
- Reminder messages for all archetypes
- Streak warnings with streak days
- AI insight greetings
- Level up messages
- Achievement messages
- Default hour values
- Channel ID mappings
- Icon mappings

**Test Results:**
```bash
✓ welcomeMessage returns correct messages for all archetypes
✓ welcomeMessage handles empty habit title
✓ reminderMessage returns correct messages for all archetypes
✓ streakWarning includes streak days for all archetypes
✓ streakWarning handles zero streak days
✓ aiInsightGreeting returns correct messages for all archetypes
✓ levelUp returns correct messages for all archetypes
✓ levelUp handles zero level
✓ achievement returns correct messages for all archetypes
✓ achievement handles empty achievement name
✓ getDefaultHour returns correct hour for all archetypes
✓ channelForArchetype returns correct channel IDs for all archetypes
✓ archetypeIcons returns correct icon names for all archetypes
```

### Integration Tests

**Location:** `test/integration_test/app_test.dart`

**Run:**
```bash
flutter test integration_test/app_test.dart
```

**Coverage:**
- Full notification flow from habit creation to reminder delivery
- Settings persistence and respect
- Cross-device synchronization (via Firestore)

### Manual Testing Checklist

**Test on Physical Device:**

```bash
flutter run --release
```

**Checklist:**

- [ ] **Create Habit → Welcome Notification**
  1. Create a new habit
  2. Verify immediate welcome notification appears
  3. Verify notification shows correct archetype styling (color, icon, message)

- [ ] **Habit Reminder Scheduling**
  1. Create habit with reminder time 2 minutes in future
  2. Wait for reminder
  3. Verify notification appears at scheduled time
  4. Verify notification content matches archetype

- [ ] **Edit Habit Reminder**
  1. Edit habit reminder time
  2. Verify old notification is cancelled
  3. Verify new notification scheduled at new time

- [ ] **Delete Habit → Cancel Notifications**
  1. Delete a habit with scheduled notifications
  2. Verify all notifications for that habit are cancelled

- [ ] **Streak Warning**
  1. Create habit with 3+ day streak
  2. Set reminder time 2 minutes in future
  3. Wait for reminder (don't complete habit)
  4. Verify streak warning appears 1 hour after reminder time

- [ ] **Level Up Notification**
  1. Complete enough habits to level up
  2. Verify level up notification appears
  3. Verify message matches archetype

- [ ] **Achievement Notification**
  1. Unlock an achievement (e.g., 7-day streak)
  2. Verify achievement notification appears
  3. Verify message matches archetype

- [ ] **Do Not Disturb**
  1. Enable DND in settings
  2. Schedule notification during quiet hours (10 PM - 7 AM UTC)
  3. Verify notification is suppressed
  4. Disable DND
  5. Verify notifications resume

- [ ] **Master Toggle**
  1. Disable all notifications in settings
  2. Create habit
  3. Verify no notifications appear
  4. Re-enable notifications
  5. Verify notifications resume

- [ ] **Weekly Recap**
  1. Wait for Monday 9 AM
  2. Verify weekly recap notification appears
  3. Tap notification
  4. Verify app navigates to recap screen

---

## Troubleshooting

### Notifications Not Appearing

**Symptoms:** No notifications appear when expected

**Diagnosis Steps:**

1. **Check Notification Permissions**
   ```dart
   // In notification_service.dart initialize()
   NotificationSettings settings = await _firebaseMessaging.requestPermission();
   print('Permission status: ${settings.authorizationStatus}');
   ```
   - Go to: Settings > Apps > Emerge > Notifications
   - Ensure notifications are enabled

2. **Verify Master Toggle**
   ```bash
   # Check Firestore
   firebase firestore:get --project your-project-id users/{userId}
   ```
   - Ensure `notificationSettings.notificationsEnabled` is `true`

3. **Check Do Not Disturb**
   - Ensure current time is not within 10 PM - 7 AM UTC if DND is enabled
   - Check `notificationSettings.doNotDisturb` in Firestore

4. **Verify FCM Token**
   ```bash
   # Check if token exists
   firebase firestore:get --project your-project-id users/{userId}
   ```
   - Look for `fcmToken` field
   - If missing, re-run app to trigger token registration

5. **Check Notification Channel (Android)**
   - Go to: Settings > Apps > Emerge > Notifications > Categories
   - Ensure archetype channel is not disabled

---

### Streak Warnings Not Sending

**Symptoms:** Streak warnings don't appear after reminder time

**Diagnosis Steps:**

1. **Verify Streak Length**
   - Streak warnings only trigger for streaks ≥ 3 days
   - Check habit streak in Firestore

2. **Check Streak Warning Setting**
   ```bash
   # Check Firestore
   firebase firestore:get --project your-project-id users/{userId}
   ```
   - Ensure `notificationSettings.streakWarnings` is `true`

3. **Confirm Cloud Function Deployment**
   ```bash
   firebase functions:list
   ```
   - Verify `sendStreakWarnings` is deployed

4. **Check Cloud Function Logs**
   ```bash
   firebase functions:log --only sendStreakWarnings
   ```
   - Look for errors or execution logs

5. **Verify Schedule Configuration**
   - Check `lastStreakWarningSent` timestamp
   - Ensure warning was not already sent today

---

### Cloud Functions Issues

**Symptoms:** Cloud Functions not executing or errors

**Diagnosis Steps:**

1. **Check Function Status**
   ```bash
   firebase functions:list
   ```
   - Verify all functions are deployed

2. **View Logs**
   ```bash
   # All logs
   firebase functions:log

   # Specific function
   firebase functions:log --only sendStreakWarnings
   ```

3. **Redeploy Functions**
   ```bash
   cd functions
   npm run build
   cd ..
   firebase deploy --only functions
   ```

4. **Check Scheduled Jobs**
   - Verify pub/sub topics are created
   - Check scheduler logs in Google Cloud Console

---

### Time Zone Issues

**Symptoms:** Notifications arriving at wrong time

**Diagnosis Steps:**

1. **Check Timezone Configuration**
   ```dart
   // In notification_service.dart initialize()
   tz.initializeTimeZones();
   tz.setLocalLocation(tz.getLocation('UTC'));
   ```
   - Currently using UTC as fallback

2. **Verify Reminder Time Format**
   - Ensure times are in "HH:MM" 24-hour format
   - Check for leading zeros (e.g., "06:00" not "6:0")

3. **Test with Specific Time**
   ```dart
   // Schedule 2 minutes from now for testing
   final now = DateTime.now();
   final testTime = '${(now.hour + 1).toString().padLeft(2, '0')}:00';
   ```

---

### Battery Optimization Killing Notifications

**Symptoms:** Notifications stop working after app is backgrounded

**Solution:**

1. **Disable Battery Optimization (Android)**
   - Go to: Settings > Apps > Emerge > Battery
   - Set to "Unrestricted"

2. **Allow Background Activity**
   - Go to: Settings > Apps > Emerge > Mobile Data
   - Enable "Allow background data usage"

3. **Test Background Execution**
   ```bash
   # Schedule notification 10 minutes in future
   # Put app in background
   # Wait for notification
   ```

---

## Cloud Functions Deployment

### Deployment Commands

**Deploy All Functions:**
```bash
firebase deploy --only functions
```

**Deploy Specific Function:**
```bash
firebase deploy --only functions:sendStreakWarnings
```

**Deploy with Region:**
```bash
firebase deploy --only functions --region us-central1
```

### Viewing Logs

**Real-time Logs:**
```bash
firebase functions:log
```

**Specific Function:**
```bash
firebase functions:log --only sendStreakWarnings
```

**Tail Logs:**
```bash
firebase functions:log --only sendStreakWarnings --limit 50
```

### Cloud Functions Implementation

**Location:** `functions/src/habit_notifications.ts`

**Key Functions:**

```typescript
// Send streak warnings to users with uncompleted habits
export const sendStreakWarnings = onSchedule(
  'every 15 minutes',
  async (event) => {
    // Query users with enabled streak warnings
    // Check habits with streaks >= 3 days
    // Send FCM notifications if habit not completed
  }
);

// Send daily AI insights
export const sendDailyInsights = onSchedule(
  'every day 09:00',
  async (event) => {
    // Generate AI insights
    // Send FCM notifications
  }
);
```

**Scheduled Jobs:**
- `sendStreakWarnings`: Every 15 minutes
- `sendDailyInsights`: Daily at 9:00 AM UTC

---

## Best Practices

### For Developers

1. **Always Use Archetype Parameter**
   - Never hardcode notification messages
   - Always pass `UserArchetype` to notification methods

2. **Respect User Settings**
   - Check `notificationSettings` before sending
   - Implement graceful fallback if settings are missing

3. **Handle Errors Gracefully**
   - Never crash the app if notification fails
   - Log errors for debugging
   - Provide user feedback for critical failures

4. **Test on Physical Devices**
   - Emulators don't always replicate notification behavior
   - Test on both Android and iOS

5. **Monitor FCM Token Rotation**
   - Tokens can rotate (user reinstalls app, etc.)
   - Implement token refresh listener

### For Users

1. **Customize Reminder Times**
   - Choose times that fit your daily routine
   - Consider archetype defaults as starting points

2. **Enable Streak Warnings**
   - Protect your hard-earned streaks
   - Get timely reminders before losing progress

3. **Review AI Insights**
   - Personalized recommendations can optimize your habit practice
   - Insights improve over time as the system learns your patterns

4. **Adjust DND Hours**
   - Ensure notifications don't disrupt sleep
   - Consider your timezone vs UTC offset

---

## Future Enhancements

### Planned Features

1. **Custom Quiet Hours**
   - Allow users to set custom DND time ranges
   - Different quiet hours for weekdays vs weekends

2. **Notification Batches**
   - Group multiple reminders into single notification
   - Reduce notification fatigue

3. **Snooze Functionality**
   - Allow users to snooze reminders
   - Reschedule for later in the day

4. **Smart Scheduling**
   - AI-optimized reminder times based on completion patterns
   - Adaptive scheduling based on user behavior

5. **Rich Notifications**
   - Add action buttons (Complete, Snooze, Skip)
   - Inline progress indicators
   - Archetype-themed notification backgrounds

6. **Notification History**
   - View past notifications
   - Analytics on notification engagement

---

## Summary

The Emerge notification system is a comprehensive, archetype-themed platform designed to reinforce identity-based habit formation. By combining local and cloud notifications, the system ensures reliable delivery while maintaining cross-device synchronization.

**Key Features:**
- Archetype-themed messaging and visual styling
- Hybrid architecture for reliability and performance
- Cross-device synchronization via Firestore
- Respects user preferences and quiet hours
- Comprehensive testing and troubleshooting support

**Files Reference:**
- Service: `lib/core/services/notification_service.dart`
- Templates: `lib/core/services/notification_templates.dart`
- Repository: `lib/features/habits/data/repositories/habit_notification_repository.dart`
- Entity: `lib/features/habits/domain/entities/habit_notification_schedule.dart`
- Tests: `test/core/services/notification_templates_test.dart`
- Cloud Functions: `functions/src/habit_notifications.ts`

**Support:**
For issues or questions, refer to the Troubleshooting section or check Firebase Cloud Functions logs.
