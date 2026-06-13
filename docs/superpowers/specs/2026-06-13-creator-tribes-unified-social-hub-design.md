# Design Spec: Creator Tribes & Unified Social Hub

**Date:** 2026-06-13
**Topic:** Creator-led tribes, social onboarding gate, tribe lobby + portal transition, unified tribe space with separate bottom nav, creator blueprint marketplace, creator hub dashboard.

---

## Goal

Transform the current Social section (3 flat tabs: TRIBE | CHALLENGES | DISCOVER) into a deeply immersive, identity-first **Community Hub** — with a tribe lobby, a cinematic portal transition into a separate tribe space, and a creator economy layer that allows verified external creators to publish blueprints and own their own tribe.

---

## Background & Research Synthesis

Research across Strava, Duolingo, Discord, Habitica, Peloton, WHOOP, BeReal, Nike Run Club and Material Design 3 / HIG 2025 guidelines surfaced the following key principles:

- **Narrow the competition scope** — tribe-scoped leaderboards massively outperform global leaderboards for retention. Users need to feel the game is winnable.
- **Collective quests drive accountability** — the Habitica boss mechanic (shared progress bar where every member contributes) is the most potent social accountability loop found in research.
- **Creator profiles need personality, not just stats** — the Peloton model (full-bleed hero, bio, speciality, programme previews) makes the creator the product, not the content.
- **Tribe must feel like a world, not a tab** — Discord's server model and Emerge's existing world-reveal aesthetic both confirm: crossing a threshold creates stronger identity investment than switching tabs.
- **Social onboarding must be value-first** — present the tribe, show social proof, then ask for commitment. Never gate the core app behind social completion.
- **Authenticity over vanity** — BeReal's reciprocal participation gate and contextual reactions (??????) over generic thumbs create genuine connection rather than clout-chasing.

---

## System Architecture

### Three New Pillars

```
+--------------------------------------------------------+
¦                   TRIBE LOBBY (/social)                ¦
¦   Social onboarding gate (first visit only)            ¦
¦   ? Archetype Tribe or Creator Tribe choice            ¦
¦   Then: Your tribe card + "Enter Tribe" CTA            ¦
+--------------------------------------------------------+
                  ¦ portal transition
    +-------------?--------------------------------------+
    ¦            TRIBE SPACE (separate scaffold)         ¦
    ¦   Own bottom nav: Feed | My Tribe | Board | Discover¦
    ¦   Themed to archetype or creator brand             ¦
    +----------------------------------------------------+
                     ¦ (verified creators only)
         +-----------?--------------------------------+
         ¦           CREATOR HUB (/creator-hub)        ¦
         ¦   Blueprint Builder · Tribe Management      ¦
         ¦   Challenges · Analytics                    ¦
         +--------------------------------------------+
```

### Tribe Membership Rules

- Every user belongs to **exactly one tribe** — either an archetype tribe or a creator tribe.
- Switching is allowed but consequential: a confirmation modal warns *"You'll lose your tribe streak and rank."*
- A user cannot join a creator's tribe without adopting their blueprint. The blueprint IS the entry ticket.
- Creator verification happens outside the app (admin manually sets `isVerifiedCreator: true` in Firestore).

### New Firestore Collections

| Collection | Purpose |
|---|---|
| `creator_profiles` | Verified creator metadata: bio, speciality tags, social links, `isVerifiedCreator`, `blueprintId` |
| `creator_tribes` | Tribe owned by a creator: linked `blueprintId`, cover art, member count, challenges, announcements |
| `tribe_memberships` | Maps `userId ? { tribeType, tribeId, joinedAt, streak }` — single source of truth |
| `tribe_challenges` | Challenges scoped to a tribe (creator-set or system for archetype) |
| `collective_quests` | Shared quest per tribe: goal, progress, contributing member count, end date |

---

## Feature 1 — Social Onboarding Gate

**Trigger:** First time user taps Tribes in main bottom nav. Stored in `users/{uid}.socialOnboardingComplete: bool`.

**Screen:** `SocialOnboardingScreen` — route: `/social/onboarding`

### Layout

```
[Full-bleed atmospheric background — nebula/stars animation]

"YOUR TRIBE AWAITS"
"Every legend belongs to a tribe. Choose yours."

+----------------------------------+
¦  ???  ARCHETYPE TRIBE            ¦
¦  Join thousands of Scholars,    ¦
¦  Athletes, Creators & more.     ¦
¦  ? Matched to your identity     ¦
¦  ? Global community             ¦
¦  ? Compete & climb the board    ¦
¦     [ JOIN ARCHETYPE TRIBE ]    ¦
+----------------------------------+

+----------------------------------+
¦  ?  CREATOR TRIBE              ¦
¦  Follow a verified creator.     ¦
¦  Adopt their exact blueprint    ¦
¦  and join their inner circle.   ¦
¦  ? Curated habit blueprint      ¦
¦  ? Creator-set tribe challenges ¦
¦  ? Tight-knit coached community ¦
¦     [ BROWSE CREATORS ]         ¦
+----------------------------------+

* You can switch tribes at any time
```

### Post-Choice Flow

- **Join Archetype Tribe** ? writes to `tribe_memberships` ? navigates to Tribe Lobby.
- **Browse Creators** ? navigates to `TribeDiscoverTab` (Creator Marketplace) ? user browses ? taps creator ? `CreatorProfileScreen` ? "Adopt Blueprint & Join Tribe" ? confirmation modal ? writes to `tribe_memberships` ? Tribe Lobby.

### State

- `socialOnboardingProvider` — `StreamProvider` reading `users/{uid}.socialOnboardingComplete`
- `tribeSelectionNotifier` — `StateNotifier` handling join action + Firestore writes

---

## Feature 2 — Tribe Lobby Screen

**Route:** `/social`
**Shown:** Every time user taps Tribes in main bottom nav (after onboarding complete).

### Layout

```
[Full-bleed tribe cover art — archetype or creator branded]
[Slow parallax / ambient particle animation]

+--------------------------------------+   glassmorphism card
¦  [Emblem]  THE SCHOLARS  ??          ¦
¦  1,247 members · Your streak: ??14d  ¦
¦                                      ¦
¦  ???  Collective Quest: 73%           ¦
¦  [¦¦¦¦¦¦¦¦¦¦] 897 of 1,247 members   ¦
¦                                      ¦
¦  "3 new check-ins today"             ¦
¦  "? Challenge ends in 2 days"       ¦
+--------------------------------------+

        [ ?  ENTER TRIBE ]

        [ Switch Tribe ]
```

### Ambient Visuals Per Archetype

| Tribe | Effect |
|---|---|
| Athlete | Ember particles, warm orange glow |
| Scholar | Star shimmer, cool blue/indigo |
| Creator | Prismatic light scatter, violet/gold |
| Stoic | Slow fog drift, muted grey/green |
| Zealot | Lightning pulse, electric white |
| Creator Tribe | Creator's custom cover art + brand colour |

### "Switch Tribe" Bottom Sheet

Two sections: (1) 5 Archetype tribe cards with member counts + current tribe checkmark; (2) "Browse Creators" button routing to DISCOVER tab. Switching triggers confirmation modal warning of streak/rank loss.

---

## Feature 3 — Portal Transition

Triggered by tapping **ENTER TRIBE** on Lobby.

### Animation Sequence (~700ms total)

1. Tribe cover art expands from behind glassmorphism card — scale + fade (400ms, ease-out)
2. Archetype/creator colour bleeds radially from centre (300ms)
3. Tribe space scaffold slides up from below — own bottom nav visible at bottom (overlaps step 2)

### Reverse Transition

Swipe right or system back ? scaffold slides down ? colour fades ? lobby re-appears.

**Portal only plays on first entry per session.** Subsequent entries in the same session use a direct cut to avoid feeling like a loading screen.

---

## Feature 4 — Tribe Space (Separate Scaffold)

The main app bottom nav is **completely replaced** by the tribe space scaffold and its own `BottomNavigationBar`, themed to the tribe's colour.

### Tribe Space Bottom Nav

```
  ??          ???           ??          ??
 Feed       My Tribe      Board      Discover
```

---

### Tab 1 — FEED

Chronological activity stream from tribe members only. No algorithm.

**Card types:** Check-in · Milestone · Challenge completed · New member joined

**Reactions:** ?? ?? ?? — tap to react, hold for reactor list.

**Reciprocal participation gate (BeReal-inspired):** If user has not checked in today, feed shows a soft blur + CTA: *"Check in first to see your tribe's activity."* Prevents passive lurking.

---

### Tab 2 — MY TRIBE

```
[Tribe cover art header — collapses on scroll]
[Tribe name + badge + member count + your role]

-----------------------------
??? COLLECTIVE QUEST [sticky]
"30-Day Identity Reset"
[¦¦¦¦¦¦¦¦¦¦ 73% — 897/1,247 contributing]
[Your days: 12/30 ?] [Top 3 avatars this week]
-----------------------------

? TRIBE CHALLENGES
[Horizontal scroll of challenge cards]
[+ Create Challenge — creator/leader/elder only]

-----------------------------

?? MEMBERS
[Top 6 avatar chips with streak flames]
[Role badges: ?? Leader · ? Elder · ?? Member]
[Nudge button — leader/elder only]
[See All Members ?]

-----------------------------

?? ANNOUNCEMENTS (creator tribes only)
[Pinned posts from creator — text + optional image]
```

### Role Hierarchy

| Role | Badge | Earned By | Privileges |
|---|---|---|---|
| Tribe Leader | ?? | Creator (creator tribes) or appointed | All |
| Elder | ? | 30-day tribe streak + top 10% activity | Suggest quests, nudge, moderate |
| Member | ?? | Default on joining | Participate in all content |

---

### Tab 3 — BOARD

```
[Weekly · Monthly · All-time]   ? time toggle
[Tribe · Friends · Global]      ? scope toggle (default: Tribe)

??  [Avatar] Name    ¦¦¦¦¦¦¦¦  2,840 XP
??  [Avatar] Name    ¦¦¦¦¦¦¦   2,610 XP
??  [Avatar] Name    ¦¦¦¦¦¦    2,190 XP
...
-----------------------------
    [You]  YOU       ¦¦¦       847 XP  ? pinned at bottom
    Rank #47
```

- Tap row ? quick-view profile bottom sheet (no full navigation)
- Weekly default, tribe-scoped default — narrow competition = winnable = retained

---

### Tab 4 — DISCOVER

Creator marketplace + tribe/challenge discovery.

```
[Search bar]

? FEATURED CREATORS
[Horizontal scroll — full-bleed creator cards]
  [Hero image · Name · ? Verified · Tags · Member count]
  [View Profile ?]

??? RECOMMENDED FOR YOU
[AI-matched tribe cards by archetype + activity]

?? TRENDING CHALLENGES
[Most-joined challenges this week across all tribes]
```

---

## Feature 5 — Creator Profile Screen

**Route:** `/creators/:creatorId`

### Layout (Peloton-inspired)

```
[Full-bleed hero image — creator in branded context]
[Gradient overlay]

[Creator Name]
[? Verified Creator badge]
[Speciality tags: #Habits #DeepWork #Mindset]
[4,200 tribe members]

[Bio — 2-3 sentences, personality-forward]

-----------------------------
?? THE BLUEPRINT
[Blueprint preview: title, difficulty, habit count]
[See Full Blueprint ?]

? ACTIVE TRIBE CHALLENGES
[2-3 challenge cards]

?? LATEST ANNOUNCEMENT
[Most recent pinned creator post]

?? TRIBE MEMBERS PREVIEW
[6 avatar chips] "Join 4,200 others"

-----------------------------

[ ?? ADOPT BLUEPRINT & JOIN TRIBE ]   ? primary CTA
[ Share Creator Profile ]             ? secondary
```

If user is already a member: CTA becomes `[ ? You're In This Tribe ]` + subtle `[ Leave Tribe ]` link.

---

## Feature 6 — Creator Hub Dashboard

**Route:** `/creator-hub`
**Access:** Only users where `creator_profiles/{uid}.isVerifiedCreator == true`. A "Creator Hub" button appears in their Me tab.

### 4 Internal Sections (top tab row)

**A — Blueprint Builder**
- Create/edit blueprint: title, description, difficulty, category, habit list (drag-reorder)
- Each habit: name, time of day, frequency, attribute
- Cover image + creator hero image upload (Firebase Storage)
- Publish / Unpublish toggle (unpublishing blocks new joins; existing members stay)
- Preview card showing exactly how blueprint appears in DISCOVER

**B — Tribe Management**
- Tribe cover art + name settings
- Member list: role, join date, streak, last active
- Role assignment: promote/demote members
- Remove member (with confirmation)
- Post Announcement: rich text + optional image ? pins to all members' MY TRIBE tab
- Tribe settings: public / private, optional max member cap

**C — Challenges**
- List: active / upcoming / past challenges
- Create Challenge: title, description, duration, habit focus, reward XP, start date, visibility (tribe-only or open)
- Challenge results: completion rate per member, overall completion %

**D — Analytics**
- Blueprint: total adoptions, adoptions this week, 30-day adoption trend chart
- Tribe: member count, growth chart, average tribe streak, most active members
- Challenges: completion rates, most popular challenges
- Activity heatmap: day-of-week × hour grid showing when tribe members check in

---

## Feature 7 — Blueprint Redesign

### Blueprint Card (DISCOVER tab)

Creator blueprints now show:
- Creator hero image (full-bleed card background)
- Creator name + ? Verified badge
- Blueprint title, difficulty, habit count
- Adoption count (social proof)
- Speciality tags

System/archetype blueprints show "Emerge Official" label with archetype branding unchanged.

### Blueprint Detail Screen Changes

New elements added to `blueprint_detail_screen.dart`:
- Creator header: avatar, name, verified badge, "View Creator Profile" link
- Social proof bar: adoption count, tribe member count, active challenge count
- Tribe preview mini-card: collective quest %, member streak averages
- "Join Tribe" replaces "Adopt Blueprint" as the primary CTA (joining = adopting — one action)

### Blueprint Model New Fields (`blueprint.dart`)

```dart
final String? creatorBio;            // Short creator bio for card context
final List<String> specialityTags;   // e.g. ['#Habits', '#DeepWork']
final String? creatorHeroImageUrl;   // Full-bleed creator image
final int tribeMemberCount;          // Live count from creator_tribes
final bool isCreatorBlueprint;       // false = system/archetype blueprint
final String? creatorTribeId;        // Links to creator_tribes collection
```

---

## Navigation & Routing Changes

### New Routes (go_router)

| Route | Screen |
|---|---|
| `/social` | `TribeLobbyScreen` |
| `/social/onboarding` | `SocialOnboardingScreen` |
| `/tribe-space` | `TribeSpaceScaffold` |
| `/tribe-space/feed` | `TribeFeedTab` |
| `/tribe-space/my-tribe` | `MyTribeTab` |
| `/tribe-space/board` | `TribeBoardTab` |
| `/tribe-space/discover` | `TribeDiscoverTab` |
| `/creators/:creatorId` | `CreatorProfileScreen` |
| `/creator-hub` | `CreatorHubScreen` |

### Screens Deprecated

| Old Screen | Replaced By |
|---|---|
| `SocialScreen` (3-tab) | `TribeLobbyScreen` + `TribeSpaceScaffold` |
| `SocialDiscoverTab` | `TribeDiscoverTab` inside tribe space |
| `AllTribesScreen` | "Switch Tribe" bottom sheet on Lobby |

`TribeTabContent` and `ChallengesScreen` are refactored into components within new tribe space tabs — re-homed, not deleted.

---

## Error Handling & Edge Cases

| Scenario | Handling |
|---|---|
| User has no tribe (data gap) | Lobby shows Social Onboarding gate again |
| Creator unpublishes blueprint | Existing members stay; new joins blocked; tribe banner shown |
| Creator tribe has 0 challenges | Empty state: "No active challenges — check back soon" |
| User switches tribe mid-challenge | Progress lost; confirmation modal warns explicitly |
| Feed has no activity today | Empty state: "Be the first to check in today ??" |
| Leaderboard data loading | Skeleton loader matching row layout (not spinner) |
| Portal transition on slow device | Fallback to simple cross-fade if frame rate drops below 30fps |

---

## Verification Plan

### Automated Tests

- `flutter test` — `TribeMembership` model serialisation (archetype + creator variants)
- `flutter test` — `tribeSelectionNotifier` join/switch logic including confirmation flow
- `flutter test` — `socialOnboardingProvider` gate logic (shows once, persists correctly)
- `flutter test` — `Blueprint` new field serialisation

### Manual Verification

1. **Social Onboarding Gate** — fresh user sees gate on first tap; not shown on second visit; both paths route correctly
2. **Tribe Lobby** — quest %, live activity, switch tribe bottom sheet all function correctly; switching triggers modal + updates Firestore
3. **Portal Transition** — smooth (=60fps on mid-range device); back gesture exits correctly; second entry in session skips animation
4. **Tribe Space** — own bottom nav visible; theme colour applied; reciprocal gate blurs feed correctly
5. **Creator Profile & Hub** — non-creators cannot access `/creator-hub`; "Adopt Blueprint & Join Tribe" writes to both collections; analytics charts render
6. **Blueprint Redesign** — creator blueprints show verified badge; system blueprints show "Emerge Official"; detail screen shows tribe preview
