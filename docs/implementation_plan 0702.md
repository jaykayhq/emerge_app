# Emerge — Habitual Engagement Redesign
## Unified Implementation Plan v1.1

**Author perspective:** 40 years in product engineering and UX design — from terminal interfaces to the first touchscreen apps to AI-native products. I've watched every "revolutionary" app pattern come and go. What follows is what actually works.

**Date:** 2026-07-02
**Merges:** `2026-07-02-habitual-engagement-redesign.md` (other AI) + ULTRATHINK analysis (Antigravity)
**Updated:** User clarification — Narrator scope expanded (see Part 0.5)
**Status:** Ready for engineering sprint planning

---

## PART 0 — CHAIN OF THOUGHT: WHAT WE'RE ACTUALLY SOLVING

Before touching a single file, let's be honest about the problem.

**The real issue isn't features. It's activation energy.**

I've built products since before the internet. The pattern is always the same: teams build elaborate feature systems trying to *force* engagement. Then a 22-year-old builds a one-screen app that nobody can put down. The difference is never capability — it's *friction*.

Emerge's completion loop currently has **8–12 steps and 8–12 seconds** of friction. That is 8× too many. Every second of friction costs you 20% of completions. Do the math.

**Both specs agree on the right diagnosis.** The specs differ on execution. Here is my synthesis after stripping out everything that sounds good in a meeting but creates technical debt in production:

### What Each Spec Got Right

**Other AI spec** — Technically precise, pragmatic:
- ✅ Timeline as the home tab (action before reward)
- ✅ One-tap completion without modal confirmation
- ✅ Notification inline actions (Complete / Snooze)
- ✅ Offline-first widget completion via Drift
- ✅ WorldEventEngine as a pure function (testable)
- ✅ CompletionSource enum (audit trail for AI learning)
- ✅ Particle burst animation on completion
- ✅ No FAB in center — move to Timeline bottom-right

**ULTRATHINK spec** — Behavioral depth, strategic clarity:
- ✅ Pulse Feed as passive content scroll (Tab 3)
- ✅ Identity-language in all notifications
- ✅ Momentum Meter (amber/red, not binary reset)
- ✅ Context-aware Timeline (morning/afternoon/evening modes)
- ✅ Identity vote visualization
- ✅ The Narrator concept (my "AI Morning Brief" + their "AI coach companion")
- ✅ Streak Resurrection flow (Compassion → Agency → Redemption)

### What Gets CUT (and why)

| Cut | Source | Reason |
|-----|--------|--------|
| Live Activity (iOS 17+) | Other AI | 18% of iOS userbase supports it. Engineering cost disproportionate. Add in v3. |
| NPC/Traveler movement (Flame animated sprites) | Other AI | Flame animation on world map when it barely renders on mid-range Android. Premature. |
| `FeatureCoachMark` widget (all 14 usages) | Codebase | Replaced by Narrator. Static bullet-point overlays contradict the narrative identity. |
| `_showCompanionGuide()` Node Guide AlertDialog | Codebase | Replaced by Narrator. "NODE GUIDE" as an AlertDialog is jarring. The Narrator tells the story. |
| `AiCoachCard` widget | Codebase | Replaced by `NarratorSummaryCard` (always-visible inline) + Narrator sheet on tap. |
| `ReflectionCard` widget | Codebase | Replaced by Narrator's `eveningReflection` trigger. Note-taking moves inside the Narrator sheet. |
| `companionEngineProvider` / `companionRepositoryProvider` triggers | Codebase | The companion system is superseded entirely by `NarratorTriggerEngine`. |

---

## PART 0.5 — USER CLARIFICATION: WHAT THE NARRATOR ACTUALLY REPLACES

> *"I also want the narrator to replace the node guide in all the screens. That was what I meant when I said widget. And reflections card under the AI coach card in timeline is what I meant by note taking."*

After reading the live codebase, here is the precise mapping:

### The Four Components Being Replaced

#### 1. `FeatureCoachMark` — 14 screens
File: `lib/core/presentation/widgets/feature_coach_mark.dart`

Currently used in:
```
timeline_screen.dart         → "Your Timeline Command Center" (2 tips)
ai_reflections_screen.dart   → AI features explanation
leveling_screen.dart         → XP progression explanation
advanced_create_habit_dialog → Habit creation tips
future_self_studio_screen    → Identity profile tips
all_tribes_screen            → Tribes explanation
challenge_detail_screen      → Challenge mechanics
challenges_screen            → Quests overview
friends_screen               → Partners explanation
leaderboard_screen           → Leaderboard explanation
social_activity_screen       → Activity feed explanation
social_contacts_screen       → Contacts discovery explanation
tribe_lobby_screen           → Tribe lobby explanation
```

**What the Narrator does instead:** When `NarratorTriggerEngine` detects a `screenFirstVisit` trigger (route not seen before), the Narrator opens with a screen-specific template. It speaks in story form — 2–3 sentences, identity-framed — then asks one orienting question. This replaces numbered bullet lists with a living voice.

#### 2. Node Guide AlertDialog — `level_immersive_screen.dart`
Method: `_showCompanionGuide()` (line 85)
Currently: A glassmorphic AlertDialog titled "NODE GUIDE" with 3 static bullet rows.

**What the Narrator does instead:** `NarratorTrigger.nodeFirstVisit` opens the Narrator sheet with a template specific to the node type, current user level, and archetype. The node's lore and mechanics are explained *as part of the user's story*, not as a help document.

#### 3. `AiCoachCard` — `timeline_screen.dart` (lines 404–466)
Currently: A GlassmorphismCard with AI insight text (skeleton loader), suggested habit pill, "Reflect" button (→ `/profile/reflections`), "Add Habit" button.
Problem: Premium-locked, requires async load with skeleton shimmer, insight is generic.

**What replaces it:** `NarratorSummaryCard` — a compact, always-instant inline card that:
- Shows the most recent Narrator insight from the local `NarratorNote` cache (no loading state ever)
- Displays a pulsing `◐` indicator
- Tap opens the Narrator sheet with `NarratorTrigger.dailyInsight`
- Free users get this card fully (Narrator depth is the premium gate, not the card itself)

#### 4. `ReflectionCard` — `timeline_screen.dart` (lines 471–475)
Currently: Mood slider (😔 → 🔥) + "Add note" text field + "Log" button → saves `Reflection` to `insightsRepositoryProvider`.
Problem: Cold, clinical. A slider doesn't capture identity. Nobody reads their old mood sliders.

**What the Narrator does instead:** The Narrator becomes the note-taker. When triggered by `eveningReflection`, the Narrator asks ONE focused question. The user's response (button tap OR short typed note inside the Narrator sheet) is saved as a `NarratorNote` with type `reflection` — AND still writes a `Reflection` to `insightsRepositoryProvider` for backward compatibility with the AI reflections screen.

**The one exception to "no text input in Narrator":** The `eveningReflection` trigger includes a single optional text field *inside* the Narrator sheet — a minimal, single-line "What happened?" input. This is the only Narrator appearance with a text field.

### The New Component: `NarratorSummaryCard`

This inline card lives in Timeline where `AiCoachCard` was. It is always present, always fast, always identity-language:

```
┌──────────────────────────────────────────────────────┐
│  ◐  EMERGE                                           │
│                                                      │
│  "You write best before 9 AM. Yesterday you         │
│   started at 9:47. One shift changes everything."   │
│                                                      │
│  [Hear more]              [Add a habit]              │
└──────────────────────────────────────────────────────┘
```

- Text = last `NarratorNote` with type `aiInsight` (local, no API call)
- `◐` pulses in archetype color
- "Hear more" → opens Narrator sheet with `dailyInsight` trigger
- "Add a habit" → same as old AiCoachCard's "Add Habit" (→ `/timeline/create-habit`)
- If no NarratorNote exists yet → shows onboarding variant: *"I'm watching how you work. Check back after your first habit."*
| 4×4 Day Overview Widget | Other AI | Nobody uses 4×4 widgets. They exist in demos. 2×2 and 4×2 only. |
| Tribe Convergence WorldEvent | Other AI | Social graph not mature enough. Adds data complexity for zero user-visible value yet. |
| WorldSliceWidget (Flame render in widget) | Other AI | Platform-level rendering limitation. Static image snapshot of world state instead. |
| Global Live Ticker ("10,000 meditating now") | ULTRATHINK | Real-time Firestore listener in a feed card is a billing disaster at scale. Use daily batch counter instead. |
| AR Mirror | Blueprint | Far future. Mentioned for roadmap only. |
| Zero-knowledge proofs for GPS | Blueprint | Academic. Firebase App Check + privacy policy is sufficient. |
| Separate Widget feature module | Other AI | Overkill abstraction. Completion logic belongs in existing `habits` feature, exposed through a service. |

---

## PART 1 — THE NARRATOR: THE CENTRAL DESIGN DECISION

### What the User Asked For

> "I wanted to replace widget and companion with a narrator that explains everything to the user as well as act as the AI engine and also note taker but it should be filled with templates for possible questions. The narrator should look like it is generating a response like it's telling a story but should feel like a companion triggered at certain critical times."

### What This Actually Means (My Interpretation After 40 Years)

The user isn't asking for a chatbot. They're describing something more like a **Greek chorus** — a voice that surfaces at key story moments, speaks with personality, feels alive, but never interrupts unnecessarily.

This is one entity that replaces three fragmented things currently in Emerge:
1. The AI reflections buried at `/profile/reflections` (nobody navigates there)
2. The planned "AI companion" (a chat UI that would have felt like a helpdesk)
3. Generic system notifications ("Don't forget to log your habit!")

The Narrator is **not a chat interface**. It is a **story mode** — a character that appears, speaks in flowing text (typewriter render), asks a focused question, and disappears. It watches everything, notes everything, and surfaces insights at precisely the right moments.

### The Narrator — Design Specification

#### Visual Identity

```
┌─────────────────────────────────────────────────┐
│                                                 │
│   ◐  EMERGE                                     │
│      ─────────────────────────────────────      │
│      You haven't written in three days.         │
│      The Library district is quiet.             │
│                                                 │
│      I noticed something though —               │
│      every time you skipped writing,            │
│      you'd opened the app after 10 PM.▌         │
│                                                 │
│      Your best writing happens before 9 AM.     │
│      Want to move your session to morning?      │
│                                                 │
│  ╔══════════════╗   ╔══════════════════════╗   │
│  ║  Not yet     ║   ║  Move it to morning  ║   │
│  ╚══════════════╝   ╚══════════════════════╝   │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Visual rules:**
- The Narrator never takes over the full screen — it occupies a **modal bottom sheet** (70% screen height max)
- An animated **◐ symbol** pulses while text is generating (archetype-colored)
- Text appears character-by-character with **natural rhythm** — not uniform speed. Pauses at commas and periods. Feels like someone thinking while speaking.
- Two action buttons maximum per appearance. Never a text input field.
- A subtle **dismiss swipe** always available — the Narrator never traps the user.
- The background behind the sheet blurs and dims slightly (glassmorphism) — creating a "pulled aside for a private conversation" feeling.

#### The Note-Taking Engine (Background)

The Narrator silently logs structured observations throughout the day. These are not user-visible in raw form — they feed the AI prompts.

```dart
// lib/features/narrator/domain/models/narrator_note.dart
enum NarratorNoteType {
  completionTime,       // What time habits are completed
  missPattern,          // Which days/times habits are skipped
  streakRecovery,       // How user responds to recovery prompts
  questionResponse,     // Which action button user tapped
  sessionLength,        // Time spent in app per session
  openTrigger,          // What caused app open (widget, notification, direct)
}

@freezed
class NarratorNote with _$NarratorNote {
  const factory NarratorNote({
    required String id,
    required NarratorNoteType type,
    required Map<String, dynamic> data,
    required DateTime recordedAt,
    String? habitId,
  }) = _NarratorNote;
}
```

Stored locally in **Drift** first (privacy-first), synced to Firestore only on premium accounts with explicit consent.

#### The 12 Narrator Trigger Moments

The Narrator appears ONLY at these moments. Not at random. Not on a timer. At inflection points in the user's story.

| # | Trigger | Tone | Replaces | Core Job |
|---|---------|------|----------|----------|
| 1 | **Onboarding — after archetype selection** | Warm, welcoming | — | Set identity framing, ask "The Why" |
| 2 | **First morning open** (day 1–3) | Energizing, brief | — | Orient user to world, explain what changed |
| 3 | **Streak break — first miss** | Compassionate | — | Recovery framing, lower friction |
| 4 | **"On Fire" state** (7+ day momentum) | Celebratory | — | Acknowledge, challenge to next level |
| 5 | **Level Up** | Epic, landmark | — | Narrative milestone, world evolution |
| 6 | **Weekly Recap** (Sunday evening) | Reflective, proud | — | Identity vote summary, next week intention |
| 7 | **Long absence** (5+ days no open) | Gentle, curious | — | Reactivation without guilt |
| 8 | **New habit creation** | Collaborative | — | Anchor to identity, set implementation intention |
| 9 | **Screen first visit** (any route) | Curious, world-aware | `FeatureCoachMark` (14 screens) | Explain screen in story form, ask one orienting question |
| 10 | **Node first visit** (level_immersive) | Lore-rich, epic | Node Guide AlertDialog | Tell the node's story, explain mechanics as world narrative |
| 11 | **Evening reflection** (habits done / 6PM+) | Quiet, observant | `ReflectionCard` | Ask one focused question, capture note |
| 12 | **Daily insight** (inline card tap) | Analytical, specific | `AiCoachCard` insight display | Surface pattern from NarratorNote history |

**Priority when multiple triggers apply:** longAbsence > levelUp > streakBreak > onFire > weeklyRecap > morningBrief > screenFirstVisit / nodeFirstVisit > eveningReflection > dailyInsight > onboarding. Narrator cannot fire twice within 4 hours (except screenFirstVisit/nodeFirstVisit which are exempt — they fire once per screen lifetime).

#### Narrator Templates (Pre-filled, AI-personalized at render time)

Each template has a **shell** (structure, never changes) and **slots** (filled by Groq at trigger time using user's actual data). This avoids cold API latency for emotional moments — the shell renders instantly, slots stream in.

**Template 1 — Onboarding (Post-Archetype)**
```
Shell:
"I've been watching ${archetypeName}s for a long time.
They all share one thing — [SLOT: archetype_trait].

You chose [${archetype}] because ${reason_placeholder}.
Before we build your world, tell me one thing:

Why does this matter to you right now?"

Action buttons:
  [For myself] / [For someone I love] / [To prove something]

Note recorded: motivation_frame = {button_tapped}
```

**Template 2 — Morning Brief (Days 1–7)**
```
Shell:
"Good ${timeOfDay}, ${archetypeName}.

[SLOT: world_overnight_update]

Your stack for this ${dayPart}:
${habitStack}

One thing: ${AI_single_focus}"

Action buttons:
  [Let's go] / [Show me my world first]
```

**Template 3 — Streak Break (First Miss)**
```
Shell:
"You missed ${habitName} ${missCount == 1 ? 'yesterday' : 'recently'}.

[SLOT: compassionate_reframe — 1 sentence, identity-language]

Here's what I know about you:
You've completed this ${totalCompletions} times.
That doesn't disappear.

One question: What got in the way?"

Action buttons:
  [Life happened] / [It felt too hard] / [I forgot]

Note recorded: miss_reason = {button_tapped, habitId}
```

**Template 4 — On Fire (7+ days)**
```
Shell:
"${streak} days.

[SLOT: world_visual_achievement]

You're in the top ${percentile}% of ${archetype}s this week.

[SLOT: challenge_suggestion — raise the bar by one notch]"

Action buttons:
  [Accept the challenge] / [Keep my current pace]
```

**Template 5 — Level Up**
```
Shell:
"[SLOT: level_narrative — 2-3 sentences about what this level means in the world]

Your ${worldType} just [SLOT: world_change_description].

${identityVotes[dominantIdentity]} votes for ${dominantIdentity}.
You're not just acting like a ${archetype}.
You're becoming one."

Action buttons:
  [See my world] / [What unlocks next]
```

**Template 6 — Weekly Recap (Sunday)**
```
Shell:
"This was week ${weekNumber} of your story.

[SLOT: week_narrative — 3 sentences max, identity-language, data-backed]

${identityVotes.entries.map format}

The ${dominantIdentity} in you showed up ${dominantCount} times.
[SLOT: one_insight_from_patterns]

Next week, one intention:"

Action buttons:
  [I'll focus on ${topSuggestedHabit}] / [Show me the full recap]
```

**Template 7 — Long Absence**
```
Shell:
"${firstName}.

Your ${worldType} has been quiet for ${daysSinceOpen} days.

[SLOT: world_state_description — what decayed, not shame-based]

I'm not here to make you feel bad.
I'm here to say: you built something real.
One habit is all it takes to clear the ${decayEffect}."

Action buttons:
  [Start with ${easiestHabit}] / [I need to rebuild from scratch]
```

**Template 8 — New Habit Creation**
```
Shell:
"A ${archetype} who wants to ${habitGoal}.

[SLOT: why_this_habit_matters — 1 sentence, identity-framed]

When will this happen in your day?
After ${anchorHabit}, ideally.

[SLOT: suggested_anchor — from existing habit stack]"

Action buttons:
  [After ${suggestedAnchor}] / [Let me pick my own time]
```

**Template 9 — Screen First Visit (replaces FeatureCoachMark)**
```
// context: screenRoute, screenPurpose, archetypeName
// Each screen has its own shell, AI fills the [SLOT]

// Example: /timeline first visit
Shell:
"This is where your day lives, ${archetypeName}.

Every habit you see here is a vote.
[SLOT: one_relevant_insight_about_user_habits — 1 sentence]

Tap the circle on any card to complete it.
I'll be watching."

Action buttons:
  [Got it, let's go] / [Tell me more about habits]

// Example: /social first visit
Shell:
"Your tribe is out here.

[SLOT: tribe_context — current tribe name + one fact]

People who track together outperform solo trackers by 65%.
You're not alone in this."

Action buttons:
  [Explore the tribe] / [Find my people]

// Stored: screenRoute visited once, never re-triggers for same route
Note recorded: screen_visited = {route, timestamp}
```

**Template 10 — Node First Visit (replaces Node Guide AlertDialog)**
```
// context: nodeId, nodeTitle, nodePrimaryAttribute, userLevel, archetypeName

Shell:
"You've reached the ${nodeTitle}.

[SLOT: node_lore — 1-2 sentences, world-building flavor]

Directives here build ${nodePrimaryAttribute}.
Every one you complete shifts the ${worldRegionName}.

Complete the missions. Conquer the node.
What happens after that is worth seeing."

Action buttons:
  [Begin the node] / [What does ${nodePrimaryAttribute} unlock]

Note recorded: node_first_visited = {nodeId, userLevel}
```

**Template 11 — Evening Reflection (replaces ReflectionCard)**
```
// Triggers: ≥1 habit completed today AND time ≥ 18:00
// OR: all habits completed (any time)

Shell:
"${completedCount} of ${totalHabits} today.

[SLOT: day_narrative — 1 sentence framing what kind of day it was]

One question before you close:
[SLOT: focused_question — drawn from NarratorNote patterns, max 12 words]

Or write it in your own words:▁"

[Optional single-line text field: placeholder = "What actually happened today?"]

Action buttons:
  [${AI_suggested_response_a}] / [${AI_suggested_response_b}]

Note recorded: reflection = {response_or_text, moodInferred, timestamp}
Backward compat: also saves Reflection to insightsRepositoryProvider
```

**Template 12 — Daily Insight (replaces AiCoachCard inline, shown in NarratorSheet)**
```
// Triggers: user taps "Hear more" on NarratorSummaryCard
// Context: last 7 days of NarratorNotes

Shell:
"Here's what I've been noticing.

[SLOT: pattern_observation — 2-3 sentences, data-backed, identity-language]

[SLOT: one_action_question — max 12 words, makes user think about next step]"

Action buttons:
  [${AI_action_a}] / [${AI_action_b}]

Note recorded: insight_acknowledged = {timestamp, action_tapped}
```

---

## PART 2 — THE ARCHITECTURE DECISIONS

### 2.1 Navigation Restructure

The other AI spec is correct here. No debate needed after 40 years.

**The principle**: The first tab is where users spend 80% of their time. Put the *action* there, not the *reward*.

```
NEW TAB ORDER:
  Tab 0 → /timeline    (HOME — action zone)
  Tab 1 → /            (World Map — reward/pride zone)
  Tab 2 → /social      (Pulse Feed — scroll zone)
  Tab 3 → /profile     (Identity — customization zone)
```

**Why this order specifically:**
- Tab 0 (Timeline): Users open app to DO something. Timeline is the doing screen.
- Tab 1 (World): The world is the *reward* for doing. It should feel like a treat, not the home.
- Tab 2 (Social/Pulse): Passive consumption. Dead-time slot. Third tab is right.
- Tab 3 (Profile): Least visited. Customization, not daily action.

### 2.2 Widget Strategy (Simplified)

I'm cutting the 4×4 widget and the Flame-rendered WorldSliceWidget. Here's what ships:

| Widget | Size | Content | Action |
|--------|------|---------|--------|
| HabitStackWidget | 4×2 | Today's top 3 habits + completion state | Tap habit → deep link to quick-log sheet |
| WorldHealthWidget | 2×2 | World health % + archetype color pulse + streak | Tap → opens Tab 1 (World Map) |

The world widget shows a **static snapshot** of the world rendered as a PNG (generated server-side or on-device when world changes) — not a live Flame render. This is the pragmatic choice.

### 2.3 One-Tap Completion (No Modal)

This is the most important UX change in the entire plan.

**Current flow**: Tap card → modal asks "Are you sure?" → Tap confirm → animation plays

**New flow**: Tap dedicated completion circle → 200ms particle burst + haptic → card dims → done

The "are you sure?" modal is deleted. In 40 years, I have never seen a confirmation modal that improved user behavior. Users who tap accidentally will simply re-open the habit. Trust users.

### 2.4 The Pulse Feed (Tab 2 — replaces TribeLobbyScreen header)

This is the key strategic change from my ULTRATHINK analysis. The Tribe tab needs a scrollable, passive, identity-reinforcing feed.

**Feed card types (in weighted rotation):**

```
1. Live Momentum Card (real-time via batch counter, not listener)
   "8,400 people completed a habit in the last hour."
   [That includes me] / [Log one now]

2. Partner Milestone Card (from partner_activity subcollection — already built!)
   "@kelechi hit 30 days of writing. 🔥"
   [Cheer them] / [Challenge: who hits 40 first]

3. AI Insight Card (personalized, from NarratorNote analysis)
   "You complete habits 3× more often on weekdays.
    Consider a lighter weekend version."
   [Adjust habits] [Got it]

4. Creator Blueprint Card (existing feature, surfaced in feed)
   "The 5AM Creator Stack — adopted by 1.2k people"
   [Preview] [Adopt]

5. Tribe Activity Card (existing activity feed, reformatted)
   "Your Athlete tribe had 94% completion yesterday."
   [See leaderboard]
```

**No video. No algorithm chasing.** The feed is identity-reinforcing by design, not engagement-maximizing. Every card should make the user feel proud to be in their tribe or motivated to do one thing.

---

## PART 3 — IMPLEMENTATION PLAN

### Engineering Philosophy (40 Years Speaking)

1. **Ship the friction fix first.** Everything else is polish.
2. **Pure functions for all logic.** If it can't be unit-tested without Firebase, it's in the wrong place.
3. **Offline-first.** Habits complete in the gym with no signal. This is non-negotiable.
4. **No new dependencies without a fight.** Every package is a liability.

---

### PHASE 1 — Foundation (Week 1–2)
*Goal: Cut friction from 12s to <3s. Nothing else matters until this is done.*

#### P1.1 — Navigation Restructure

**File: `lib/core/router/router.dart`**
```dart
// Change StatefulShellRoute branch order:
// Branch 0: /timeline (was branch 1)
// Branch 1: /         (WorldMap, was branch 0)
// Branch 2: /social   (unchanged)
// Branch 3: /profile  (unchanged)
```

**File: `lib/core/presentation/widgets/scaffold_with_nav_bar.dart`**
- Remove center FAB position
- Update `NavBarItem` order to match new branch order
- Tab 0 icon: check-circle (action indicator)
- Tab 1 icon: map/globe (visual/world)

#### P1.2 — One-Tap Completion

**New file: `lib/core/presentation/widgets/completion_particles.dart`**

```dart
// CustomPainter-based particle burst
// 30 particles, archetype-colored, gravity + fade
// 200ms total, GPU-friendly
// Accepts: Offset tapPosition, Color archetypeColor

class CompletionParticles extends StatefulWidget {
  final Color color;
  final VoidCallback onComplete;
  // ...
}
```

**Modified: `lib/features/habits/presentation/widgets/habit_card.dart`** (or equivalent)
- Add `CompletionZone` widget (48×48 circle, always visible)
- Remove confirmation modal entirely
- On tap: fire particle animation, call `markComplete`, card dims
- No navigation on completion

#### P1.3 — Habit Completion Service

**New file: `lib/features/habits/data/services/habit_completion_service.dart`**

```dart
// Single responsibility: mark a habit complete
// Works offline (Drift first, Firestore sync queued)
// Emits CompletionResult with XP delta, streak state, world delta

class HabitCompletionService {
  Future<CompletionResult> markComplete(
    String habitId, {
    required CompletionSource source,
    DateTime? completedAt,
  });
}
```

This service is the single truth for all completion paths:
- Timeline tap
- Widget tap
- Notification action
- Voice (future)
- Health sync (future — already spec'd separately)

**New file: `lib/features/habits/domain/models/completion_result.dart`**
```dart
@freezed
class CompletionResult with _$CompletionResult {
  const factory CompletionResult({
    required String habitId,
    required int xpEarned,
    required HabitStreakState newStreakState,  // existing enum
    required int newMomentumScore,
    required int newWorldHealthDelta,
    String? narratorTrigger,  // null = no narrator, else trigger type
  }) = _CompletionResult;
}
```

#### P1.4 — Momentum Meter (Replaces Binary Streak)

**Modified: `lib/features/habits/domain/models/habit.dart`**

Add the fields identified in the April ULTRATHINK audit:
```dart
// Add to Habit entity:
final int momentumScore;           // 0-100
final HabitStreakState streakState; // onFire/strong/building/atRisk/recovery/reset
final int consecutiveMisses;        // 0, 1, 2+
```

**Modified: `lib/features/habits/data/repositories/habit_repository.dart`**
- Update Firestore mapping
- Migration: existing `currentStreak > 0` → `momentumScore = min(currentStreak * 10, 100)`

---

### PHASE 2 — The Narrator (Week 3–4)
*Goal: Replace all fragmented AI touchpoints with one coherent voice.*

#### P2.1 — Narrator Feature Module

```
lib/features/narrator/
├── domain/
│   ├── models/
│   │   ├── narrator_trigger.dart       ← enum of 8 triggers
│   │   ├── narrator_note.dart          ← NarratorNote (observation log)
│   │   └── narrator_appearance.dart    ← template + rendered content
│   └── services/
│       ├── narrator_trigger_engine.dart ← pure function: should narrator appear?
│       └── narrator_note_service.dart   ← records observations
├── data/
│   ├── datasources/
│   │   └── narrator_local_datasource.dart  ← Drift tables for notes
│   └── repositories/
│       └── narrator_repository.dart        ← Interface
└── presentation/
    ├── providers/
    │   ├── narrator_providers.dart          ← Riverpod providers
    │   └── narrator_providers.g.dart
    └── widgets/
        ├── narrator_sheet.dart              ← The bottom sheet UI
        ├── narrator_typewriter.dart         ← Streaming typewriter text widget
        └── narrator_pulse_indicator.dart    ← The ◐ animated symbol
```

#### P2.2 — NarratorTriggerEngine (Pure Function)

```dart
// lib/features/narrator/domain/services/narrator_trigger_engine.dart

enum NarratorTrigger {
  onboardingPostArchetype,
  morningBriefEarlyDays,
  streakBreakFirstMiss,
  onFireState,
  levelUp,
  weeklyRecap,
  longAbsence,
  newHabitCreation,
}

class NarratorTriggerEngine {
  /// Pure function — no side effects, fully testable
  static NarratorTrigger? shouldTrigger({
    required UserStats stats,
    required AppOpenContext context,   // why app opened, time of day
    required DateTime now,
    required List<NarratorNote> recentNotes,
  }) {
    // Priority order: highest emotional moment wins
    // 1. Long absence (5+ days) — always wins
    // 2. Level up (just triggered)
    // 3. Streak break (first miss detected)
    // 4. On Fire state (7+ day, not recently triggered)
    // 5. Weekly recap (Sunday 5PM+)
    // 6. Morning brief (days 1-7 only, morning open)
    // 7. Onboarding (one-time)
    // 8. New habit creation (on save)
    // Returns null if none apply or narrator appeared < 4 hours ago
  }
}
```

#### P2.3 — NarratorSheet Widget

```dart
// lib/features/narrator/presentation/widgets/narrator_sheet.dart

class NarratorSheet extends StatefulWidget {
  final NarratorTrigger trigger;
  final UserStats stats;
  // ...
}

// Key UX behaviors:
// 1. Opens as DraggableScrollableSheet (max 70% height)
// 2. Background dims + blurs (BackdropFilter)
// 3. NarratorTypewriter streams text
// 4. Typing pauses at sentence endings (150ms pause at '.', '?', '!')
// 5. Action buttons fade in only AFTER text completes
// 6. Swipe down to dismiss (always available)
// 7. Auto-dismiss after 30s if no interaction
```

#### P2.4 — NarratorTypewriter Widget

```dart
// lib/features/narrator/presentation/widgets/narrator_typewriter.dart

class NarratorTypewriter extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback? onComplete;
}

// Implementation:
// - Timer-driven character reveal (not animation controller)
// - Base speed: 28ms/character
// - Pause at '.': 250ms, at ',': 100ms, at '?': 300ms, at '!': 200ms
// - Slightly randomized per-character timing (±8ms) for organic feel
// - [SLOT] text is held as placeholder, replaced when Groq response streams in
// - Shell text renders immediately. Slots stream in from Groq Cloud Function.
```

#### P2.5 — Groq Integration (Slot Filling)

**Modified: `functions/src/narrator.ts`** (new Cloud Function)

```typescript
// Cloud Function: fillNarratorSlots
// Input: { trigger, userId, templateShell, slotKeys }
// Output: { slots: Map<string, string> }
// Calls Groq with structured prompt: "Fill slot [X] with ≤15 words, 
//   identity-language, no fluff. Context: [UserStats JSON]"

// Each slot is ≤15 words. Fast to generate. Low token cost.
// Streamed back to client via Server-Sent Events or FCM message.
```

**On client:**
```dart
// Template shell renders immediately (from local template)
// Groq slots stream in over 1–3 seconds
// User sees text appearing — exactly like the "story being told" feel requested
// If Groq fails: fallback slot text is baked into each template
```

---

### PHASE 3 — Ambient Layer (Week 5–6)
*Goal: Emerge lives on the home screen. Not just inside the app.*

#### P3.1 — Widgets

**New file: `lib/widgets/habit_stack_widget.dart`** (home screen, 4×2)

Platform implementation:
- Android: `home_widget` package + `AppWidgetProvider`
- iOS: `home_widget` package + WidgetKit `TimelineProvider`

```dart
// Widget renders:
// - Today's date + archetype greeting
// - Top 3 habits (today's uncompleted, prioritized by schedule)
// - Per-habit: name + completion circle
// - Tapping habit → deep link: emergeapp://quick-log/{habitId}
// - Tapping world area → deep link: emergeapp://world

// Completion from widget:
// → Calls HabitCompletionService via platform channel
// → Offline-first: Drift write, sync queue
// → Widget re-renders via home_widget.HomeWidget.updateWidget()
```

**New file: `lib/widgets/world_health_widget.dart`** (2×2)

```dart
// Shows:
// - World health % (bold, archetype color)
// - Small static PNG snapshot of world (generated on world state change)
// - Streak / momentum bar
// - Tap → opens app to World Map tab

// Static PNG generation:
// On every world state change → render Flame scene to image → cache to app group
// NOT live Flame rendering in widget context
```

#### P3.2 — Notification Action Buttons

**Modified: `lib/core/services/notification_service.dart`**

```dart
// For each scheduled habit notification, register:
// Action 1: "Complete" → calls HabitCompletionService via background isolate
// Action 2: "Snooze 1h" → calls NotificationSnoozeService
// Action 3: "Open App" → navigates to Timeline (existing behavior)

// Android: AndroidNotificationAction
// iOS: UNNotificationAction (registered in AppDelegate)

// Complete action processing (background isolate):
// → Initialize Drift connection
// → HabitCompletionService.markComplete(habitId, source: CompletionSource.notification)
// → Sync queue enqueue
// → Update widget
// → Show brief success local notification ("✓ Meditation complete. Streak: 8 days.")
```

#### P3.3 — Pulse Feed (Tab 2 redesign)

**Modified: `lib/features/social/presentation/screens/tribe_lobby_screen.dart`**

Replace the current complex lobby with a vertical card feed:

```dart
// PulseFeedScreen
// Card types rendered by PulseFeedCardFactory:

enum PulseFeedCardType {
  liveMomentum,    // Batch counter (Firestore scheduled function, not live listener)
  partnerMilestone, // From partner_activity subcollection (already exists!)
  aiInsight,        // From Narrator note analysis
  creatorBlueprint, // Existing blueprint feature, reformatted
  tribeActivity,    // Existing activity feed, reformatted as card
  questCard,        // Active quest progress
}

// Cards are pre-fetched on tab enter, cached for 15 minutes
// No real-time listeners in the feed (prevents billing/performance issues)
// Pull-to-refresh clears cache
```

---

### PHASE 4 — World Event Engine (Week 7)
*Goal: The world surprises users. Variable reward locks in long-term retention.*

#### P4.1 — WorldEventEngine (Pure Function)

Using the other AI spec's architecture exactly — it's correct:

```dart
// lib/features/gamification/domain/services/world_event_engine.dart

class WorldEventEngine {
  /// Pure function — testable without any framework
  static List<WorldEvent> evaluateAndFire({
    required UserStats stats,
    required DateTime now,
    required List<WorldEvent> recentEvents,
  }) {
    final events = <WorldEvent>[];

    // Rule 1: Traveler Visit — 5-day consistency streak, not visited recently
    if (stats.consecutiveActiveDays >= 5 &&
        !_recentlyFired(recentEvents, WorldEventType.travelerVisit)) {
      events.add(WorldEvent.travelerVisit(stats));
    }

    // Rule 2: Weather Shift — daily, seeded by date (deterministic!)
    final weatherSeed = now.day * now.month;
    if (_shouldShiftWeather(weatherSeed, recentEvents)) {
      events.add(WorldEvent.weatherShift(weatherSeed));
    }

    // Rule 3: Discovery Burst — momentum score 90+
    if (stats.currentMomentumScore >= 90 &&
        !_recentlyFired(recentEvents, WorldEventType.discoveryBurst)) {
      events.add(WorldEvent.discoveryBurst(stats));
    }

    // Rule 4: Biome Transition — level milestone
    if (_isLevelMilestone(stats.level) &&
        !_recentlyFired(recentEvents, WorldEventType.biomeTransition)) {
      events.add(WorldEvent.biomeTransition(stats.level));
    }

    return events;
  }
}
```

Note: Tribe Convergence event is **cut** (social graph not ready). Can be added in Phase 5.

---

### PHASE 5 — Polish & Onboarding (Week 8)
*Goal: First-time experience matches the promise of the redesign.*

#### P5.1 — Onboarding Narrator Integration

The Narrator's first appearance is the most important moment in the product. It sets the tone for everything.

**Modified: `lib/features/onboarding/presentation/screens/identity_studio_screen.dart`**

After archetype selection (existing flow), instead of proceeding to identity attributes screen:
1. World generation animation plays (existing WorldRevealScreen logic)
2. World fades to 30% opacity
3. NarratorSheet slides up with `NarratorTrigger.onboardingPostArchetype`
4. User taps action button → response recorded as NarratorNote
5. Identity attributes screen appears

This creates the emotional anchor: **the world exists before the user has done anything**. Now they have something to protect from the start.

#### P5.2 — Streak Resurrection Flow

**Modified: `lib/features/habits/presentation/screens/streak_recovery_screen.dart`**

Current screen: shows missed habit, offers recovery.

Redesigned: The Narrator appears automatically on first open after a miss:
1. Timeline loads → `NarratorTriggerEngine.shouldTrigger()` returns `streakBreakFirstMiss`
2. NarratorSheet opens with compassion template
3. User taps reason button → NarratorNote recorded
4. Sheet dismisses → Timeline is visible with decay visual
5. User sees the ONE recovery habit prominently surfaced

The existing `StreakRecoveryScreen` becomes a sub-route only if user explicitly wants full recovery context. The Narrator handles the emotional moment.

---

## PART 4 — DATA MODEL SUMMARY

### New/Modified Models

```
✅ Habit (modified)
   + momentumScore: int
   + streakState: HabitStreakState
   + consecutiveMisses: int

✅ CompletionResult (new)
   - habitId, xpEarned, newStreakState, newMomentumScore, 
     newWorldHealthDelta, narratorTrigger?

✅ NarratorNote (new — Drift + Firestore)
   - id, type, data, recordedAt, habitId?

✅ NarratorTrigger (enum — 12 values)
   - onboardingPostArchetype
   - morningBriefEarlyDays
   - streakBreakFirstMiss
   - onFireState
   - levelUp
   - weeklyRecap
   - longAbsence
   - newHabitCreation
   - screenFirstVisit    ← NEW (replaces FeatureCoachMark)
   - nodeFirstVisit      ← NEW (replaces Node Guide AlertDialog)
   - eveningReflection   ← NEW (replaces ReflectionCard)
   - dailyInsight        ← NEW (replaces AiCoachCard inline AI)

✅ NarratorNote type enum (expanded)
   - completionTime, missPattern, streakRecovery, questionResponse
   - sessionLength, openTrigger
   - screenVisited       ← NEW: records screen first visits
   - nodeVisited         ← NEW: records node first visits
   - reflection          ← NEW: stores eveningReflection responses (→ insightsRepository)
   - aiInsight           ← NEW: stores the last insight shown in NarratorSummaryCard

✅ HabitCompletionIntent (from other AI spec — keep as-is)
```

---

## PART 5 — PROVIDER CHANGES (RIVERPOD)

```dart
// NEW providers:

@riverpod
HabitCompletionService habitCompletionService(Ref ref);

@riverpod
Future<List<Habit>> todayHabits(Ref ref);

@riverpod
class HabitCompletionNotifier extends _$HabitCompletionNotifier {
  Future<CompletionResult> complete(String habitId, CompletionSource source);
}

@Riverpod(keepAlive: true)
NarratorTriggerEngine narratorTriggerEngine(Ref ref);

@riverpod
class NarratorStateNotifier extends _$NarratorStateNotifier {
  // Manages: should narrator show, which trigger, dismiss
  // Feeds into: NarratorSheet visibility
}

@riverpod
Stream<List<WorldEvent>> worldEventStream(Ref ref);

@riverpod
Future<List<PulseFeedCard>> pulseFeed(Ref ref);

// MODIFIED providers:
// habitRepository: add momentum fields to toJson/fromJson
// userStatsProvider: add worldHealthScore, consecutiveActiveDays
```

---

## PART 6 — FILE STRUCTURE (COMPLETE)

### New Files

```
lib/features/narrator/
├── domain/
│   ├── models/narrator_trigger.dart          ← enum: 12 values
│   ├── models/narrator_note.dart
│   ├── models/narrator_appearance.dart
│   └── services/
│       ├── narrator_trigger_engine.dart       ← Pure function
│       └── narrator_note_service.dart
├── data/
│   ├── datasources/narrator_local_datasource.dart
│   └── repositories/narrator_repository.dart
└── presentation/
    ├── providers/narrator_providers.dart
    ├── providers/narrator_providers.g.dart
    └── widgets/
        ├── narrator_sheet.dart                ← Full bottom sheet
        ├── narrator_summary_card.dart         ← NEW: inline Timeline card (replaces AiCoachCard)
        ├── narrator_typewriter.dart
        └── narrator_pulse_indicator.dart

lib/features/habits/data/services/
└── habit_completion_service.dart           ← Unified completion logic

lib/core/presentation/widgets/
├── completion_particles.dart               ← Particle burst animation
└── one_tap_completion_zone.dart            ← Reusable completion circle

lib/widgets/                                ← Platform widget code
├── habit_stack_widget.dart
└── world_health_widget.dart

lib/features/gamification/domain/services/
└── world_event_engine.dart                 ← Pure function

lib/core/services/
└── notification_snooze_service.dart        ← Reschedule notifs

functions/src/
└── narrator.ts                             ← Slot-filling Cloud Function
```

### Modified Files

#### Core & Navigation
```
lib/core/router/router.dart
  ← Tab order: timeline(0), world(1), social(2), profile(3)
lib/core/presentation/widgets/scaffold_with_nav_bar.dart
  ← Remove center FAB, reorder tab icons
lib/core/services/notification_service.dart
  ← + notification action buttons (Complete / Snooze)
```

#### Habits
```
lib/features/habits/domain/models/habit.dart
  ← + momentumScore, streakState, consecutiveMisses
lib/features/habits/presentation/widgets/habit_card.dart (or equivalent)
  ← One-tap completion zone, particle animation target
lib/features/habits/presentation/screens/streak_recovery_screen.dart
  ← Narrator-first: NarratorTrigger.streakBreakFirstMiss takes over
```

#### Timeline (largest change)
```
lib/features/timeline/presentation/screens/timeline_screen.dart
  ← REMOVE: AiCoachCard import and usage (lines 404-466)
  ← REMOVE: ReflectionCard import and usage (lines 471-475)
  ← REMOVE: FeatureCoachMark import and usage (lines 187-204)
  ← REMOVE: companionEngineProvider / companionRepositoryProvider calls (lines 68-79)
  ← ADD: NarratorSummaryCard in place of AiCoachCard
  ← ADD: NarratorStateNotifier listener that triggers eveningReflection
  ← ADD: context-aware day header (morning/afternoon/evening modes)
```

#### World Map / Level Screen
```
lib/features/world_map/presentation/screens/level_immersive_screen.dart
  ← REMOVE: _showCompanionGuide() method (lines 85-144)
  ← REMOVE: _guideRow() helper (lines 146-175)
  ← REMOVE: tutorialSettingProvider listener that triggers guide
  ← ADD: NarratorStateNotifier.trigger(NarratorTrigger.nodeFirstVisit, context: nodeContext)
```

#### FeatureCoachMark removals (13 additional screens)
```
lib/features/ai/presentation/screens/ai_reflections_screen.dart
  ← REMOVE: FeatureCoachMark block
  ← ADD: NarratorTrigger.screenFirstVisit on first visit
lib/features/gamification/presentation/screens/leveling_screen.dart
  ← REMOVE: FeatureCoachMark block
lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart
  ← REMOVE: FeatureCoachMark block
  ← ADD: NarratorTrigger.newHabitCreation (already planned)
lib/features/profile/presentation/screens/future_self_studio_screen.dart
  ← REMOVE: FeatureCoachMark block
lib/features/social/presentation/screens/all_tribes_screen.dart
  ← REMOVE: FeatureCoachMark block
lib/features/social/presentation/screens/challenge_detail_screen.dart
  ← REMOVE: FeatureCoachMark block
lib/features/social/presentation/screens/challenges_screen.dart
  ← REMOVE: FeatureCoachMark block
lib/features/social/presentation/screens/friends_screen.dart
  ← REMOVE: FeatureCoachMark block
lib/features/social/presentation/screens/leaderboard_screen.dart
  ← REMOVE: FeatureCoachMark block
lib/features/social/presentation/screens/social_activity_screen.dart
  ← REMOVE: FeatureCoachMark block
lib/features/social/presentation/screens/social_contacts_screen.dart
  ← REMOVE: FeatureCoachMark block
lib/features/social/presentation/screens/tribe_lobby_screen.dart
  ← REMOVE: FeatureCoachMark block
  ← REBUILD: as PulseFeedScreen (already planned)
```

#### Deprecated Files (Delete, do NOT leave dead code)
```
lib/core/presentation/widgets/feature_coach_mark.dart    ← DELETE after all 14 usages removed
lib/features/timeline/presentation/widgets/ai_coach_card.dart  ← DELETE (replaced by narrator_summary_card)
lib/features/timeline/presentation/widgets/reflection_card.dart ← DELETE (replaced by eveningReflection trigger)
```

#### Onboarding & Social
```
lib/features/onboarding/presentation/screens/identity_studio_screen.dart
  ← + Narrator appearance post-archetype selection
lib/features/social/presentation/screens/tribe_lobby_screen.dart
  ← Rebuild as PulseFeedScreen (Pulse Feed Phase 3)
functions/src/index.ts
  ← Register narrator Cloud Function
```

---

## PART 7 — TEST STRATEGY

### Unit Tests (Pure Functions — Run First)

```
test/features/narrator/domain/services/narrator_trigger_engine_test.dart
  - shouldTrigger returns null when narrator appeared < 4h ago
  - returns streakBreakFirstMiss on first miss after streak
  - returns longAbsence when 5+ days since open
  - priority: longAbsence beats morningBrief

test/features/gamification/domain/services/world_event_engine_test.dart  
  - travelerVisit fires at 5-day streak
  - travelerVisit does NOT fire if recently fired
  - weatherShift is deterministic for same date
  - discoveryBurst fires at momentum >= 90

test/features/habits/data/services/habit_completion_service_test.dart
  - markComplete returns CompletionResult with correct XP
  - offline completion writes to Drift
  - consecutiveMisses resets to 0 on completion
  - momentumScore increases on completion, decreases on miss
```

### Widget Tests

```
test/core/presentation/widgets/completion_particles_test.dart
  - particles render at correct position
  - animation completes within 300ms

test/features/narrator/presentation/widgets/narrator_typewriter_test.dart
  - renders empty initially
  - reveals characters over time
  - pauses at sentence endings
  - onComplete called when text done
```

### Integration Tests

```
test/integration/habit_completion_offline_test.dart
  - complete habit in airplane mode → Drift updated → reconnect → Firestore synced

test/integration/narrator_trigger_test.dart
  - open app after 5-day absence → Narrator appears with longAbsence template
```

---

## PART 8 — VERIFICATION CHECKLIST

Before shipping each phase:

**Phase 1:**
- [ ] Habit completion: measure time from app open to confirmed completion. Must be <3s.
- [ ] Particle animation fires on every completion without dropping frames (60fps)
- [ ] Timeline is first tab when app opens fresh
- [ ] FAB removed from center nav

**Phase 2 (Narrator):**
- [ ] Narrator appears within 500ms of trigger detection
- [ ] Shell text renders before Groq response (never blank)
- [ ] Groq slot text streams in within 3s on 4G
- [ ] Fallback text shows if Groq times out
- [ ] Narrator cannot appear twice within 4 hours
- [ ] Swipe-to-dismiss always works
- [ ] NarratorNote recorded correctly after button tap

**Phase 3 (Ambient):**
- [ ] Widget completion works in airplane mode
- [ ] Widget updates within 2s of completion
- [ ] Notification "Complete" action works from shade without opening app
- [ ] Pulse Feed loads in <1s (cached)

**Phase 4 (World Events):**
- [ ] WorldEventEngine unit tests all passing
- [ ] TravelerVisit fires for user with 5-day streak in manual test

---

## NON-GOALS (Explicitly Out of Scope)

| Item | Why |
|------|-----|
| Live Activity (iOS 17+) | Too narrow platform support for the engineering cost. Phase 3. |
| Flame animation in widgets | Platform limitation. Static PNG snapshot approach instead. |
| Real-time global counter | Firestore billing risk. Batch-updated counter (hourly Cloud Function). |
| New chat/conversation UI for AI | The Narrator is NOT a chatbot. No text input. Ever. |
| AR Mirror | Phase 5+ roadmap. |
| Full 3D avatar integration | Separate spec. |
| Creator route changes | Separate spec. |

---

## SUMMARY: THE EXECUTION ORDER

```
Week 1-2:  Fix the friction. Navigation + one-tap + completion service + momentum meter.
Week 3-4:  Build the Narrator. The emotional engine that makes it feel alive.
Week 5-6:  Make it ambient. Widgets + notification actions + Pulse Feed.
Week 7:    World Events. Variable reward for long-term retention.
Week 8:    Polish onboarding + streak resurrection flow to match the new system.
```

**One sentence for the whole redesign:**

> Emerge stops being a tool you visit and becomes a world you live in — one that tells you your own story back to you, and makes you want to keep writing it.

---

*Written: July 2, 2026 | Unified from two AI specs | Engineering perspective: 40+ years*
