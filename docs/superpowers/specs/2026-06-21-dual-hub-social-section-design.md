# Dual-Hub Social Section — Design

**Status:** Draft
**Date:** 2026-06-21
**Owner:** Social/Tribe feature area

## Summary

The Tribe tab (bottom-nav index 2, route `/social`) is documented as "the
canonical social hub" but has no decided identity: it renders tribe/club
content while the user's personal friends (accountability partners) have no
home in the lobby at all. This produces three concrete defects the user
identified, all rooted in that one structural ambiguity:

1. **The live feed routes to the Friends screen in two places**, but the feed
   is club-scoped while FriendsScreen manages 1:1 partners — two different
   social graphs conflated.
2. **There is no official place where friends enter the lobby.** Friends are
   reachable only via the two misrouted feed deep-links.
3. **"Active Quests" is mislabeled** — the section blends genuinely-active
   joined quests with `featured` catalog templates the user may never have
   touched. Two-thirds of the list is not active.

Underneath these, the social section has three colliding graphs (archetype
**tribe**, 1:1 **partners**, asymmetric **creators**), a complete partners
widget that was orphaned in a `SocialScreen → TribeLobbyScreen` refactor, and
documentation (`screens_overview.md`) that describes files and routes which no
longer exist.

This design resolves all of the above by making the tab an explicit **dual
hub** — tribe and friends as first-class peers in one lobby — and adds a real
partner-activity data source and an address-book contacts discovery surface.

## Decisions (locked)

| Decision | Choice |
|----------|--------|
| Tab identity | **Dual hub** — tribe (collective) + friends (personal) as peers in one lobby |
| Live feed scope | **Club-scoped**, with an honest destination (new `/social/activity`) |
| Spec scope | **Full dual hub + new data sources** |
| Partner activity data | **Live event feed** — new write (fan-out-on-write) + read paths |
| Contacts | **Address-book discovery surface** → invite as partner; not a new relationship tier |

## Non-Goals

- **No new relationship tier.** Contacts resolve to the existing `partner`
  model. A "contacts vs partners" relationship split is explicitly deferred
  (see Future Plans).
- **No changes to the partner model itself** (`Friend`, `PartnerRequest`). We
  reuse it as-is.
- **No changes to the bottom-nav structure** (World / Habits / Tribe /
  Identity). The Tribe tab stays index 2.
- **No creator-graph changes.** The creators strip stays as-is.
- **No club/tribe activity backend changes** — `clubActivityProvider` is
  reused, only paginated in the new screen.

## Architecture

### Lobby IA (restructured `TribeLobbyScreen`)

New sliver order (changed lines marked with ← below).

```
TRIBE LOBBY  (/social)
 1. _Hero                         (tribe emoji/name)         — unchanged
 2. _StatsBar                     (members/streak/momentum)  — unchanged
 3. TribePulseStatusRow           (pulse chips)              — LIVE chip retargeted
 4. YOUR CIRCLE  (partners)       ← NEW section, mounted     — gives friends a home
 5. TribeLiveCompact              (club feed, top 3)         — "View More" retargeted
 6. TribeCreatorsStrip            (creators)                 — unchanged
 7. YOUR QUESTS                   ← renamed + split (active)
 8. QUESTS FOR YOU                ← NEW (featured daily/weekly)
```

Two routing fixes land here:
- **Place 1** (`tribe_live_compact.dart:257`) and **Place 2**
  (`tribe_pulse_status_row.dart:91`) both repoint from `/social/accountability`
  → **`/social/activity`** (the new screen). The feed's "see more" now goes to
  more of the same feed.
- The new **Your Circle** section (§"Your Circle section") becomes the *one*
  honest door to partners.

### New `/social/activity` screen

A full-screen push (registered with `parentNavigatorKey: _rootNavigatorKey`,
matching `/social/accountability` and `/social/leaderboard`) with two tabs:

```
ACTIVITY                              [Tribe] [Partners]
─────────────────────────────────────────────────────
Tribe tab:     full club activity feed (existing clubActivityProvider,
               paginated instead of top-3)
Partners tab:  your circle's live events (new partnerActivityProvider)
```

- **Tribe tab** reuses `clubActivityProvider` but renders the full list with
  pagination — the honest expansion of the compact feed.
- **Partners tab** is the new live event feed.

### Partner Activity data source (new backend)

The core new data source. Two paths.

**Write path — fan-out-on-write.** When a partner-visible event occurs for
user `U`, write a denormalized doc to each of `U`'s partners' activity
subcollections:

```
events that trigger a write:
  • habit check-in / complete
  • streak milestone (7d, 30d, …)
  • quest/challenge joined
  • contract signed

on event, for user U with partners [P1, P2, …]:
  write doc → users/{Pi}/partner_activity/{eventId}
    { actorId, actorName, avatarUrl, type, payload, createdAt }
```

**Rationale:** the partner model is "Only one can walk beside you"
(`invite_code_dialog.dart`) — partner counts are tiny, so write amplification
is negligible and reads stay a single clean query. Events are denormalized at
write time (actor name/avatar snapshotted) so reads never fan out to user
profiles.

**Read path** — new provider:

```
partnerActivityProvider  →  stream of partner_activity docs
  reads: users/{me}/partner_activity ordered by createdAt desc
  shape: denormalized actor info, ready to render
```

The write hooks mirror wherever `clubActivityProvider` currently sources its
events, so tribe and partner activity stay consistent.

**Empty state:** if the user has no partners, the Partners tab shows a clear
prompt → "Find a partner" → `/social/accountability`. Honest about the
precondition rather than a blank feed.

### Your Circle section (friends get a home)

Builds a focused `TribeCircleSection` that fits the lobby's visual language
(reviving the orphaned `TribeAccountabilitySection`, which is production-ready
but never mounted, rather than reusing it verbatim):

```
YOUR CIRCLE                              [2 requests]
┌──────────────────────────────────────────────────────┐
│  ○ Alex   ○ Sam   ○ Jordan        [ + Add partner ]   │
│  (avatars, online dots)                               │
│  Contracts: 3 active          →  /social/contracts    │
└──────────────────────────────────────────────────────┘
                                  tap row → /social/accountability
```

- Pulls from the **same** providers already wired in the orphaned widget:
  `partnersListStreamProvider`, `pendingPartnerRequestsStreamProvider`,
  `activeOnlyContractsProvider`. No new data plumbing — mounting + restyling.
- Tapping the section → `/social/accountability` (`FriendsScreen`). This is
  now the *single* official lobby entry to partners.
- The old `tribe_accountability_section.dart` is deleted (superseded).

### Quest honesty split

The current `TribeActiveQuestsSection` (`tribe_active_quests_section.dart`)
blends active + featured under one label. Split into two honest sections:

- **`TribeYourQuestsSection`** — *only* `userChallengesProvider` filtered to
  `status == ChallengeStatus.active`. Label: **`YOUR QUESTS`**. Empty state:
  "No quests in progress — pick one below."
- **`TribeQuestsForYouSection`** — *only* `dailyQuestFromBundleProvider` +
  `weeklySpotlightFromBundleProvider` (the featured catalog templates). Label:
  **`QUESTS FOR YOU`**. Honest: available, not yet started.

The `ChallengeStatus` enum already has the right vocabulary (`featured` vs
`active`); we stop smuggling `featured` into the `active` list. Both sections
keep their existing `View All →` deep links to `/social/challenges`. The old
blended widget is deleted.

### Contacts discovery (address book)

New `/social/contacts` screen — a discovery surface, *not* a relationship tier:

```
FIND FROM CONTACTS
  [ permission gate: read contacts ]
  Sarah Chen   (555-0142)    [ on Emerge → Add partner ]
  Mike Patel   (555-0188)    [ Invite via code ]
  …
```

- Uses `fast_contacts` + `permission_handler`.
- **Resolution step:** match contact phone numbers/emails against existing
  emerge users (a read-only lookup). Matches → "Add partner" (reuses
  `sendPartnerRequest`). Non-matches → "Invite" (reuses `generateInviteCode`).
- Everyone connected becomes a **partner** — contacts is purely a discovery
  aid, no new relationship tier (YAGNI).
- **Entry point:** an "Add from contacts" affordance inside
  `FriendsScreen` / `InviteCodeDialog`, the partner-management hub.
- **Privacy:** contacts read on-device, never uploaded wholesale. Only the
  phone numbers/emails needed for resolution are sent; resolution is a read,
  not a store.

### Dead code & docs cleanup

The `SocialScreen → TribeLobbyScreen` refactor left debris. As part of this
work:

- **Delete:**
  - `tribe_tab_content.dart` (references nonexistent `CommunityScreen` /
    `TribesScreen`)
  - `FriendsTabContent` class in `friends_screen.dart` (~line 1106)
  - `accountability_screen.dart` (hardcoded fake names, never routed)
  - `tribe_accountability_section.dart` (superseded by `TribeCircleSection`)
  - `tribe_active_quests_section.dart` (superseded by the two split widgets)
- **Rewrite** `screens_overview.md` — currently documents a `SocialScreen` at
  `/tribes` with files that don't exist. Rewrite to match the real
  `TribeLobbyScreen` dual-hub architecture.

## Components

New files (~9):

| File | Responsibility |
|------|----------------|
| `social_activity_screen.dart` | Two-tab activity screen at `/social/activity` |
| `partner_activity_providers.dart` | `partnerActivityProvider` stream + partners-list join |
| `partner_activity_repository.dart` | Interface + Firestore impl for `partner_activity` reads |
| `partner_activity_model.dart` | `PartnerActivityEvent` entity |
| `partner_activity_writer.dart` | Fan-out write hooks (habit/streak/quest/contract events) |
| `tribe_circle_section.dart` | Lobby partners section (revived + modernized) |
| `tribe_your_quests_section.dart` | Active-only quest section |
| `tribe_quests_for_you_section.dart` | Featured-only quest section |
| `social_contacts_screen.dart` | Address-book contacts discovery screen |

Modified (~6):

| File | Change |
|------|--------|
| `tribe_lobby_screen.dart` | Mount new sections, new sliver order |
| `tribe_live_compact.dart` | Repoint "View More" → `/social/activity` |
| `tribe_pulse_status_row.dart` | Repoint LIVE chip → `/social/activity` |
| `router.dart` | Register `/social/activity`, `/social/contacts` |
| `friends_screen.dart` / `invite_code_dialog.dart` | "Add from contacts" entry |
| `friend_repository.dart` + habit/streak/quest/contract completion paths | Wire partner-activity fan-out writes at each partner-visible event point |

Deleted (~5): the orphaned files listed under Dead code & docs cleanup.

New dependencies: `fast_contacts`, `permission_handler`.

## Data Flow

### Partner activity (the new path)

```
[h habit completed]──┐
                     ├─→ PartnerActivityWriter.fanOut(U, event)
[streak milestone]──┤      reads U's partner list
                     │      writes denormalized doc to
[quest joined]──────┤      users/{Pi}/partner_activity/{eventId} for each Pi
                     │
[contract signed]───┘
                                        │
                                        ▼
                partnerActivityProvider (new)
                  stream: users/{me}/partner_activity
                  ordered by createdAt desc
                                        │
                                        ▼
                Partners tab on /social/activity
```

### Feed routing (the fix)

```
ClubActivityProvider ──→ TribeLiveCompact (top 3) ──┐
                                                     │ "View More"
TribePulseStatusRow ──── "LIVE" chip ────────────────┤
                                                     ▼
                              /social/activity  (NEW, honest destination)
                                ├─ Tribe tab   (full club feed, paginated)
                                └─ Partners tab (partner activity, new)

Your Circle section (NEW) ─── tap ───→ /social/accountability  (FriendsScreen)
```

## Error Handling

- **Permission denied (contacts):** the contacts screen shows the permission
  rationale and a retry affordance; never crashes if permission is withheld.
- **partner_activity read failure:** the Partners tab shows a non-blocking
  retry state; the Tribe tab is unaffected (independent streams).
- **Write fan-out partial failure:** writes use the existing sync engine
  (`_syncEngine.enqueueSet`) so partial failures retry on the existing queue
  rather than leaving inconsistent state.
- **Empty states** are explicit and honest everywhere (no partners → prompt to
  add; no active quests → prompt to pick one).

## Testing

- **Model/provider:** unit tests for `partnerActivityProvider` stream shaping
  and `PartnerActivityWriter` fan-out (mock partner list → assert one write per
  partner, denormalized fields present).
- **Quest split:** widget tests asserting `TribeYourQuestsSection` renders only
  `active` items and `TribeQuestsForYouSection` renders only `featured` items,
  given a mixed fixture.
- **Routing:** a golden/router test asserting `tribe_live_compact` "View More"
  and `tribe_pulse_status_row` LIVE chip both push `/social/activity` (not
  `/social/accountability`).
- **Contacts resolution:** unit test of the phone/email → user lookup against
  a mock, with matched/unmatched branches.
- **Existing lobby:** regression widget test of the full lobby rendering with
  the new sliver order.

## Migration / Backfill

- The `partner_activity` subcollection starts empty; the Partners tab
  backfills naturally as users generate qualifying events. **No historical
  backfill** — pre-launch events are not reconstructed. This is acceptable
  because the social section is live but not yet broadly shipped.
- No schema migration on existing collections; `partner_activity` is purely
  additive.
- Deleted files have no live references (verified: `tribe_tab_content.dart`,
  `FriendsTabContent`, `accountability_screen.dart` are never instantiated by
  active routes), so deletion is safe.

## Future Plans

Items deliberately **out of scope** for this spec but recorded so they are
not lost. Each would be its own spec → plan → implementation cycle.

### FP-1: Contacts as a relationship tier
Currently contacts are discovery-only and resolve to `partner`. If the product
later needs a lighter "I know them but we're not accountability partners"
relationship, introduce a `Contact` model + `users/{me}/contacts` collection
with its own request/accept flow, sitting below partners in the social graph:
`strangers → contacts → partners`. This roughly doubles relationship
modeling, so it stays deferred until a concrete need appears.

### FP-2: Unified ranked activity feed
The activity screen keeps Tribe and Partners as separate tabs. A future
enhancement could merge them into one ranked, source-tagged feed
(`[TRIBE]` / `[PARTNER]`) ordered by relevance + recency. Requires a relevance
ranking model and a dual-source merge — deferred until engagement data
justifies it.

### FP-3: Block / mute on the partner graph
`PartnerRequest` currently supports only `pending` / `accepted` / `rejected` —
no `blocked`. If moderation needs arise, add a `blocked` status and a block
list, and have the partner-activity fan-out skip blocked edges.

### FP-4: Partner activity backfill
Onboarding or first-launch could seed `partner_activity` from recent partner
events (retroactively walk the last N days of partner check-ins). Deferred
because there is no clean event log to reconstruct from today.

### FP-5: Tribe-scoped quests / team challenges
Challenges are currently per-user (`users/$userId/challenges`), yet displayed
in a tribe lobby. If real team/tribe-wide quests are wanted, model
`isTeamChallenge` properly (the field exists but is always `false`) with a
tribe-keyed challenge path and shared progress. This changes the quest model,
so it is its own future design.

### FP-6: Creator activity in the feed
The creators strip is faces-only today. A future enhancement could surface
creator activity (new drops, posts) in the activity feed, giving creators a
third honest path into the hub.
