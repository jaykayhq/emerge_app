# Gamification & Level Progression Enhancements

**Date:** 2025-02-26
**Status:** Approved
**Requirements:** 8 of 9 (time-based habits deferred)

---

## Overview

This design creates a cohesive, production-ready gamification system with standardized progression, consistent theming, proper XP tracking, and mission gating.

---

## Requirements Scope

| # | Requirement | Status |
|---|-------------|--------|
| 1 | Level-up screen after every level | ✅ In Scope |
| 2 | Exactly 5 levels per archetype stage | ✅ In Scope |
| 3 | Unified archetype colors | ✅ In Scope |
| 4 | Individual XP per attribute in nodes | ✅ In Scope |
| 5 | Mission completion soft gate | ✅ In Scope |
| 6 | Synergy cards: 2 attrs + See More | ✅ In Scope |
| 7 | Time-based habit anchor replacement | ❌ Deferred |
| 8 | Anytime habits time filtering | ❌ Deferred |
| 9 | Zealot archetype link fix | ✅ In Scope |

---

## XP System Architecture

### Three-Tier XP Model

```
Node XP (mission progress)
    ↓ (100 XP to complete)
Attribute XP (cumulative per attribute)
    ↓ (sum of all attributes)
Total Level XP (÷ 500 = level)
```

**Example:**
- Complete Strength node mission → +100 XP to Strength
- Strength total: 2,450 XP
- All attributes total: 9,400 XP
- Level: 9,400 ÷ 500 = Level 18

---

## 1. Level-Up Triggers

**Current:** `LevelUpListener` exists but triggers inconsistently

**Solution:**
- Wrap entire app in `LevelUpListener` (already at root)
- Listen to `userStatsStreamProvider` for level changes
- Compare `previousLevel` vs `currentLevel` on every emit
- Store `lastCelebratedLevel` to avoid duplicates

**Files:**
- `lib/features/gamification/presentation/widgets/level_up_listener.dart`

---

## 2. Archetype Level Structure

**Standardized 5-level stages:**

| Archetype | Stage 1 (1-5) | Stage 2 (6-10) | Stage 3 (11-15) |
|-----------|---------------|----------------|-----------------|
| Athlete | Valley Base | Forest Trail | Mountain Climb |
| Scholar | Library | Laboratory | Archive |
| Creator | Workshop | Gallery | Studio |
| Stoic | Garden | Temple | Sanctuary |
| Zealot | Shrine | Conclave | Ascension |
| Explorer | Camp | Outpost | Fortress |

**Node Pattern (repeats each stage):**
| Level | Type | Purpose |
|-------|------|---------|
| 1 | Waypoint | Tutorial/intro |
| 2 | Resource | Attribute unlock |
| 3 | Challenge | Skill test |
| 4 | Resource | Attribute unlock |
| 5 | Milestone | Gate to next stage |

**Files:**
- `lib/features/world_map/domain/models/archetype_maps_catalog.dart`

---

## 3. Unified Color System

**Archetype Colors:**

| Archetype | Primary | Accent | Attributes |
|-----------|---------|--------|------------|
| Athlete | `#FF5252` | `#FF8A80` | Strength, Vitality |
| Scholar | `#E040FB` | `#EA80FC` | Intellect, Focus |
| Creator | `#76FF03` | `#B0FF57` | Creativity, Vitality |
| Stoic | `#00E5FF` | `#80D8FF` | Focus, Spirit |
| Zealot | `#FFAB00` | `#FFD54F` | Spirit, Strength |
| Explorer | `#2BEE79` | `#7EFFAC` | All balanced |

**Files:**
- `lib/core/theme/archetype_theme.dart` — add `ArchetypeColors` class
- `lib/features/profile/presentation/widgets/synergy_status_card.dart`
- `lib/features/world_map/presentation/widgets/*.dart`

---

## 4. Node XP Display

**Node shows mission progress:**
```
┌─────────────────────┐
│  💪 Strength Node   │
│  Mission: 3 workouts │
│                     │
│  45 / 100 XP        │  ← Progress to complete
│  ████████░░░░░      │
└─────────────────────┘
```

**On completion (100 XP):**
- Node marks complete
- +100 XP to Strength attribute
- +100 XP to total level XP

**Node Attributes:**
- Waypoint: No XP (tutorial)
- Resource: 1 primary attribute
- Challenge: 2 attributes
- Milestone: All 6 attributes

**Files:**
- `lib/features/world_map/domain/models/world_node.dart` — add `primaryAttributes`, `attributeXp`
- `lib/features/world_map/presentation/widgets/structure_node.dart`

---

## 5. Mission Soft Gate

**Node States:**
```
COMPLETED → ACTIVE → LOCKED
    ↑          │         │
    └──────────┴─────────┘
         (sequential)
```

**Lock Logic:**
- Locked if previous node incomplete OR user level too low
- Tapping locked shows: "Complete [mission] first to unlock"
- Completed nodes stored in `user_stats.worldState.completedNodeIds`

**Files:**
- `lib/features/world_map/domain/models/world_node.dart` — add `missionCompleted`
- `lib/features/world_map/presentation/widgets/structure_node.dart`

---

## 6. Synergy Cards (2 Attributes + See More)

**Card Layout:**
```
┌─────────────────────────────────────┐
│  💪 STRENGTH        🧠 INTELLECT   │
│  2,450 XP           1,890 XP        │
│  +15% from          +10% from       │
│  Morning Workout    Read 30min      │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      [+2] See More           │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

**See More Sheet:**
Shows all 6 attributes with cumulative XP, sorted by descending.

**Files:**
- `lib/features/profile/presentation/widgets/synergy_status_card.dart`
- Create `AttributeBreakdownSheet` widget

---

## 7. Zealot Archetype Content

**Full Zealot Progression (15 levels):**

| Level | Type | Name | Attributes | Mission |
|-------|------|------|------------|---------|
| 1 | Waypoint | First Flame | Spirit | Light your first flame |
| 2 | Resource | Inner Fire | Spirit | Complete 3 devotional habits |
| 3 | Challenge | Trial of Devotion | Spirit, Strength | 5-day streak + strength workout |
| 4 | Resource | Burning Focus | Spirit | Morning ritual, 7 days |
| 5 | Milestone | Flame Unleashed | All | Complete stage 1 |

Stage 2 (Conclave) and Stage 3 (Ascension) follow same pattern with themed missions.

**Visual Theme:**
- Flame particles, warm glow effects
- Orange/gold color palette
- Ascending/church-like architecture

**Files:**
- `lib/features/world_map/domain/models/archetype_maps_catalog.dart`

---

## Implementation Order

1. **Phase 1: Foundation** (Colors, XP model)
2. **Phase 2: Nodes** (Display, gates, Zealot content)
3. **Phase 3: Level-up** (Triggers, screen)
4. **Phase 4: Synergy** (Card expansion, sheet)

---

## Deferred Features

**Time-Based Habits** (Requirements 7-8):
- Not implemented in current codebase
- Requires significant UX work
- Will be addressed as separate feature

---

## Success Criteria

- ✅ Level-up screen shows on every level increase
- ✅ All archetypes have 5 levels per stage
- ✅ Colors consistent between map and profile
- ✅ Nodes show specific attribute XP
- ✅ Missions must complete before next node
- ✅ Synergy cards show 2 attributes + See More
- ✅ Zealot links to Zealot content (not Mystic)
