# Tribe Lobby Restructure — Implementation Plan

## Design Decisions (ULTRATHINK Output)

### IA: top-to-bottom sequence (locked)
1. **Hero** — archetype emblem, tribe name, subtitle (kept; cleaned)
2. **Stats Bar** — 3-column: MEMBERS / STREAK / **MOMENTUM** (relabeled, was mislabeled "QUESTS")
3. **Status Chips Row** (NEW) — live pulse: members online · last sync · momentum state · quest window
4. **Live Feed / Leaderboard** — compact two-tab segmented block, 3 items each, "View More" CTAs
5. **Creators** — horizontal scroll of FACES only (no blueprints). Real data, fallback avatar
6. **Active Quests** — real user challenges with currentDay/joinedAt, no fake challenges
7. **View More row** — full feed / leaderboard / quests routes
8. **Switch Tribes / Creators** — sticky bottom action bar (cannot miss)

### Background
- Remove `Image.network(REMOTE_NEBULA_URL)` + gradient overlay from `tribe_lobby_screen.dart`
- Set `Scaffold.backgroundColor = Colors.transparent`
- The shell's `WorldBackground` (already painted by `ScaffoldWithNavBar`) will show through
- `EmergeColors.nebulaBackground = Color(0xFF050505)` is acceptable for content contrast since WorldBackground fades to dark at top/bottom via its overlay

### Hardware Back
- Wrap `TribeLobbyScreen` in `PopScope(canPop: false, onPopInvokedWithResult: ...)` → calls `context.go('/')` (world map)
- Wrap `WorldMapScreen` in `PopScope(canPop: false)` → double-tap-to-exit with SnackBar ("Tap back again to exit")
- Both implemented as a reusable `AppBackHandler` helper widget

### Stats Fixes
- Lobby "QUESTS" → "MOMENTUM" (semantic fix; render `profile.momentumScore.clamp(0,1)` as 0–100)
- World map XP progress bar: replace `500` literal with `GamificationConstants.xpPerLevel` (read from `gamification_service.dart`)
- Add `EffectiveLevelStat` widget that shows `profile.effectiveLevel` consistently

### Creator Profile Rewrites
- Replace hardcoded `i.pravatar.cc/150?img=12` → use `profile.avatarUrl` with `FallbackInitialAvatar` widget (renders initials in archetype-coloured circle)
- Replace hardcoded stats (RECRUITS 14.2K · MISSIONS 28 · RATING 4.9) with computed:
  - RECRUITS = sum of `adoptionCount` across creator's blueprints (streamed)
  - MISSIONS = count of creator's blueprints
  - RATING = show "—" (no rating system exists yet — don't fake it)
- Keep the "LATEST TRANSMISSIONS" blueprints carousel, but use real data
- Add a verified/featured badge that uses real `profile.isVerifiedCreator` and `profile.specialityTags`
- Wire JOIN VANGUARD CTA to navigate to creator's first blueprint via new `/blueprint/:id` route

### Routes Added
- `/blueprint/:id` (top-level + under /social) → `BlueprintDetailScreen(blueprint: passed via extra)`
  - BlueprintDetailScreen already exists at `/lib/features/social/presentation/screens/blueprint_detail_screen.dart`
- `/creators` (top-level) → `CreatorsBrowseScreen` (new, simple list)
- `/social/discover` → re-use `CreatorsBrowseScreen` (avoids duplicate)

### Fake Data Removal
- All `Commander Vex`, `Nova Elite`, `Lyra_99`, `Kael_Vox` literals → gone
- All pravatar.cc URLs → replaced with `FallbackInitialAvatar`
- Hardcoded challenge titles (`Daily Check-in Node`, `Void Runner`) → real `Challenge` data from `userChallengesProvider`
- Hardcoded stats in creator profile → computed
- Hardcoded `itemCount: 5` in `_CreatorCard` → real creators from a new `verifiedCreatorsProvider`

### New Creator Seed
- Add `seedCreatorsIfEmpty()` to `CreatorRepository` — creates 6 verified creator profiles
- Add `seedCreatorBlueprintsIfEmpty()` to `BlueprintRepository` — creates 6 "featured creator" blueprints linked to seeded creators
- Wire both into `seed_runner.dart`

### CTA Visibility (per request: "make sure the CTA is very visible")
- Create `lib/core/presentation/widgets/emerge_primary_button.dart` — gradient pill, 56px tall, full-width, uppercase, letterSpacing 2, with optional icon and shimmer
- Replace the hand-rolled gradient buttons in lobby + creator profile with this
- Sticky bottom action bar on lobby uses this widget

## File Touch List

### NEW files
- `lib/core/presentation/widgets/emerge_primary_button.dart` — shared CTA
- `lib/core/presentation/widgets/fallback_initial_avatar.dart` — initials avatar fallback
- `lib/core/presentation/widgets/app_back_handler.dart` — PopScope helper for double-tap-to-exit
- `lib/features/social/presentation/widgets/tribe_pulse_status_row.dart` — status chips row
- `lib/features/social/presentation/widgets/tribe_creators_strip.dart` — horizontal scroll of creator faces (real data, no fake)
- `lib/features/social/presentation/widgets/tribe_active_quests_section.dart` — real quests (replaces nebula_challenges_section.dart)
- `lib/features/social/presentation/widgets/tribe_live_compact.dart` — compact feed + leaderboard tab block
- `lib/features/social/presentation/screens/creators_browse_screen.dart` — browse all creators
- `lib/features/social/presentation/providers/verified_creators_provider.dart` — fetches real verified creator profiles

### MODIFIED files
- `lib/features/social/presentation/screens/tribe_lobby_screen.dart` — full rewrite per IA
- `lib/features/social/presentation/screens/creator_profile_screen.dart` — strip fake data, use real stats
- `lib/features/social/presentation/widgets/tribe_discover_section.dart` — DELETE (replaced by tribe_creators_strip + creators_browse_screen)
- `lib/features/social/presentation/widgets/nebula_challenges_section.dart` — DELETE (replaced by tribe_active_quests_section)
- `lib/features/social/presentation/widgets/tribe_activity_feed_widget.dart` — DELETE (mock data; lobby now uses tribe_live_compact with real data)
- `lib/core/router/router.dart` — add `/blueprint/:id`, `/creators`, `/social/discover`; wire lobby creator CTA
- `lib/features/world_map/presentation/screens/world_map_screen.dart` — PopScope double-tap-exit; fix XP `500` literal
- `lib/features/social/data/repositories/creator_repository.dart` — add `seedCreatorsIfEmpty()`; add `watchVerifiedCreators()`
- `lib/features/blueprints/data/repositories/blueprint_repository.dart` — add `seedCreatorBlueprintsIfEmpty()`
- `lib/core/data/seed_runner.dart` — call new seeds
- `lib/features/social/presentation/providers/creator_provider.dart` — add `verifiedCreatorsStreamProvider`

## Implementation Order (parallel where safe)

### Wave 1 (parallel, no inter-dependencies)
- **Agent A**: New widgets — `emerge_primary_button`, `fallback_initial_avatar`, `app_back_handler`, `tribe_pulse_status_row`, `tribe_creators_strip`, `tribe_active_quests_section`, `tribe_live_compact`, `verified_creators_provider`, `seedCreatorsIfEmpty()`, `seedCreatorBlueprintsIfEmpty()`
- **Agent B**: Rewrite `creator_profile_screen.dart` — strip hardcoded data, use real stats, wire JOIN CTA
- **Agent C**: Fix world_map_screen XP bar (`500` → `GamificationConstants.xpPerLevel`), wrap in PopScope
- **Agent D**: Add `/blueprint/:id`, `/creators`, `/social/discover` routes; new `CreatorsBrowseScreen`; wire seed_runner

### Wave 2 (sequential, depends on Wave 1)
- **Agent E**: Rewrite `tribe_lobby_screen.dart` per new IA; delete `tribe_discover_section.dart`, `nebula_challenges_section.dart`, `tribe_activity_feed_widget.dart`

### Wave 3 (review)
- **Reviewer**: lint + type-check, check no broken references remain, run `flutter analyze`

## Verification
- `flutter analyze` — no errors
- All `context.push('/blueprint/...')` call sites now route correctly
- All `context.push('/social/discover')` and `/creators` call sites route correctly
- No `i.pravatar.cc`, `lh3.googleusercontent.com`, `Commander Vex`, `Nova Elite`, `Lyra_99`, `Kael_Vox`, `Daily Check-in Node`, `Void Runner`, `Creator ${index}`, `14.2K`, `MISSIONS 28`, `RATING 4.9`, `stats.totalXp % 500` literals remain in `lib/features/social/`
- WorldBackground paints through the lobby (visual confirmation)
