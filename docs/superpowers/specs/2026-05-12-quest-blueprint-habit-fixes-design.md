# Quest, Blueprint & Habit Behavioral Fixes

## Overview
Fixes across 3 features: quest routing/categorization, blueprint discovery/adoption, and habit limits.

---

## 1. Quests: Join → Route + Category Separation

### Problem
- Joining a quest just pops back to challenges, no tab routing
- "All" filter shows a mixed "ACTIVE QUESTS" section combining solo/daily/weekly
- `activeSoloChallenges` includes ALL active quests regardless of type
- Featured quests remain visible after user joins them

### Changes

**1a. Post-join routing** (`challenge_detail_screen.dart`)
- Replace `context.pop()` with `context.go('/tribes/challenges')` after successful join
- This navigates to SocialScreen with Challenges tab active

**1b. Category filtering in ChallengeBundleData** (`challenge_bundle.dart`)
- Add `activeSoloChallenges` → filter by category solo only
- Add `activeDailyChallenge` → getter for active daily quest
- Add `activeWeeklyChallenge` → getter for active weekly quest

**1c. ChallengesScreen "All" filter** (`challenges_screen.dart`)
- Remove the `_ActiveChallengesSection` from filter 0 (All)
- Weekly Spotlight section: show featured OR user's active weekly (not both)
- Daily Quest section: show featured OR user's active daily (not both)
- Solo Quests section: show only active solo quests (unchanged)
- Archetype Challenges section: show only non-joined featured challenges

---

## 2. Blueprint: Adoption Message + Remove Archetype Categories

### Problem
- Adoption snackbar message is verbose: "Blueprint adopted! Your new habit stack is ready."
- Blueprints grouped by archetype category (Athlete, Creator, Scholar, Stoic, Zealot)
- These are identity-type labels, not action-oriented categories

### Changes

**2a. Adoption message** (`blueprint_detail_screen.dart`)
- Change snackbar to: "Adopted successfully"
- Keep routing to `/timeline` after adoption

**2b. Blueprint categories** (`blueprint_repository.dart` + `social_discover_tab.dart`)
- Replace archetype-based categories with action-oriented categories:
  - **Morning** (5 blueprints)
  - **Productivity** (5 blueprints)
  - **Fitness** (5 blueprints)
  - **Mindfulness** (5 blueprints)
  - **Learning** (5 blueprints)
- Update seed data: replace all 25 archetype blueprints with 25 new blueprints across 5 new categories
- Each blueprint uses an online image (Unsplash URL)
- Each category has exactly 5 blueprints
- Remove `creatorArchetype` display from blueprint cards (badge showing archetype)
- Update `_CategoryStrip` title display (already shows category as title)

---

## 3. Habit Limit: 3 → 5

### Problem
- Free tier habit limit is 3
- User wants 5 before premium

### Changes

**3a. Remote Config default** (`remote_config_service.dart`)
- Change `'free_habit_limit': 3` to `'free_habit_limit': 5`

**3b. Code constant** (`habit_providers.dart`)
- Change `const int kDefaultFreeHabitLimit = 3` to `5`

---

## 4. Upgrade Button Bug Fix

### Problem
- PremiumLimitDialog with "UPGRADE" button shows when user hasn't hit the limit
- Race condition: `habitsProvider` may not have loaded when limit check runs

### Root cause
In `advanced_create_habit_dialog.dart:_saveHabit()`:
- Reads `ref.read(habitsProvider).value ?? []` — if habits haven't loaded, value is `null`, defaults to `[]`
- `[].length >= freeHabitLimit` = `0 >= 5` = false (no dialog shown)
- BUT: `createHabitProvider` also checks the limit, and by then habits may have loaded
- If habits count IS at or above limit, BOTH checks show the dialog → "UPGRADE" appears
- This is actually correct behavior for users at the limit

Actually, the bug is this: `_saveHabit()` checks the dialog THEN calls `createHabitProvider`. If the dialog's check passes (user is under limit) but the provider's check fails (because habits loaded in between), the provider throws `SubscriptionLimitReachedException`, which is caught and shows ANOTHER dialog. But if the dialog's check FAILS (user at limit), it returns early before reaching the provider — so only one dialog shows. 

The real bug: if `habitsProvider.value` is null (not loaded), the dialog check mistakenly passes (0 >= limit = false), but `createHabitProvider` then correctly identifies the limit is hit and throws. The user sees the UPGRADE dialog even though the dialog-side check was meant to prevent that.

### Fix
- In `_saveHabit()`, await habitsProvider to ensure it's loaded before checking:
  ```dart
  final habitsAsync = await ref.read(habitsProvider.future);
  final habits = habitsAsync;
  ```
- Remove the redundant dialog-side check and let `createHabitProvider` be the single source of truth for limit enforcement
- OR: consolidate into a single limit check that properly awaits data

Recommended approach: remove the dialog-side duplicate check entirely and rely on the provider-level check + the existing catch handler.

---

## Files Modified

| File | Change |
|------|--------|
| `challenge_detail_screen.dart` | Post-join navigation to `/tribes/challenges` |
| `challenge_bundle.dart` | Add `activeDailyChallenge`, `activeWeeklyChallenge`, fix `activeSoloChallenges` filter |
| `challenges_screen.dart` | Remove mixed `_ActiveChallengesSection` from All; hide featured if joined |
| `blueprint_detail_screen.dart` | Shorter snackbar message |
| `blueprint_repository.dart` | New non-archetype categories, 25 new seed blueprints |
| `social_discover_tab.dart` | Remove archetype badge from cards |
| `remote_config_service.dart` | Change `free_habit_limit` to 5 |
| `habit_providers.dart` | Change `kDefaultFreeHabitLimit` to 5; fix race condition in limit check |
| `advanced_create_habit_dialog.dart` | Remove redundant dialog-side limit check or fix race condition |
