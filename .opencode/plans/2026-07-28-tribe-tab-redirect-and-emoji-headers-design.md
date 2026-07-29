# Tribe Tab Redirect & Emblem Header Design

## Problem

1. **Tribe tab shows PulseFeedScreen even for tribe members** — users who belong to a tribe and tap the "Tribe" bottom nav tab land on the generic Pulse Feed rather than their tribe's lobby. This breaks the expectation that a tab labeled "Tribe" shows your tribe.

2. **Archetype tribe headers use text labels** — the discovery filter chips and tribe section headers use plain text ("By Archetype", "Creator") instead of the tribe's emblem/box image, making visual scanning harder.

## Design Decisions

### Decision 1: SocialHubScreen wrapper with auto-redirect

A thin `SocialHubScreen` widget sits at `/social` in place of the current `PulseFeedScreen`. It always renders `PulseFeedScreen` as its body, but listens to `hasClubProvider`. When the user belongs to a tribe:

- On first entry to the tab with `hasClub == true`, auto-push `/social/tribe/:id` on the root navigator (full-screen overlay, same as current lobby behavior)
- A `_navigatedToTribe` flag prevents redirect loops when pressing back
- Flag resets when `hasClub` transitions to `false` (user leaves tribe)

Non-members see `PulseFeedScreen` as before — zero behavior change.

### Decision 2: PulseFeedScreen remains default for non-members

No removal or relocation of the pulse feed. It stays as the content of `/social`. Tribe members are auto-redirected; non-members never see the redirect.

### Decision 3: Emblem images replace text labels

Filter chips in the discovery view (`TribeTabContent._buildFilterChips`) and archetype section headers use the tribe's actual emblem image (loaded via `clubEmblemImageUrl()`) instead of plain text. The existing `ClubBoxCard` already shows the emblem — this extends the same treatment to headers.

## Architecture

```
GoRouter Branch 2 (/social)
  └── SocialHubScreen (new)
       ├── PulseFeedScreen (rendered as body)
       └── Listener: hasClubProvider
            └── hasClub == true, flag false → context.go('/social/tribe/${tribeId}')
```

### Data flow

```
hasClubProvider (FutureProvider<bool>)
  └─ ref.listen → _navigatedToTribe flag
       └─ true → currentArchetypeProvider → userClubProvider → tribeId
            └─ context.go('/social/tribe/$id')
```

## Files

### Create

| File | Purpose |
|---|---|
| `lib/features/social/presentation/screens/social_hub_screen.dart` | Wrapper widget with `hasClub` listener + auto-redirect logic |

### Modify

| File | Change |
|---|---|
| `lib/core/router/router.dart:499-504` | Change `/social` builder from `PulseFeedScreen` to `SocialHubScreen` |
| `lib/features/social/presentation/screens/tribe_tab_content.dart:296-321` | Update filter chips to use tribe emblem images instead of plain text labels |

## Edge Cases

| Case | Handling |
|---|---|
| Redirect loop | `_navigatedToTribe` flag, only fires once per `hasClub == true` cycle |
| No archetype (pre-onboarding) | `currentArchetypeProvider` returns `null` → no redirect |
| `hasClub` error | Falls back to `PulseFeedScreen` (safe default) |
| Web setState-during-build | Navigation in `addPostFrameCallback` + `ref.listen` — never during build |
| Tab switching (indexedStack) | Widget stays alive, `_navigatedToTribe` stays `true` → no repeat redirect |
| User leaves tribe | `hasClub` → `false` → flag resets → re-entry redirects again |
| No tribe found for archetype | `userClubProvider` returns `null` → no redirect |

## Non-Goals

- No backend changes (Firestore, providers, repositories, models)
- No changes to `PulseFeedScreen`, `TribeLobbyScreen`, `TribeTabContent` (beyond filter chips)
- No changes to onboarding flow or timeline
