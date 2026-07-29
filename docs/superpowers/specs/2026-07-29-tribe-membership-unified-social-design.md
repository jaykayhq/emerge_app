# Tribe Membership & Unified Social Architecture Design

## Problem Statement

1. **Club-not-showing bug**: Selecting a club during onboarding or via the pulse feed's "Explore tribes" path does not display the club in the tribes screen. Root cause is a 5-layer chain: sync engine async writes → `getUserTribes()` reads Firestore → `hasClubProvider` is a non-reactive `FutureProvider` → `ClubScreen` doesn't invalidate providers → no local Drift membership table.

2. **Fragmented social architecture**: Tribes, friends, challenges, blueprints, creators, and accountability operate as silos with separate data models, repositories, and screens. The tribe is not the hub.

3. **Offline-first violations**: Membership queries hit Firestore directly instead of local Drift. Friend repository is Firestore-only. Challenge repository has no offline implementation.

## Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Membership model | **One tribe per user** | Simplifies data model, strengthens tribe identity |
| Social UX | **Tribe-first everything** | Tribe is the central hub for all social features |
| Membership data | **Drift-first with Firestore sync** | Offline-first; local is truth until sync confirms |
| Join/leave path | **Single `TribeMembershipService`** | Eliminates 3 fragmented join paths |
| `hasClubProvider` | **`StreamProvider` from Drift** | Reactive, no race conditions |
| `recalcTribes` function | **Respect actual membership** | Don't overwrite user-chosen tribes based on archetype |

## Architecture

### Layer 1: Drift Data Layer

**New table: `UserTribeTable`**

| Column | Type | Purpose |
|---|---|---|
| `userId` | `Text` (composite PK) | User identifier |
| `tribeId` | `Text` (composite PK) | Tribe identifier |
| `membershipType` | `Text` | `"archetype"` or `"creator"` |
| `joinedAt` | `Text` | ISO timestamp |
| `isActive` | `Bool` | Exactly one active at a time |
| `syncedAt` | `Text?` | Last sync timestamp |

**New DAO: `TribeMembershipDao`**

- `watchActiveMembership(userId)` → `Stream<UserTribeTableData?>`
- `upsertMembership(companion)` → local write
- `deactivateAll(userId)` → set all `isActive = false`
- `getMembership(userId, tribeId)` → one-shot read

### Layer 2: Service Layer

**`TribeMembershipService`** — single atomic join/leave path:

```
joinTribe(userId, tribeId, type):
  1. Validate: not already in a tribe
  2. Drift: deactivateAll → upsertMembership
  3. Sync Engine: 3 enqueueSet calls (user subcollection, contributor, tribe doc)
  4. Invalidate: hasClubProvider, discoveryClubsProvider, userClubProvider
  5. Notify: social activity event

leaveTribe(userId):
  1. Drift: deactivateAll
  2. Sync Engine: enqueueMutation(delete) + enqueueSet(arrayRemove)
  3. Invalidate: same providers
```

### Layer 3: Presentation Layer

**Refactored screen structure:**

| Screen | Source | Status |
|---|---|---|
| `tribe_tab_content.dart` | 1348-line behemoth | Split into dispatcher + 5 extracted screens |
| `tribe_discovery_screen.dart` | NEW | Club grid, search, filter, join |
| `tribe_sanctum_tab.dart` | NEW | Emblem, stats, activity feed |
| `tribe_quests_tab.dart` | NEW | Active quests, featured quests |
| `tribe_members_tab.dart` | NEW | Leaderboard, member roster |
| `tribe_bonds_tab.dart` | NEW | Tribe-scoped accountability partners |
| `tribe_lobby_screen.dart` | REFACTOR | Uses reactive membership provider |
| `club_screen.dart` | REFACTOR | Uses `TribeMembershipService.joinTribe()` |
| `social_hub_screen.dart` | REFACTOR | Uses `watchActiveMembership()` |

**`hasClubProvider` new form:**
```dart
final hasClubProvider = StreamProvider<bool>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(false);
  final dao = ref.watch(tribeMembershipDaoProvider);
  return dao.watchActiveMembership(userId).map((m) => m != null);
});
```

### Layer 4: Feature Integration

| Feature | Integration | Provider |
|---|---|---|
| Friends | Tribe-scoped partner list | `tribeCircleProvider` |
| Challenges | Tribe-scoped challenge feed | `tribeChallengesProvider` |
| Blueprints | Tribe-curated blueprints | `tribeBlueprintsProvider` (enhanced) |
| Creators | Creators linked to tribe | `tribeCreatorsProvider` |
| Accountability | Tribe-wide contracts | `TribeBondsTab` |

### Layer 5: Cloud Functions

**`recalcTribes.ts` update:**
- Query `users/{uid}/tribes` subcollection for actual membership records
- Only assign by archetype for users with NO explicit membership
- Never overwrite `members` array for users who chose a creator's tribe

No changes needed to:
- `firestore.rules` — existing rules already allow authenticated tribe writes
- `cleanupUserData.ts` — already queries `members` array correctly
- Sync engine — `enqueueSet` with `arrayUnion`/`increment` merge semantics already correct

## Implementation Phases

### Phase 1: Foundation (Loop Cycle 1)
- Drift `UserTribeTable` + `TribeMembershipDao`
- `TribeMembershipService` with join/leave
- `recalcTribes.ts` update
- Verify: `hasClubProvider` returns true immediately after join

### Phase 2: Bug Fix + Provider Rewire (Loop Cycle 2)
- `hasClubProvider` → `StreamProvider`
- `ClubScreen` → `TribeMembershipService`
- `TribeTabContent` → `TribeMembershipService`
- `SocialHubScreen` → `watchActiveMembership()`
- Verify: Club selected during onboarding shows in tribes screen

### Phase 3: Tab Refactor (Loop Cycle 3)
- Extract 5 screens from `tribe_tab_content.dart`
- Each tab is a standalone widget with its own provider
- Verify: Each tab loads independently, no regressions

### Phase 4: Feature Integration (Loop Cycle 4)
- Tribe-scoped friends, challenges, blueprints, creators, accountability
- All features verified offline-first
- No Firestore race conditions

## Verification Gates

| Gate | Command |
|---|---|
| Static analysis | `dart analyze` |
| DAO tests | `flutter test test/core/drift/daos/tribe_membership_dao_test.dart` |
| Provider tests | `flutter test test/features/social/presentation/providers/` |
| Service tests | `flutter test test/features/social/domain/services/tribe_membership_service_test.dart` |
| Screen tests | `flutter test test/features/social/presentation/screens/` |
| Regression | `flutter test test/features/onboarding/presentation/screens/club_screen_test.dart` |

## Rollback Protocol

If any verification gate fails with no clear fix in 15 minutes:
1. Revert phase changes
2. Document failure in task-observer
3. Adjust approach and retry in next loop cycle
