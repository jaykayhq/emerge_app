# Creator Analytics Dashboard — Design

**Date:** 2026-08-18
**Status:** Approved for planning
**Feature area:** Creator dashboard · `lib/features/social`
**Companion spec:** `2026-08-18-shareable-images-design.md` (planned in the same session)

## 1. Context & Problem

The creator dashboard (`creator_overview_tab.dart`) shows a handful of crude cards —
Blueprint count, Adoptions, Total Habits, and a **fake** "+X/wk" Growth Rate
(`totalAdoptions / 7`) — plus a "Full Analytics — SOON" card that only shows a
snackbar. The tribe management tab shows three live chips (members, tribe XP,
habits done) and a placeholder "Member list available in full analytics view."

Creators need a real analytics surface: the important metrics about their tribe,
with trends over time and a per-member breakdown.

## 2. Decisions (from brainstorming)

- **Depth:** Full suite — live KPI cards + time-series trends + per-member breakdown.
- **Placement:** A new 4th nav branch "Analytics" in the creator dashboard shell
  (`StatefulShellRoute.indexedStack`), between/after the existing three branches.
- **Metrics:** Member growth, engagement volume, blueprint performance, top
  members, challenge health.
- **Trend data:** **Client-side daily snapshot** (not a scheduled Cloud Function).
  When a creator opens the analytics tab, if the last snapshot is >24h stale,
  the client writes today's snapshot to `tribe_analytics/{tribeId}/daily/{date}`.
  History accumulates as creators open the app.
- **Architecture:** Pure aggregation service + Riverpod provider (the project's
  signature testable pattern), with a Drift cache of the last snapshot for
  offline-first rendering.

## 3. Data model

### Firestore: `tribe_analytics/{tribeId}/daily/{date}` (new)

```dart
class TribeAnalyticsSnapshot {
  final String tribeId;
  final String date;            // yyyy-MM-dd (snapshot day)
  final int memberCount;
  final int totalXp;
  final int totalHabitsCompleted;
  final int totalChallengesCompleted;
  final int activeMembers;      // contributors active in last 7d
  final int newMembersThisWeek; // contributors joined in last 7d
}
```

Written client-side (idempotent per day — same doc id, upsert). `createdAt` uses
`FieldValue.serverTimestamp()`.

### Pure struct the UI renders (computed)

```dart
class CreatorAnalytics {
  final String tribeId;
  final String tribeName;
  // KPIs (live)
  final int memberCount, totalXp, totalHabitsCompleted, totalChallengesCompleted;
  // Member growth
  final int newMembersThisWeek, activeMembers;
  final double activeRate;                      // activeMembers / memberCount
  // Blueprints (creator-owned)
  final List<BlueprintStat> blueprintStats;     // title, adoptions, habits
  // Top members
  final List<MemberStat> topMembers;            // name, xp, habitsCompleted (top 10)
  // Challenges (creator-published)
  final List<ChallengeStat> challengeStats;     // title, participants, status, xpReward
  // Trends (from daily snapshots, 30d)
  final List<DailyTrend> trends;                // date, memberCount, xp, habits
}

class DailyTrend { final String date; final int memberCount, totalXp, totalHabitsCompleted; }
```

## 4. Data sources (rules-compliant)

**Critical constraint:** `user_stats` is owner-only in `firestore.rules`
(`allow read: if isOwner(userId) || isAdmin()`). The existing
`TribeStatsService` batch-queries other members' `user_stats` — denied in
production. Analytics **must not** aggregate from `user_stats`.

Instead, aggregate from:

| Metric | Source | Rules status |
|---|---|---|
| Tribe name, total memberCount | `tribes/{tribeId}` | `allow read: if isAuthenticated()` |
| Top members, XP, habits, challenges, joinedAt, lastActivity | `tribes/{tribeId}/contributors/*` | `allow read: if isAuthenticated()` |
| Blueprint adoptions + habits | `blueprints` (filter `creatorUserId == uid`) | `allow read: if true` |
| Challenge participants/status | `challenges` (filter `createdBy == uid`) + `challenges/{id}/participants/*` | `allow read: if true` / authenticated |
| Snapshot history | `tribe_analytics/{tribeId}/daily/*` | new rule (below) |

The `contributors` subcollection already stores the per-member fields we need
(`totalXpContributed`, `totalHabitsCompleted`, `totalChallengesCompleted`,
`joinedAt`, `lastActivity`, `userName`). This is the aggregation-friendly source,
matching how `tribe_stats_service.dart` should ideally already work.

## 5. Architecture & files

```
lib/features/social/domain/models/creator_analytics.dart
  // pure structs: CreatorAnalytics, BlueprintStat, MemberStat, ChallengeStat,
  // DailyTrend, TribeAnalyticsSnapshot (+ fromMap/toMap, ==/hashCode)

lib/features/social/data/services/creator_analytics_service.dart
  // Aggregates live KPIs + breakdowns from tribes/contributors/blueprints/challenges.
  // Pure-ish: takes Firestore, returns Either<Failure, CreatorAnalytics>.
  // Shared aggregation helpers extracted so TribeStatsService can reuse them.

lib/features/social/data/services/tribe_analytics_snapshot_service.dart
  // Writes today's snapshot (idempotent) when >24h stale; reads last 30d.

lib/features/social/presentation/providers/creator_analytics_provider.dart
  // @riverpod family keyed by (uid, tribeId). Stream: Drift cache first,
  // Firestore live, non-blocking snapshot write when stale.

lib/features/social/presentation/screens/creator/creator_analytics_tab.dart
  // The 4th nav branch UI.
```

### Drift cache

Add a dedicated `TribeAnalyticsTable` keyed by `(tribeId, date)` storing the full
`TribeAnalyticsSnapshot` shape, so the tab renders instantly offline and
refreshes when Firestore catches up — the project's offline-first pattern. A
separate table keeps analytics fields out of the existing `TribeStatsTable`
(tribe-stats cache), which is synced by `FirestoreDriftSyncer` for other
surfaces.

## 6. Data flow

1. Open `/creator/dashboard/analytics` → `creatorAnalyticsProvider(uid, tribeId)`.
2. Emit cached Drift row immediately (if any) → render.
3. `CreatorAnalyticsService` aggregates live KPIs + breakdowns from
   tribes/contributors/blueprints/challenges → emit.
4. `TribeAnalyticsSnapshotService` checks last snapshot date; if >24h stale,
   writes today's snapshot (non-blocking, never awaited before render).
5. Read last 30 days of snapshots → trends → emit.
6. Update Drift cache with the freshest snapshot.

## 7. UI — `CreatorAnalyticsTab`

Follows `docs/design.md` §5 state UX: every `AsyncValue` handles
loading/error/data + empty case.

```
┌─ Creator Analytics ─────────────────────────┐
│  [Members] [Tribe XP] [Habits done] [Challenges] │  ← KPI cards (live)
│  ──────────────────────────────────────────── │
│  MEMBER GROWTH                                │
│  ██ bar chart: last 30 days memberCount       │  ← fl_chart
│  +N new this week · M active (A%)             │
│  ──────────────────────────────────────────── │
│  ENGAGEMENT                                   │
│  ▂▂ line chart: habits completed (30d)        │  ← fl_chart
│  ──────────────────────────────────────────── │
│  BLUEPRINTS                                   │
│  [Blueprint A · 12 adoptions · 4 habits]      │
│  ──────────────────────────────────────────── │
│  TOP MEMBERS                                  │
│  1. Name · 5,200 XP · 34 habits               │
│  ──────────────────────────────────────────── │
│  CHALLENGES                                   │
│  [Title · 8 participants · Active · 100 XP]   │
│  ──────────────────────────────────────────── │
│  [Share tribe card]  ← wires to shareable spec│
└───────────────────────────────────────────────┘
```

- KPI cards reuse the `_AnalyticCard` style from `creator_overview_tab.dart`.
- Trends use `fl_chart` (already a dependency). Bar for member growth, line for
  engagement. Empty trend series → empty state, never a blank chart.
- The Overview tab's "Full Analytics — SOON" card is rewired to switch to the
  analytics branch via `context.go('/creator/dashboard/analytics')` (branch
  switch, not a pushed page); the fake Growth Rate card is replaced with the
  real member-growth number.
- The tribe management tab's "Member list available in full analytics view"
  placeholder links here.

## 8. Error handling

- All service calls return `Either<Failure, T>`; consumers `.fold`.
- Snapshot write failure → non-blocking, `debugPrint`, live KPIs still render.
- No tribe yet / no blueprints / no snapshots (new creator) → explicit empty
  states ("History builds as you open analytics daily").
- Firestore error → `AppErrorWidget` with retry (`ref.invalidate`), matching the
  tribe tab.

## 9. Security (firestore.rules)

New rule for `tribe_analytics` — creator-owned tribe, validated shape:

```
match /tribe_analytics/{tribeId} {
  allow read: if isAuthenticated();
  match /daily/{date} {
    allow read: if isAuthenticated();
    allow create, update: if isAuthenticated() &&
      get(/databases/$(database)/documents/tribes/$(tribeId)).data.createdBy
        == request.auth.uid &&
      request.resource.data.tribeId == tribeId &&
      request.resource.data.date == date &&
      request.resource.data.memberCount is number &&
      request.resource.data.totalXp is number &&
      request.resource.data.totalHabitsCompleted is number &&
      request.resource.data.totalChallengesCompleted is number &&
      request.resource.data.activeMembers is number &&
      request.resource.data.newMembersThisWeek is number;
    allow delete: if false;
  }
}
```

## 10. Testing (TDD)

Mirrors `test/features/social/...`. Use `fake_cloud_firestore`; no mocks where
fakes suffice.

- **Unit — `CreatorAnalyticsService`:** aggregates KPIs; member growth from
  contributor `joinedAt`; active members from `lastActivity` (7d window); top
  members sorted by XP desc (top 10); blueprint/challenge breakdowns; empty
  inputs → zeros; missing creator → empty state.
- **Unit — `TribeAnalyticsSnapshotService`:** write-once-per-day idempotency;
  24h staleness check; 30-day read; write failure → `Left(Failure)`.
- **Widget — `CreatorAnalyticsTab`:** loading (`EmergeLoadingSkeleton`), error
  (`AppErrorWidget` + retry), data (KPI cards render values, charts present),
  empty (no tribe / no snapshots).
- **Router:** `/creator/dashboard/analytics` reachable only by creators
  (already enforced by `decideRedirect`; add a route test).

## 11. Success criteria

- Creators see real, current tribe metrics (members, XP, habits, challenges).
- Trends accumulate daily and render as 7/30-day charts once history exists.
- Top members and blueprint/challenge breakdowns are accurate and rules-compliant.
- Offline-first: the tab renders from Drift instantly, refreshes from Firestore.
- The "SOON" placeholder and fake growth rate are gone.
