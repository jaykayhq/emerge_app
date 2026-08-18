# Design Specification: World Map Flamekeeper Call-to-Action & Living Archetype System

**Date:** 2026-08-18  
**Status:** Approved  
**Topic:** World Map Call-to-Action (Identity-First Behavioral Hub)  
**Applies to:** emerge_app (lib/features/world_map/, lib/features/habits/)

---

## 1. Overview & Psychological Rationale

### 1.1 The Problem
In the current implementation of WorldMapScreen, the user is presented with a cosmic visualization of their life discipline: the central WorldBonfire (representing global health vs. entropy) and four surrounding WorldTypeNode items (Scholar, Athlete, Creator, Stoic). 

However, this screen operates purely as a **passive spectator gallery**. If world vitality is decaying or entropy is rising, the screen displays a warning (*Your world needs attention*), but provides **zero direct mechanism to act**. The user is forced to leave the screen, navigate to the Timeline tab, find an uncompleted habit, and check it off. This friction breaks the core behavioral loop of *Atomic Habits*.

### 1.2 The Behavioral Solution: The Flamekeeper's Stoking Loop
By operationalizing the Four Laws of Behavior Change, the World Map becomes an active **Identity Engine**:

1. **Law 1 (Make It Obvious):** The WorldStokingDock dynamically queues the **Next Best Action (NBA)** based on real-time realm needs (prioritizing decaying or under-nourished archetypes).
2. **Law 2 (Make It Attractive):** Habit actions are framed not as chores, but as **Identity Votes** and **Hearth Offerings** (e.g., *STOKE CRAFT • 20m Deep Work to nourish Creator*).
3. **Law 3 (Make It Easy):** 1-tap direct voting right from the World Map dock without page switches.
4. **Law 4 (Make It Satisfying):** Completing a vote triggers a kinetic spark particle stream into the WorldBonfire, causing the flame to flare and world health to rise immediately in real time.
5. **The Never Miss Twice Protocol:** If entropy > 0 (a missed habit), the CTA dynamically downscales to a frictionless 2-minute recovery micro-habit (e.g. *Dispel Fog: 2-min Breathwork*) to prevent shame spirals.

---

## 2. Architecture & Component Hierarchy

`
lib/features/world_map/
├── domain/
│   ├── models/
│   │   ├── archetype_node_state.dart      # (NEW) State model for node health & badges
│   │   └── next_identity_vote.dart         # (NEW) Data model for queued NBA action
│   └── services/
│       ├── next_identity_vote_service.dart # (NEW) Pure prioritization logic for NBA
│       └── archetype_status_service.dart   # (NEW) Evaluates per-archetype daily status
├── presentation/
│   ├── providers/
│   │   ├── next_identity_vote_provider.dart # (NEW) Riverpod stream/future for active CTA
│   │   └── archetype_node_states_provider.dart # (NEW) Provides Map<HabitAttribute, ArchetypeNodeState>
│   ├── screens/
│   │   └── world_map_screen.dart           # (MODIFY) Integrates dock and spark burst overlay
│   └── widgets/
│       ├── world_stoking_dock.dart         # (NEW) Floating glassmorphism CTA card
│       ├── world_type_node.dart            # (MODIFY) Adds status badges (complete, pending, decaying)
│       └── world_spark_burst.dart          # (NEW) Kinetic particle animation into the bonfire
`

---

## 3. Detailed Component Specifications

### 3.1 Domain & Logic: NextIdentityVoteService
Pure, testable service that evaluates today's habit list and attributes:
- **Priority Scoring:**
  1. *Decaying Archetypes (Weight: 100):* If an attribute has entropy > 0 or broken streak, its habit becomes top priority with Never Miss Twice framing.
  2. *Under-nourished Archetypes (Weight: 75):* Attribute with lowest current daily completion ratio.
  3. *Context/Time-of-Day (Weight: 50):* Morning habits in AM, evening shutdown rituals in PM.
  4. *Two-Minute Starters (Weight: 25):* Low-friction gateway habits.
- **States Returned:**
  - NextIdentityVote.actionable(habit, attribute, vitalityImpact, isRecovery): An active habit ready to log.
  - NextIdentityVote.harmonized(): All habits for today are completed; displays *Realm Harmonized • View Recap*.
  - NextIdentityVote.empty(): No habits exist for the user yet; displays *Ignite Your First Archetype*.

### 3.2 UI: WorldStokingDock Widget
- **Location:** Floating above bottom safe area / bottom navigation bar on WorldMapScreen.
- **Styling:** Glassmorphism card (gba(18, 14, 32, 0.85), blur: 16px, border: ttributeColor.withOpacity(0.4)).
- **Contents:**
  - **Tag Pill:** Glowing dot + uppercase label (e.g., NEXT IDENTITY VOTE • CRAFT or RECOVERY ACTION).
  - **Reward Badge:** Expected vitality gain (e.g. +14% VITALITY or DISPELS FOG).
  - **Title & Subtitle:** Habit title + identity affirmation (*Empowers Creator • Cast vote to fuel hearth*).
  - **Action Button:** 
    - Green #2BEE79 for normal votes.
    - Violet #A855F7 for recovery votes.
    - Muted glass for Harmonized recap.
- **Micro-Interaction:** Tapping triggers onCastVote(habit) and launches WorldSparkBurst.

### 3.3 UI: WorldTypeNode Badges & Visual Pulses
- Each of the 4 nodes (Scholar, Athlete, Creator, Stoic) receives an overlay status badge:
  - **🟢 Complete (✓):** All habits for this archetype completed today.
  - **🟡 Pending Fuel (! or count):** 1+ habits remaining today.
  - **⚠️ At Risk (⚠️):** Attribute suffering decay/entropy.

### 3.4 Animation: WorldSparkBurst
- An ephemeral overlay / custom painter that renders 12-16 glowing spark particles travelling from the dock button to the center WorldBonfire.
- On particle arrival, WorldBonfire executes a momentary scale flare (1.0 -> 1.25 -> 1.0) and updates the glow shadow.
- Respects MediaQuery.disableAnimationsOf(context): instantly updates health if reduced motion is enabled.

---

## 4. Error Handling & Edge Cases

| Scenario | Behavior |
| :--- | :--- |
| **All Daily Habits Complete** | Dock transitions to *Realm Harmonized (100%)*, action button opens /recap-hub. |
| **User Has Zero Habits** | Dock displays *Ignite Your First Archetype*, action button navigates to /habits/new. |
| **Offline Mode (No Connection)** | Votes are committed instantly to Drift SQLite (HabitActivityDao) with optimistic health recalculation; background Firestore sync fires automatically when online. |
| **Small Screen Viewports** | Ring radius and dock margin scale dynamically via LayoutBuilder so the dock never overlaps ring nodes. |

---

## 5. Verification Plan

### Automated Tests
1. 	est/features/world_map/domain/services/next_identity_vote_service_test.dart
   - Test priority calculation with decaying attribute (entropy > 0).
   - Test priority calculation with under-nourished attribute.
   - Test all-complete scenario returning harmonized().
   - Test zero habits scenario returning empty().
2. 	est/features/world_map/presentation/widgets/world_stoking_dock_test.dart
   - Verify widget renders correct attribute colors and text.
   - Verify tap callback executes with selected habit.
   - Verify Harmonized state renders recap action.
3. 	est/features/world_map/presentation/widgets/world_type_node_test.dart
   - Verify node renders complete, pending, and decay badges correctly.
4. 	est/features/world_map/presentation/screens/world_map_screen_test.dart
   - Verify integration of WorldStokingDock into WorldMapScreen.

### Static Analysis
- Run dart analyze to ensure zero warnings or errors.
