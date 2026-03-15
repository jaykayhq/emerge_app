# CUE IMPLEMENTATION STRATEGY
## Emerge App - Comprehensive "Make It Obvious" Framework

**Document Version:** 1.0
**Last Updated:** 2025-03-14
**Status:** Implementation Ready

---

## EXECUTIVE SUMMARY

This document outlines the comprehensive cue implementation strategy for the Emerge App, operationalizing the **1st Law of Behavior Change: MAKE IT OBVIOUS**. Drawing from behavioral science research (James Clear, *Atomic Habits*; B.J. Fogg, *Tiny Habits*), this strategy transforms theoretical principles into actionable Flutter code with measurable outcomes.

### Core Philosophy
- **Cues are Triggers**: Every habit begins with a cue. Quality of cue = Quality of habit initiation.
- **Identity Reinforcement**: Every cue reinforces the user's chosen archetype identity.
- **Friction Management**: Cues reduce friction to action while respecting user's attention.
- **Personalization at Scale**: AI-driven adaptation ensures cues remain novel and effective.

---

## TABLE OF CONTENTS

1. [Psychological Foundations](#1-psychological-foundations)
2. [Cue Architecture](#2-cue-architecture)
3. [Implementation Intentions](#3-implementation-intentions)
4. [Screen-Specific Cue Strategies](#4-screen-specific-cue-strategies)
5. [Timing & Scheduling Logic](#5-timing--scheduling-logic)
6. [Personalization Parameters](#6-personalization-parameters)
7. [Engagement Metrics](#7-engagement-metrics)
8. [Anti-Patterns & Edge Cases](#8-anti-patterns--edge-cases)
9. [Technical Implementation](#9-technical-implementation)

---

## 1. PSYCHOLOGICAL FOUNDATIONS

### 1.1 The Four Laws Context
```
CUE → CRAVING → RESPONSE → REWARD
 ↓
MAKE IT OBVIOUS
```

Our cue system optimizes the first step: **MAKING THE CUE OBVIOUS**.

### 1.2 Key Behavioral Principles

| Principle | Application | Code Reference |
|-----------|-------------|----------------|
| **Implementation Intentions** | "When X happens, I will do Y" | `CueRule.triggerType` |
| **Habit Stacking** | Attach new habits to existing cues | `CueTriggerType.habitStacking` |
| **Environment Design** | Prime the digital/physical space | `CueDeliveryChannel.subtleHint` |
| **Variable Reward Schedule** | Prevent cue habituation | `Cue.priority` randomization |
| **Social Proof** | Tribe activity triggers action | `CueTriggerType.social` |

### 1.3 Archetype-Based Personalization

Each archetype responds to different motivational triggers:

| Archetype | Primary Motivation | Cue Tone | Example |
|-----------|-------------------|----------|---------|
| **Athlete** | Performance, strength | Energetic, competitive | "💪 Your training awaits!" |
| **Scholar** | Knowledge, growth | Curious, thoughtful | "📚 Your quest for wisdom..." |
| **Creator** | Expression, innovation | Inspiring, artistic | "🎨 Inspiration strikes..." |
| **Stoic** | Discipline, mastery | Calm, purposeful | "🏛️ Master yourself..." |
| **Zealot** | Devotion, commitment | Passionate, intense | "🔥 Stay the sacred path..." |

---

## 2. CUE ARCHITECTURE

### 2.1 Cue Entity Structure

```
Cue
├── id: String (unique identifier)
├── triggerType: CueTriggerType (time, location, context, social, etc.)
├── category: CueCategory (initiation, completion, social, celebration, etc.)
├── intensity: CueIntensity (gentle, moderate, urgent, critical)
├── channels: List<CueDeliveryChannel> (push, popup, banner, haptic, etc.)
├── title: String (headline)
├── body: String (actionable message)
├── habitId: String? (associated habit)
├── userArchetype: String (for personalization)
├── triggerData: Map<String, dynamic> (trigger conditions)
├── personalizationTokens: Map<String, String> (dynamic content)
├── priority: int (0-100, queue management)
├── expiresAt: DateTime? (urgency deadline)
└── relevanceScore: double (calculated, 0-100)
```

### 2.2 Cue Types & Use Cases

| Cue Category | Primary Channel | Use Case | Example |
|--------------|-----------------|----------|---------|
| **Initiation** | Push + Banner | Time to start habit | "Morning meditation time!" |
| **Completion** | In-App Popup | Reinforce finished action | "Great job! +15 XP" |
| **Social** | Toast + Badge | Friend completed habit | "Alex just finished reading!" |
| **Celebration** | Modal Dialog | Milestone reached | "🏆 7-day streak!" |
| **Recovery** | Modal Dialog | Streak at risk | "Recover your 5-day streak" |
| **Discovery** | Banner | New habit suggestion | "Try journaling based on..." |
| **Reflection** | Banner | Daily review prompt | "How did today go?" |
| **Motivation** | Push + Haptic | Engagement dropping | "You've got this!" |

### 2.3 Cue Intensity Levels

```
GENTLE (0-30):    Subtle nudges, non-urgent suggestions
MODERATE (31-60): Standard reminders, regular prompts
URGENT (61-80):  Streak at risk, time-sensitive
CRITICAL (81-100): Recovery required, milestone moments
```

**Intensity Escalation Logic:**
```dart
int calculateInitiationIntensity(Habit habit) {
  if (habit.currentStreak == 0) return INTENSITY_MODERATE;
  if (habit.currentStreak < 3) return INTENSITY_MODERATE;
  if (habit.currentStreak < 7) return INTENSITY_GENTLE;
  return INTENSITY_GENTLE; // Established = gentle
}
```

---

## 3. IMPLEMENTATION INTENTIONS

### 3.1 The Formula
> "WHEN [situation arises], I will [perform action]."

### 3.2 Cue Rule System

```dart
CueRule(
  id: 'morning_meditation',
  triggerType: CueTriggerType.time,
  conditions: {
    'hour': 6,
    'minute': 0,
    'days': [1, 2, 3, 4, 5]  // Weekdays only
  },
  cooldown: Duration(hours: 24),
  priority: 80
)
```

### 3.3 Context-Aware Triggers

| Context | Trigger Condition | Example Cue |
|---------|-------------------|------------|
| **Time** | Scheduled time reached | "6:00 AM - Training time!" |
| **Location** | Arrived at gym | "You're at the gym! Ready?" |
| **Energy** | Low energy detected | "Quick 2-min version available" |
| **Social** | Friend completed habit | "Sarah finished her run!" |
| **Habit Stack** | Previous habit completed | "After coffee, time to read!" |
| **Recovery** | Missed yesterday | "Never miss twice - recover now!" |

---

## 4. SCREEN-SPECIFIC CUE STRATEGIES

### 4.1 Timeline Screen

**Purpose:** Daily command center, habit initiation hub

**Cue Strategy:**
- **Morning Stack Cue:** Time-based, shows first 3 morning habits
- **Context-Aware:** Adapts based on time of day (morning/afternoon/evening)
- **Progress Nudges:** Shows completion rate with subtle hints
- **Social Proof:** "5 tribe members active now"

**Implementation:**
```dart
// Timeline shows cues as banners
SliverToBoxAdapter(
  child: CueStreamWidget(
    cues: cueEngine.getActiveCuesForScreen('timeline'),
    onAction: (cue) => _handleCueAction(cue),
  ),
)
```

**Key Cues:**
1. **Habit Initiation Banner** (Morning/Afternoon/Evening stacks)
2. **Progress Update** ("You've completed 3/5 today!")
3. **Social Proof** ("Alex just logged their workout!")
4. **Streak Protection** ("⚠️ Your meditation streak is at risk!")

### 4.2 Create Habit Screen

**Purpose:** Habit formation, identity voting

**Cue Strategy:**
- **Tutorial Cues:** First-time guidance
- **Habit Stacking Suggestions:** "After [existing habit], do [new habit]?"
- **Identity Reinforcement:** "This habit votes for your [Archetype] identity"

**Key Cues:**
1. **Identity Statement Cue:** "I am the type of person who [habit action]"
2. **Habit Stacking Cue:** "Anchor this to [existing habit]?"
3. **Two-Minute Version Cue:** "Start small: [2-min version]"

### 4.3 Tribes Screen

**Purpose:** Social accountability, community engagement

**Cue Strategy:**
- **Tribe Activity Updates:** "Your tribe completed 47 habits today!"
- **Challenge Invites:** "New 7-day challenge starting!"
- **Leaderboard Nudges:** "You're #3 this week! Keep pushing!"

**Key Cues:**
1. **Tribe Pulse:** "🔥 12 members active right now!"
2. **Challenge Countdown:** "Challenge ends in 3 hours!"
3. **Achievement Broadcast:** "🏆 Jane hit 30-day streak!"

### 4.4 Challenges Screen

**Purpose:** Goal-oriented habit engagement

**Cue Strategy:**
- **Challenge Start:** "New challenge available!"
- **Progress Milestones:** "Day 5/7 - Almost there!"
- **Challenge Ending:** "⏰ 2 hours left - finish strong!"

**Key Cues:**
1. **New Challenge Alert:** Weekly spotlight
2. **Daily Quest:** "Today's challenge is ready!"
3. **Completion Reward:** "🎁 You earned +50 XP!"

### 4.5 Friends Screen

**Purpose:** Accountability partnerships

**Cue Strategy:**
- **Partner Activity:** "Mike completed 3 habits today!"
- **Nudge Request:** "Sarah wants you to complete your habit!"
- **Contract Reminder:** "Your accountability contract is active"

**Key Cues:**
1. **Friend Request:** "New accountability partner request!"
2. **Nudge Received:** "🔔 Alex nudged you to run!"
3. **Contract At Risk:** "Your contract penalty is $5 - complete now!"

---

## 5. TIMING & SCHEDULING LOGIC

### 5.1 Optimal Cue Timing

| Habit Attribute | Best Time | Rationale |
|-----------------|-----------|-----------|
| **Vitality** | Morning | Energy habits start the day |
| **Focus** | Morning | Deep work before distractions |
| **Creativity** | Morning/Evening | Peak creative times |
| **Strength** | Morning/Afternoon | Post-warmup energy |
| **Intellect** | Evening | Learning wind-down |
| **Spirit** | Morning/Evening | Bookend the day |

### 5.2 Archetype Default Times

```dart
int getDefaultHour(UserArchetype archetype) {
  switch (archetype) {
    case UserArchetype.stoic:  return 5;  // 5 AM - Early discipline
    case UserArchetype.athlete: return 6;  // 6 AM - Training time
    case UserArchetype.zealot: return 6;  // 6 AM - Morning devotion
    case UserArchetype.scholar: return 8;  // 8 AM - Mind is fresh
    case UserArchetype.creator: return 9;  // 9 AM - Creative peak
    case UserArchetype.none:    return 7;  // 7 AM - Default
  }
}
```

### 5.3 Cue Scheduling Algorithm

```dart
void scheduleCueForHabit(Habit habit) {
  // 1. Calculate optimal time based on attribute + archetype
  final optimalTime = calculateOptimalTime(habit);

  // 2. Set reminder time
  scheduleReminder(
    habitId: habit.id,
    time: optimalTime,
    frequency: habit.frequency,
  );

  // 3. Schedule streak warning (1 hour after reminder)
  scheduleStreakWarning(
    habitId: habit.id,
    time: optimalTime.add(Duration(hours: 1)),
  );

  // 4. Schedule recovery cue (if missed yesterday)
  if (wasMissedYesterday(habit)) {
    scheduleRecoveryCue(habit);
  }
}
```

### 5.4 Quiet Hours

**Default:** 10 PM - 7 AM (configurable)

**Exception:** Critical cues (streak recovery) may override quiet hours with reduced intensity.

---

## 6. PERSONALIZATION PARAMETERS

### 6.1 Dynamic Content Tokens

```dart
personalizationTokens: {
  'habitTitle': 'Morning Meditation',
  'streak': '7',
  'friendName': 'Alex',
  'milestoneDays': '30',
  'xpGained': '50',
}
```

### 6.2 AI-Driven Adaptation

**Adaptation Factors:**
1. **Response Rate:** Decrease frequency if consistently dismissed
2. **Time to Action:** Schedule earlier if user consistently acts late
3. **Completion Rate:** Increase intensity if streaks are breaking
4. **Engagement Patterns:** Adjust channels based on user preferences

```dart
void adaptCueStrategy(String userId) {
  final metrics = getCueMetrics(userId);

  if (metrics.dismissalRate > 0.7) {
    // User dismisses often - reduce frequency
    decreaseCueFrequency();
  }

  if (metrics.avgTimeToAction > Duration(minutes: 30)) {
    // User acts slowly - schedule earlier
    shiftCueTiming(earlier: Duration(minutes: 15));
  }

  if (metrics.conversionRate < 0.2) {
    // Low engagement - try different channels
    rotateDeliveryChannels();
  }
}
```

---

## 7. ENGAGEMENT METRICS

### 7.1 Tracked Metrics

| Metric | Formula | Target |
|--------|---------|--------|
| **Impressions** | Total cues shown | - |
| **Conversions** | Cues acted upon | > 40% |
| **Dismissals** | Cues dismissed | < 30% |
| **Time to Action** | Avg time from cue to action | < 30s |
| **Conversion Rate** | Conversions / Impressions | > 0.4 |
| **Engagement Score** | Combined metric | > 60 |

### 7.2 Engagement Score Calculation

```dart
double calculateEngagementScore(CueEngagementMetrics metrics) {
  final rateScore = metrics.conversionRate * 70;  // Max 70 points
  final speedScore = calculateSpeedScore(metrics.avgTimeToAction);  // Max 30
  return (rateScore + speedScore).clamp(0.0, 100.0);
}

double calculateSpeedScore(int avgTimeToAction) {
  final seconds = avgTimeToAction / 1000;
  if (seconds < 5) return 30.0;
  if (seconds < 30) return 20.0;
  if (seconds < 120) return 10.0;
  return 5.0;
}
```

### 7.3 A/B Testing Framework

```dart
class CueVariant {
  final String id;
  final String title;
  final String body;
  final CueDeliveryChannel channel;
  final CueIntensity intensity;
}

// Test different cue variants
final variants = [
  CueVariant(id: 'A', title: 'Time to meditate!', ...),
  CueVariant(id: 'B', title: 'Ready for mindfulness?', ...),
  CueVariant(id: 'C', title: '🧘 Your practice awaits', ...),
];
```

---

## 8. ANTI-PATTERNS & EDGE CASES

### 8.1 Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| **Notification Fatigue** | Too many cues → ignored | Rate limit: max 5 cues/hour |
| **Generic Messaging** | Doesn't resonate | Archetype personalization |
| **Wrong Timing** | Cues at inconvenient times | Quiet hours + user preferences |
| **Vague CTAs** | Unclear what to do | Specific action buttons |
| **No Recovery Path** | Missed cue = missed habit | Recovery cues + "Never Miss Twice" |

### 8.2 Edge Cases

1. **User on vacation:** Detect inactivity, pause cues
2. **Habit deleted:** Remove associated cues immediately
3. **Streak broken:** Escalate recovery cues, never give up
4. **New user:** Show tutorial cues, reduce frequency
5. **Power user:** Reduce frequency, show advanced features

---

## 9. TECHNICAL IMPLEMENTATION

### 9.1 File Structure

```
lib/
├── core/
│   ├── domain/
│   │   └── entities/
│   │       └── cue.dart                    # Cue entities
│   ├── services/
│   │   ├── cue_engine.dart                 # Cue orchestration
│   │   ├── notification_service.dart       # Push notifications
│   │   └── notification_templates.dart    # Message templates
│   └── presentation/
│       └── widgets/
│           └── cue_popups.dart             # UI components
└── features/
    ├── habits/
    │   └── presentation/
    │       └── providers/
    │           └── cue_provider.dart       # Habit cues
    ├── social/
    │   └── presentation/
    │       └── providers/
    │           └── social_cue_provider.dart # Social cues
    └── timeline/
        └── presentation/
            └── widgets/
                └── cue_banner_widget.dart   # Timeline cues
```

### 9.2 Key Classes

**CueEngine** (`lib/core/services/cue_engine.dart`)
- Singleton service managing all cue operations
- Methods: `initialize()`, `queueCue()`, `evaluateRules()`

**Cue** (`lib/core/domain/entities/cue.dart`)
- Core cue entity with all properties
- Methods: `personalalizedTitle`, `personalalizedBody`, `relevanceScore`

**CuePopupDialog** (`lib/core/presentation/widgets/cue_popups.dart`)
- Modal dialog for urgent cues
- Handles all cue categories with appropriate actions

### 9.3 Integration Example

```dart
// In a screen's build method
class TimelineScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    final cueEngine = ref.watch(cueEngineProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          MainTimelineContent(),

          // Cue overlay (stream-based)
          StreamBuilder<Cue>(
            stream: cueEngine.cueStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return CuePopupDialog(
                  cue: snapshot.data!,
                  onActionTaken: () => _handleCueAction(snapshot.data!),
                  onDismissed: () => _handleCueDismissed(snapshot.data!),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
```

---

## 10. MEASUREMENT & OPTIMIZATION

### 10.1 Key Performance Indicators

| KPI | Target | Measurement Method |
|-----|--------|-------------------|
| **Cue Conversion Rate** | > 40% | `conversions / impressions` |
| **Time to Action** | < 30s | Average from cue to action |
| **Streak Recovery Rate** | > 60% | Recoveries / streak breaks |
| **Daily Active Users** | Increasing | Cohort analysis |
| **Habit Completion Rate** | > 70% | Daily completion % |

### 10.2 Continuous Improvement Loop

```
1. Collect metrics (real-time analytics)
2. Identify underperforming cues (< 30% conversion)
3. Generate variants (A/B test)
4. Deploy winner
5. Repeat
```

---

## APPENDIX A: QUICK REFERENCE

### Cue Types Quick Reference

| Type | Channel | Intensity | Example |
|------|---------|----------|---------|
| Initiation | Push + Banner | Moderate | "Time to read!" |
| Recovery | Modal | Urgent | "Save your streak!" |
| Celebration | Modal | Critical | "🏆 30 days!" |
| Social | Toast | Gentle | "Alex finished!" |
| Discovery | Banner | Gentle | "Try journaling" |

### Archetype Colors Quick Reference

| Archetype | Primary Color | Hex |
|-----------|--------------|-----|
| Athlete | Sienna | #A04000 |
| Scholar | Purple | #6B5B95 |
| Creator | Pink | #B76E79 |
| Stoic | Blue | #8B9DC3 |
| Zealot | Terracotta | #E07A5F |
| None | Teal | #2BEE79 |

---

**END OF DOCUMENT**

*This strategy document is a living resource. Update as user data and research inform new approaches.*
