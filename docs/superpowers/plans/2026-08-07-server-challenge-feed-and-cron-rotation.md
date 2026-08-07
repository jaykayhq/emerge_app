# Server Challenge Feed & Cron Rotation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the app show server-published challenges (images, affiliate links, sponsorship windows) and rotate them daily/weekly via a GitHub Actions cron + Node script — with **zero Firebase scheduled-function invocations**.

**Architecture:** Two coupled parts.
- **Part A (one-time app release):** a pure `mergeChallengeSources()` helper, a `publicChallengesProvider` Firestore stream (rules already allow public read, `firestore.rules:464`), wired into `challengeBundleProvider` + a `challengeById` Firestore fallback + sponsor-field propagation in `getUserChallenges`.
- **Part B (no app release):** a Node rotation package under `scripts/rotation/` (pure `computeRotation()` logic unit-tested with `node:test`, thin Firestore driver using `firebase-admin`), triggered by `.github/workflows/rotate-challenges.yml` on a daily cron. Reuses the existing `FIREBASE_SERVICE_ACCOUNT_TRADEFLASH_L2966` GitHub secret. Also removes the committed `scripts/service-account-key.json`.

**Tech Stack:** Flutter/Riverpod (Part A, `fake_cloud_firestore` already a dev dep, `firestoreProvider` seam exists), Node 22 + `firebase-admin` + `node:test` (Part B), GitHub Actions `on: schedule`.

**Why not scheduled functions:** each scheduled invocation bills; a GitHub Actions cron (free tier) runs the same Admin-SDK writes with no function invocations.

**Spec:** `docs/superpowers/specs/2026-08-07-growth-monetization-gtm-design.md` §6 P1 (affiliate reward card depends on challenges carrying sponsor data).

---

# PART A — App feed unlock

### Task A1: Pure challenge-source merger

**Files:**
- Create: `lib/features/social/domain/services/challenge_feed_merger.dart`
- Test: `test/features/social/domain/services/challenge_feed_merger_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/services/challenge_feed_merger.dart';
import 'package:flutter_test/flutter_test.dart';

Challenge _challenge(String id) {
  return Challenge(
    id: id,
    title: 'Challenge $id',
    description: 'desc',
    imageUrl: '',
    reward: 'Reward',
    participants: 0,
    daysLeft: 7,
    totalDays: 7,
    currentDay: 0,
    status: ChallengeStatus.featured,
    xpReward: 250,
    steps: const [],
    category: ChallengeCategory.fitness,
  );
}

void main() {
  test('server challenges come before catalog challenges', () {
    final merged = mergeChallengeSources(
      server: [_challenge('srv_1')],
      catalog: [_challenge('cat_1')],
    );
    expect(merged.map((c) => c.id).toList(), ['srv_1', 'cat_1']);
  });

  test('server wins on id collision', () {
    final server = _challenge('same');
    final catalog = _challenge('same');
    final merged = mergeChallengeSources(server: [server], catalog: [catalog]);
    expect(merged.length, 1);
    expect(identical(merged.single, server), isTrue);
  });

  test('catalog fills ids missing from server', () {
    final merged = mergeChallengeSources(
      server: [_challenge('srv_1')],
      catalog: [_challenge('srv_1'), _challenge('cat_1')],
    );
    expect(merged.map((c) => c.id).toSet(), {'srv_1', 'cat_1'});
  });

  test('blank server ids are ignored', () {
    final merged = mergeChallengeSources(
      server: [_challenge('')],
      catalog: [_challenge('cat_1')],
    );
    expect(merged.map((c) => c.id).toList(), ['cat_1']);
  });

  test('empty inputs produce empty output', () {
    expect(mergeChallengeSources(server: const [], catalog: const []), isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/domain/services/challenge_feed_merger_test.dart --timeout 120s`
Expected: FAIL — missing `challenge_feed_merger.dart`

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:emerge_app/features/social/domain/models/challenge.dart';

/// Merges server-published challenges ahead of the static catalog, de-duping
/// by id. Server entries win on collision so server rotation is authoritative.
List<Challenge> mergeChallengeSources({
  required List<Challenge> server,
  required List<Challenge> catalog,
}) {
  final byId = <String, Challenge>{};
  for (final c in server) {
    if (c.id.isNotEmpty) byId[c.id] = c;
  }
  for (final c in catalog) {
    byId.putIfAbsent(c.id, () => c);
  }
  return byId.values.toList();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/domain/services/challenge_feed_merger_test.dart --timeout 120s`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/domain/services/challenge_feed_merger.dart test/features/social/domain/services/challenge_feed_merger_test.dart
git commit -m "feat(social): pure challenge source merger"
```

---

### Task A2: `publicChallengesProvider` (Firestore stream)

**Files:**
- Modify: `lib/features/social/presentation/providers/challenge_provider.dart`
- Test: `test/features/social/presentation/providers/public_challenges_provider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('publicChallengesProvider streams live statuses only', () async {
    final fake = FakeFirebaseFirestore();
    await fake.collection('challenges').doc('featured_1').set({
      'title': 'Featured One',
      'description': 'd',
      'imageUrl': '',
      'reward': 'r',
      'participants': 1,
      'daysLeft': 7,
      'totalDays': 7,
      'currentDay': 0,
      'status': 'featured',
      'xpReward': 250,
      'steps': <Map<String, dynamic>>[],
    });
    await fake.collection('challenges').doc('active_1').set({
      'title': 'Active One',
      'description': 'd',
      'imageUrl': '',
      'reward': 'r',
      'participants': 1,
      'daysLeft': 5,
      'totalDays': 7,
      'currentDay': 2,
      'status': 'active',
      'xpReward': 250,
      'steps': <Map<String, dynamic>>[],
    });
    await fake.collection('challenges').doc('completed_1').set({
      'title': 'Done',
      'description': 'd',
      'imageUrl': '',
      'reward': 'r',
      'participants': 1,
      'daysLeft': 0,
      'totalDays': 7,
      'currentDay': 7,
      'status': 'completed',
      'xpReward': 250,
      'steps': <Map<String, dynamic>>[],
    });

    final container = ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final result = await container.read(publicChallengesProvider.future);
    expect(result.map((c) => c.id).toSet(), {'featured_1', 'active_1'});
    expect(result.every((c) => c.status != ChallengeStatus.completed), isTrue);
    expect(result.map((c) => c.title).toSet(), {'Featured One', 'Active One'});
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/providers/public_challenges_provider_test.dart --timeout 120s`
Expected: FAIL — `publicChallengesProvider` not defined

- [ ] **Step 3: Write minimal implementation**

In `lib/features/social/presentation/providers/challenge_provider.dart`, add (the file already imports `firestoreProvider` via `auth_providers.dart` and `Challenge.fromMap`):

```dart
/// Server-published challenge catalog (public read per Firestore rules).
/// Only live statuses are surfaced; expired entries are filtered here so the
/// feed never shows retired challenges.
final publicChallengesProvider =
    StreamProvider.autoDispose<List<Challenge>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('challenges').snapshots().map(
        (snap) => snap.docs
            .where((doc) {
              final status = doc.data()['status'] as String?;
              return status == 'featured' || status == 'active';
            })
            .map((doc) => Challenge.fromMap(doc.data(), id: doc.id))
            .toList(),
      );
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/providers/public_challenges_provider_test.dart --timeout 120s`
Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/providers/challenge_provider.dart test/features/social/presentation/providers/public_challenges_provider_test.dart
git commit -m "feat(social): stream server-published challenges into the feed"
```

---

### Task A3: Wire the server feed into the bundle + detail lookup

**Files:**
- Modify: `lib/features/social/presentation/providers/challenge_bundle_provider.dart`
- Modify: `lib/features/social/presentation/providers/challenge_provider.dart`
- Test: `test/features/social/presentation/providers/challenge_bundle_provider_test.dart`
- Test: `test/features/social/presentation/providers/public_challenges_provider_test.dart`

- [ ] **Step 1: Write the failing test**

1a. In `test/features/social/presentation/providers/challenge_bundle_provider_test.dart`, add the fake-firestore import and a `firestoreProvider` override, so the bundle's new `publicChallengesProvider` watch is hermetic:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
```

```dart
      final container = ProviderContainer(
        overrides: [
          challengeRepositoryProvider.overrideWithValue(mockRepo),
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
          authStateChangesProvider.overrideWithValue(
            AsyncValue.data(
              const AuthUser(id: 'test', email: 'test@example.com'),
            ),
          ),
          userStatsStreamProvider.overrideWithValue(
            AsyncValue.data(
              const UserProfile(uid: 'test', archetype: UserArchetype.athlete),
            ),
          ),
        ],
      );
```

1b. Append to `test/features/social/presentation/providers/public_challenges_provider_test.dart`:

```dart
import 'package:emerge_app/features/social/domain/services/challenge_feed_merger.dart';
// (add at top)

  test('challengeByIdProvider falls back to Firestore for server challenges',
      () async {
    final fake = FakeFirebaseFirestore();
    await fake.collection('challenges').doc('srv_42').set({
      'title': 'Server Quest',
      'description': 'd',
      'imageUrl': '',
      'reward': 'r',
      'participants': 3,
      'daysLeft': 7,
      'totalDays': 7,
      'currentDay': 0,
      'status': 'featured',
      'xpReward': 250,
      'steps': <Map<String, dynamic>>[],
      'sponsor': 'Nike',
      'isSponsored': true,
      'affiliateUrl': 'https://example.com/reward',
      'rewardDescription': '20% off',
      'affiliateNetwork': 'direct',
    });

    final container = ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final challenge = await container.read(challengeByIdProvider('srv_42').future);
    expect(challenge, isNotNull);
    expect(challenge!.title, 'Server Quest');
    expect(challenge.isSponsored, isTrue);
    expect(challenge.affiliateUrl, 'https://example.com/reward');
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/providers/public_challenges_provider_test.dart --timeout 120s`
Expected: FAIL — `challengeByIdProvider('srv_42')` returns null (catalog has no `srv_42`)

- [ ] **Step 3: Implement the wiring**

3a. In `lib/features/social/presentation/providers/challenge_provider.dart`, replace `challengeByIdProvider`:

```dart
final challengeByIdProvider = FutureProvider.family<Challenge?, String>((
  ref,
  id,
) async {
  final repository = ref.read(challengeRepositoryProvider);
  final catalog = await repository.getChallengeById(id);
  if (catalog != null) return catalog;
  final firestore = ref.read(firestoreProvider);
  final doc = await firestore.collection('challenges').doc(id).get();
  if (!doc.exists) return null;
  return Challenge.fromMap(doc.data()!, id: doc.id);
});
```

3b. In `lib/features/social/presentation/providers/challenge_bundle_provider.dart`:
- Add import: `import 'package:emerge_app/features/social/domain/services/challenge_feed_merger.dart';`
- Inside `build()`, after `final archetypeName = ...`, add:

```dart
    // Server-published challenges merge ahead of the catalog when present;
    // the catalog still renders instantly (offline-first) until the stream
    // emits.
    final serverChallenges =
        ref.watch(publicChallengesProvider).value ?? const <Challenge>[];
```

- Replace the featured merge and archetype merge:

```dart
    final featuredChallenges = mergeChallengeSources(
      server: serverChallenges
          .where((c) => c.status == ChallengeStatus.featured)
          .toList(),
      catalog: await repository.getChallenges(featuredOnly: true),
    );

    return ChallengeBundleData(
      weeklySpotlight: results[0] as Challenge?,
      dailyQuest: results[1] as Challenge?,
      userChallenges: results[2] as List<Challenge>,
      archetypeChallenges: mergeChallengeSources(
        server: serverChallenges
            .where(
              (c) =>
                  c.archetypeId == null ||
                  c.archetypeId == archetypeName,
            )
            .toList(),
        catalog: results[3] as List<Challenge>,
      ),
      featuredChallenges: featuredChallenges,
    );
```

- Remove the now-unused `final featuredChallenges = await repository.getChallenges(...)` block (its logic moved into the merge call above).

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/social/presentation/providers/public_challenges_provider_test.dart test/features/social/presentation/providers/challenge_bundle_provider_test.dart --timeout 120s`
Expected: PASS (bundle provider tests unchanged behavior with empty server stream; new byId fallback test passes)

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/providers/challenge_provider.dart lib/features/social/presentation/providers/challenge_bundle_provider.dart test/features/social/presentation/providers/public_challenges_provider_test.dart test/features/social/presentation/providers/challenge_bundle_provider_test.dart
git commit -m "feat(social): merge server challenges into bundle; firestore detail fallback"
```

---

### Task A4: Propagate sponsor fields in `getUserChallenges`

**Files:**
- Modify: `lib/core/drift_repositories/drift_challenge_repository.dart`
- Test: `test/core/drift_repositories/drift_challenge_repository_test.dart`

Why: the reward card (shipped previously) reads `isSponsored`/`affiliateUrl` off the Challenge; `getUserChallenges` rebuilds joined challenges from Drift progress and currently drops those fields, so the card never shows on joined challenges.

- [ ] **Step 1: Write the failing test**

Add to `test/core/drift_repositories/drift_challenge_repository_test.dart` (uses the file's existing harness: `db`, `mockSyncEngine`, `mockSocialService`, `repository`, `userId`, all set in `setUp`; note `joinChallenge` consults the real static `ChallengeCatalog`, so this test seeds Drift progress directly via the DAO):

```dart
  test('getUserChallenges propagates sponsor fields from the catalog template',
      () async {
    const sponsoredTemplate = Challenge(
      id: 'srv_sponsored',
      title: 'Sponsored Quest',
      description: 'desc',
      imageUrl: '',
      reward: 'Voucher',
      participants: 10,
      daysLeft: 7,
      totalDays: 7,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 250,
      steps: [],
      category: ChallengeCategory.fitness,
      sponsor: 'Nike',
      isSponsored: true,
      affiliateUrl: 'https://example.com/reward',
      rewardDescription: '20% off Nike',
      affiliateNetwork: AffiliateNetwork.direct,
      affiliatePartnerId: 'nike_partner',
    );

    final repoWithLookup = DriftChallengeRepository(
      db,
      LocalGameLoopEngine(),
      mockSyncEngine,
      mockSocialService,
      catalogLookup: (id) => id == 'srv_sponsored' ? sponsoredTemplate : null,
    );

    await db.challengeProgressDao.insertFromData(
      challengeId: 'srv_sponsored',
      userId: userId,
      title: sponsoredTemplate.title,
      attribute: 'vitality',
      totalDays: sponsoredTemplate.totalDays,
      xpReward: sponsoredTemplate.xpReward,
      joinedAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    final challenges = await repoWithLookup.getUserChallenges(userId);
    expect(challenges, hasLength(1));
    final rebuilt = challenges.single;
    expect(rebuilt.isSponsored, isTrue);
    expect(rebuilt.affiliateUrl, 'https://example.com/reward');
    expect(rebuilt.sponsor, 'Nike');
    expect(rebuilt.rewardDescription, '20% off Nike');
    expect(rebuilt.affiliateNetwork, AffiliateNetwork.direct);
    expect(rebuilt.affiliatePartnerId, 'nike_partner');
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/drift_repositories/drift_challenge_repository_test.dart --timeout 120s`
Expected: FAIL — `isSponsored` is false on the rebuilt challenge (constructor has no `catalogLookup` yet, so compile error first; after adding the param without the propagation fix, the sponsor assertions fail)

- [ ] **Step 3: Implement the fix**

In `lib/core/drift_repositories/drift_challenge_repository.dart`:

3a. Add an injectable catalog lookup (defaults to the static catalog) so the propagation is unit-testable — this is the project's standard injected-seam pattern:

```dart
  final AppDatabase _db;
  final LocalGameLoopEngine _engine;
  final EnhancedSyncEngine _syncEngine;
  final SocialActivityService _socialService;
  final Challenge? Function(String id) _catalogLookup;

  DriftChallengeRepository(
    this._db,
    this._engine,
    this._syncEngine,
    this._socialService, {
    Challenge? Function(String id)? catalogLookup,
  }) : _catalogLookup = catalogLookup ?? ChallengeCatalog.getChallengeById;
```

3b. In `getUserChallenges`, replace `ChallengeCatalog.getChallengeById(r.challengeId)` with `_catalogLookup(r.challengeId)` (the file's only remaining direct catalog use in this method).

3c. Extend the rebuilt `Challenge(...)` with the template's sponsor fields:

```dart
        sponsor: template?.sponsor,
        sponsorLogoUrl: template?.sponsorLogoUrl,
        isSponsored: template?.isSponsored ?? false,
        affiliateUrl: template?.affiliateUrl,
        rewardDescription: template?.rewardDescription,
        affiliatePartnerId: template?.affiliatePartnerId,
        affiliateNetwork:
            template?.affiliateNetwork ?? AffiliateNetwork.none,
        commissionRate: template?.commissionRate,
```

(`AffiliateNetwork` is already imported in this file via the challenge model import.)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/drift_repositories/drift_challenge_repository_test.dart --timeout 120s`
Expected: PASS (all tests incl. new one)

- [ ] **Step 5: Commit**

```bash
git add lib/core/drift_repositories/drift_challenge_repository.dart test/core/drift_repositories/drift_challenge_repository_test.dart
git commit -m "fix(social): joined challenges keep sponsor and affiliate fields"
```

> **Known limitation (noted, not fixed here):** sponsor fields for **server-authored** (non-catalog) challenges are not persisted in the Drift progress row, so their metadata still won't survive a join. A future task should persist sponsor/affiliate fields in the `challenge_progress` table. Catalog-sponsored challenges are fully fixed by this task.

---

# PART B — Cron rotation via GitHub Actions (no scheduled functions)

### Task B1: Rotation package — pure logic + node tests

**Files:**
- Create: `scripts/rotation/package.json`
- Create: `scripts/rotation/templates.js`
- Create: `scripts/rotation/lib/rotation.js`
- Test: `scripts/rotation/test/rotation.test.js`

- [ ] **Step 1: Write the failing node tests**

Create `scripts/rotation/test/rotation.test.js`:

```js
"use strict";

const { test } = require("node:test");
const assert = require("node:assert/strict");
const { computeRotation } = require("../lib/rotation");

const NOW = new Date("2026-08-10T00:00:00Z"); // a Monday

const template = (id, overrides = {}) => ({
  id,
  title: `Quest ${id}`,
  description: "d",
  category: "fitness",
  archetypeId: "athlete",
  totalDays: 30,
  xpReward: 1000,
  reward: "Exclusive reward",
  imageUrl: "https://img.example/fallback.jpg",
  rewardDescription: "20% off",
  partnerId: "nike",
  steps: [{ day: 1, title: "Start", description: "Go", isCompleted: false }],
  ...overrides,
});

const partner = (id, overrides = {}) => ({
  id,
  name: "Nike",
  logoUrl: "https://img.example/nike.jpg",
  category: "fitness",
  network: "direct",
  commissionRate: 0.1,
  affiliateUrl: "https://partner.example/reward",
  ...overrides,
});

const existing = (id, overrides = {}) => ({
  id,
  title: "Old",
  status: "featured",
  participants: 5,
  sponsorshipEndDate: "2099-01-01T00:00:00Z",
  ...overrides,
});

test("expires challenges whose sponsorship window has ended", () => {
  const plan = computeRotation({
    templates: [],
    existing: [
      existing("a", { sponsorshipEndDate: "2020-01-01T00:00:00Z" }),
      existing("b", { status: "completed", sponsorshipEndDate: "2020-01-01T00:00:00Z" }),
      existing("c", {}),
    ],
    partners: [],
    config: { enabled: true, featuredLimit: 3, imagePool: [] },
    now: NOW,
  });
  assert.deepEqual(plan.updates.filter((u) => u.update.status === "completed").map((u) => u.id), ["a"]);
});

test("upserts templates that do not exist yet, with partner affiliate fields", () => {
  const plan = computeRotation({
    templates: [template("q1")],
    existing: [],
    partners: [partner("nike")],
    config: { enabled: true, featuredLimit: 1, imagePool: [] },
    now: NOW,
  });
  assert.equal(plan.upserts.length, 1);
  const doc = plan.upserts[0].challenge;
  assert.equal(doc.id, "q1");
  assert.equal(doc.status, "featured");
  assert.equal(doc.isSponsored, true);
  assert.equal(doc.affiliateUrl, "https://partner.example/reward");
  assert.equal(doc.sponsor, "Nike");
  assert.equal(doc.affiliateNetwork, "direct");
  assert.equal(doc.imageUrl, "https://img.example/fallback.jpg");
});

test("honours featuredLimit; excess templates stay active", () => {
  const plan = computeRotation({
    templates: [template("q1"), template("q2"), template("q3")],
    existing: [],
    partners: [],
    config: { enabled: true, featuredLimit: 2, imagePool: [] },
    now: NOW,
  });
  assert.equal(plan.upserts.length, 3);
  assert.deepEqual(plan.upserts.map((u) => u.challenge.status), ["featured", "featured", "active"]);
});

test("rotates imageUrl per week from the image pool", () => {
  const pool = ["https://img.example/1.jpg", "https://img.example/2.jpg"];
  const monday = new Date("2026-08-10T00:00:00Z");
  const nextMonday = new Date("2026-08-17T00:00:00Z");
  const planA = computeRotation({
    templates: [template("q1")],
    existing: [],
    partners: [],
    config: { enabled: true, featuredLimit: 1, imagePool: pool },
    now: monday,
  });
  const planB = computeRotation({
    templates: [template("q1")],
    existing: [],
    partners: [],
    config: { enabled: true, featuredLimit: 1, imagePool: pool },
    now: nextMonday,
  });
  assert.equal(planA.upserts[0].challenge.imageUrl, "https://img.example/1.jpg");
  assert.equal(planB.upserts[0].challenge.imageUrl, "https://img.example/2.jpg");
});

test("skips writes when an existing doc is already up to date", () => {
  const same = existing("q1", {
    status: "featured",
    imageUrl: "https://img.example/fallback.jpg",
  });
  const plan = computeRotation({
    templates: [template("q1")],
    existing: [same],
    partners: [],
    config: { enabled: true, featuredLimit: 1, imagePool: [] },
    now: NOW,
  });
  assert.equal(plan.updates.length, 0);
  assert.equal(plan.upserts.length, 0);
});

test("disabled config produces no operations", () => {
  const plan = computeRotation({
    templates: [template("q1")],
    existing: [],
    partners: [],
    config: { enabled: false, featuredLimit: 1, imagePool: [] },
    now: NOW,
  });
  assert.equal(plan.upserts.length, 0);
  assert.equal(plan.updates.length, 0);
  assert.equal(plan.notifyIds.length, 0);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test scripts/rotation/test/rotation.test.js`
Expected: FAIL — `Cannot find module '../lib/rotation'`

- [ ] **Step 3: Write minimal implementation**

Create `scripts/rotation/lib/rotation.js`:

```js
"use strict";

/**
 * Pure rotation decisions. No Firestore/admin imports — all inputs and outputs
 * are plain objects so the logic is unit-testable with node:test.
 */

const VISIBLE_STATUSES = new Set(["featured", "active"]);
const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

/** Whole weeks since epoch — the deterministic image-rotation bucket. */
function weekIndex(now) {
  return Math.floor(now.getTime() / WEEK_MS);
}

/** Challenge ids whose sponsorship window has ended and are still visible. */
function computeExpiredIds(challenges, now) {
  return challenges
    .filter((c) => VISIBLE_STATUSES.has(c.status))
    .filter((c) => {
      if (!c.sponsorshipEndDate) return false;
      const end = new Date(c.sponsorshipEndDate);
      return !Number.isNaN(end.getTime()) && end <= now;
    })
    .map((c) => c.id);
}

function pickImage(template, imagePool, week, index) {
  if (imagePool.length > 0) return imagePool[(week + index) % imagePool.length];
  return template.imageUrl;
}

/**
 * Computes the rotation plan.
 *
 * @param {object} opts
 * @param {Array<object>} opts.templates  curated template pool
 * @param {Array<object>} opts.existing   existing `challenges` docs (id + data)
 * @param {Array<object>} opts.partners   `affiliatePartners` docs (id + data)
 * @param {object} opts.config            { featuredLimit, imagePool, enabled }
 * @param {Date} opts.now
 * @returns {{upserts: Array<{challenge: object}>, updates: Array<{id: string, update: object}>, notifyIds: string[]}}
 */
function computeRotation({ templates, existing, partners, config, now }) {
  const upserts = [];
  const updates = [];
  const notifyIds = [];

  if (!config.enabled) return { upserts, updates, notifyIds };

  const expired = new Set(computeExpiredIds(existing, now));
  const existingById = new Map(existing.map((c) => [c.id, c]));
  const featuredLimit = Math.max(1, config.featuredLimit ?? 3);
  const imagePool = config.imagePool ?? [];
  const week = weekIndex(now);

  for (const id of expired) {
    updates.push({ id, update: { status: "completed" } });
  }

  templates.forEach((template, index) => {
    const partner = partners.find((p) => p.id === template.partnerId);
    const isFeatured = index < featuredLimit;
    const imageUrl = pickImage(template, imagePool, week, index);

    const doc = {
      title: template.title,
      description: template.description,
      imageUrl,
      category: template.category,
      archetypeId: template.archetypeId,
      totalDays: template.totalDays,
      currentDay: 0,
      daysLeft: template.totalDays,
      participants: existingById.get(template.id)?.participants ?? 0,
      status: isFeatured ? "featured" : "active",
      xpReward: template.xpReward,
      reward: template.reward,
      isFeatured,
      isTeamChallenge: false,
      buddyValidationRequired: false,
      sponsor: partner?.name ?? template.sponsor,
      sponsorLogoUrl: partner?.logoUrl ?? template.sponsorLogoUrl ?? "",
      isSponsored: Boolean(partner),
      affiliateUrl: partner?.affiliateUrl ?? template.affiliateUrl ?? "",
      rewardDescription: template.rewardDescription ?? template.reward,
      affiliatePartnerId: partner?.id ?? template.partnerId ?? null,
      affiliateNetwork: partner?.network ?? template.affiliateNetwork ?? "none",
      commissionRate: partner?.commissionRate ?? template.commissionRate ?? null,
      sponsorshipStartDate: now.toISOString(),
      sponsorshipEndDate: new Date(
        now.getTime() + template.totalDays * 24 * 60 * 60 * 1000
      ).toISOString(),
      steps: template.steps,
    };

    const existingDoc = existingById.get(template.id);
    if (
      existingDoc &&
      existingDoc.status === doc.status &&
      existingDoc.imageUrl === doc.imageUrl &&
      existingDoc.affiliateUrl === doc.affiliateUrl
    ) {
      // No visible change — skip the write entirely (billing/cost).
      return;
    }
    if (existingDoc) {
      doc.participants = existingDoc.participants ?? doc.participants;
      updates.push({ id: template.id, update: doc });
      if (isFeatured && existingDoc.status !== "featured") notifyIds.push(template.id);
    } else {
      upserts.push({ challenge: { id: template.id, ...doc } });
      if (isFeatured) notifyIds.push(template.id);
    }
  });

  return { upserts, updates, notifyIds };
}

module.exports = { computeRotation, computeExpiredIds, weekIndex };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test scripts/rotation/test/rotation.test.js`
Expected: PASS (7 tests)

- [ ] **Step 5: Create `scripts/rotation/package.json` and commit**

```json
{
  "name": "emerge-challenge-rotation",
  "private": true,
  "version": "1.0.0",
  "description": "GitHub Actions cron: rotate server-published challenges in Firestore without scheduled functions",
  "main": "index.js",
  "scripts": {
    "test": "node --test scripts/rotation/test/"
  },
  "dependencies": {
    "firebase-admin": "^13.10.0"
  }
}
```

Run: `npm --prefix scripts/rotation install --package-lock-only` (generates the lockfile the workflow needs; requires network — if offline, note the lockfile will be produced on first CI run).

```bash
git add scripts/rotation/package.json scripts/rotation/package-lock.json scripts/rotation/lib/rotation.js scripts/rotation/templates.js scripts/rotation/test/rotation.test.js
git commit -m "feat(cron): pure challenge rotation logic with node tests"
```

(`templates.js` is created in Task B2; if Task B2 isn't done yet, create an empty `module.exports = { TEMPLATES: [] };` placeholder so `rotation.js` tests run, then fill it in B2.)

---

### Task B2: Template pool, driver, and GitHub Actions workflow

**Files:**
- Create: `scripts/rotation/templates.js`
- Create: `scripts/rotation/index.js`
- Create: `.github/workflows/rotate-challenges.yml`

- [ ] **Step 1: Create the template pool**

Create `scripts/rotation/templates.js` — curated templates; `partnerId` links to `affiliatePartners` docs (id must match a doc in that collection); `affiliateUrl` is a **real** URL fallback used when the partner doc lacks one (this fixes the quarterly function's `affiliateUrl: partnerId` bug — never point it at a doc ID):

```js
"use strict";

/**
 * Curated server-published challenge templates.
 *
 * The rotation driver upserts these into the `challenges` collection. To change
 * a challenge's title/reward/links/images, edit this file (or better: the
 * `config/challengeRotation` doc's imagePool) — no app release required.
 *
 * `partnerId` must match a doc id in the `affiliatePartners` collection; the
 * driver copies the partner's name/logo/network/commission/affiliateUrl over
 * the template fields when present.
 */
const TEMPLATES = [
  {
    id: "srv_morning_protocol",
    title: "The Morning Protocol",
    description:
      "14 days of a non-negotiable morning routine: hydrate, move, and set one intention before screens.",
    category: "productivity",
    archetypeId: "athlete",
    totalDays: 14,
    xpReward: 700,
    reward: "700 XP & Morning Warrior Emblem",
    rewardDescription: "15% off your first order",
    imageUrl:
      "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800",
    partnerId: "headspace",
    affiliateNetwork: "direct",
    affiliateUrl: "https://example.com/reward/headspace",
    steps: [
      { day: 1, title: "Hydrate First", description: "500ml water before coffee.", isCompleted: false },
      { day: 7, title: "One Week In", description: "Your routine is taking shape.", isCompleted: false },
      { day: 14, title: "Protocol Locked", description: "Own your mornings.", isCompleted: false },
    ],
  },
  {
    id: "srv_read_20",
    title: "Read 20",
    description:
      "20 minutes of reading a day for 21 days. Become the reader you keep saying you will.",
    category: "learning",
    archetypeId: "scholar",
    totalDays: 21,
    xpReward: 900,
    reward: "900 XP & Reader's Quill",
    rewardDescription: "30 days free on us",
    imageUrl:
      "https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=800",
    partnerId: "audible",
    affiliateNetwork: "direct",
    affiliateUrl: "https://example.com/reward/audible",
    steps: [
      { day: 1, title: "Start Small", description: "20 minutes, one book.", isCompleted: false },
      { day: 10, title: "Halfway", description: "You are a reader now.", isCompleted: false },
      { day: 21, title: "Reader", description: "21 days of pages.", isCompleted: false },
    ],
  },
  {
    id: "srv_30_day_move",
    title: "30 Days of Movement",
    description:
      "Move your body every single day for 30 days. Walk, run, stretch — just move.",
    category: "fitness",
    archetypeId: "athlete",
    totalDays: 30,
    xpReward: 1200,
    reward: "1200 XP & Golden Running Shoes",
    rewardDescription: "20% off your next pair",
    imageUrl:
      "https://images.unsplash.com/photo-1552664730-d307ca884978?w=800",
    partnerId: "nike",
    affiliateNetwork: "direct",
    affiliateUrl: "https://example.com/reward/nike",
    steps: [
      { day: 1, title: "Show Up", description: "10 minutes counts.", isCompleted: false },
      { day: 15, title: "Halfway", description: "Fifteen in a row.", isCompleted: false },
      { day: 30, title: "Movement Day 30", description: "You moved for a month.", isCompleted: false },
    ],
  },
];

module.exports = { TEMPLATES };
```

- [ ] **Step 2: Create the driver**

Create `scripts/rotation/index.js` (mirrors `scripts/seed_onboarding_catalog.js` — Admin SDK reads `GOOGLE_APPLICATION_CREDENTIALS` set by the GitHub Actions auth step):

```js
"use strict";

/**
 * Rotation driver: reads config + partners + existing challenges from
 * Firestore, computes the plan with the pure logic in lib/rotation.js, applies
 * it with batched writes, and pushes an FCM topic notification for newly
 * featured challenges. Triggered by the daily GitHub Actions cron.
 *
 * Run locally:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json \
 *     node scripts/rotation/index.js
 */
const admin = require("firebase-admin");
const { computeRotation } = require("./lib/rotation");
const { TEMPLATES } = require("./templates");

async function main() {
  if (admin.apps.length === 0) {
    admin.initializeApp();
  }
  const db = admin.firestore();
  const now = new Date();

  const configDoc = await db
    .collection("config")
    .doc("challengeRotation")
    .get()
    .catch(() => null);
  const config = configDoc?.exists
    ? configDoc.data()
    : { enabled: true, featuredLimit: 3, imagePool: [] };

  const partnersSnap = await db
    .collection("affiliatePartners")
    .get()
    .catch(() => null);
  const partners =
    partnersSnap?.docs.map((d) => ({ id: d.id, ...d.data() })) ?? [];

  const existingSnap = await db.collection("challenges").get();
  const existing = existingSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

  const plan = computeRotation({
    templates: TEMPLATES,
    existing,
    partners,
    config,
    now,
  });

  const toTimestamp = (iso) =>
    admin.firestore.Timestamp.fromDate(new Date(iso));

  for (const { challenge } of plan.upserts) {
    const { id, sponsorshipStartDate, sponsorshipEndDate, ...rest } = challenge;
    await db.collection("challenges").doc(id).set({
      ...rest,
      sponsorshipStartDate: toTimestamp(sponsorshipStartDate),
      sponsorshipEndDate: toTimestamp(sponsorshipEndDate),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  const batch = db.batch();
  for (const { id, update } of plan.updates) {
    const { sponsorshipStartDate, sponsorshipEndDate, ...rest } = update;
    batch.update(db.collection("challenges").doc(id), {
      ...rest,
      ...(sponsorshipStartDate
        ? { sponsorshipStartDate: toTimestamp(sponsorshipStartDate) }
        : {}),
      ...(sponsorshipEndDate
        ? { sponsorshipEndDate: toTimestamp(sponsorshipEndDate) }
        : {}),
    });
  }
  if (plan.updates.length > 0) await batch.commit();

  for (const id of plan.notifyIds) {
    const t = TEMPLATES.find((x) => x.id === id);
    if (t) {
      await admin.messaging().send({
        notification: { title: "New featured challenge", body: t.title },
        data: { challengeId: id, type: "challenge_rotation" },
        topic: "all_users",
      });
    }
  }

  await db.collection("analytics").add({
    event: "challenge_rotation_completed",
    upserts: plan.upserts.length,
    updates: plan.updates.length,
    notified: plan.notifyIds.length,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(
    `Rotation done: ${plan.upserts.length} upserts, ${plan.updates.length} updates, ${plan.notifyIds.length} notified`
  );
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
```

- [ ] **Step 3: Create the workflow**

Create `.github/workflows/rotate-challenges.yml`:

```yaml
name: Rotate challenges (daily cron)

on:
  schedule:
    - cron: "0 6 * * *" # 06:00 UTC daily
  workflow_dispatch: {} # manual "Run workflow" button

jobs:
  rotate:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
          cache-dependency-path: scripts/rotation/package-lock.json

      - name: Authenticate to Firebase
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_TRADEFLASH_L2966 }}

      - name: Install rotation dependencies
        run: npm --prefix scripts/rotation ci

      - name: Run challenge rotation
        run: node scripts/rotation/index.js
```

- [ ] **Step 4: Verify the pure logic still passes**

Run: `node --test scripts/rotation/test/rotation.test.js`
Expected: PASS (7 tests)

- [ ] **Step 5: Commit**

```bash
git add scripts/rotation/ .github/workflows/rotate-challenges.yml
git commit -m "feat(cron): daily challenge rotation driver and GitHub Actions workflow"
```

---

### Task B3: Rotation config guide

**Files:**
- Create: `docs/growth/challenge-rotation.md`

- [ ] **Step 1: Write the guide**

Document:
- What runs when: `0 6 * * *` UTC daily via GitHub Actions; manual trigger via workflow_dispatch.
- How to change rotation **without an app release**: edit the `config/challengeRotation` doc in Firestore:
  ```json
  {
    "enabled": true,
    "featuredLimit": 3,
    "imagePool": ["https://.../img1.jpg", "https://.../img2.jpg", "https://.../img3.jpg"]
  }
  ```
- How to change images/affiliate links per partner: update the `affiliatePartners/{id}` doc fields `logoUrl` and `affiliateUrl`; the next cron run copies them onto the challenge.
- How to run locally: `GOOGLE_APPLICATION_CREDENTIALS=path/to/serviceAccount.json node scripts/rotation/index.js`.
- Billing note: GitHub Actions free-tier cron; zero Firebase function invocations; writes are batched; unchanged challenges are skipped (no-op writes avoided).
- Security note: never commit service account keys (see Task B4).

- [ ] **Step 2: Commit**

```bash
git add docs/growth/challenge-rotation.md
git commit -m "docs(growth): challenge rotation config guide"
```

---

### Task B4: Remove the committed service-account key (security)

**Files:**
- Modify: `.gitignore`
- Delete (from git index): `scripts/service-account-key.json`

**Context:** `scripts/service-account-key.json` is tracked in the repo (`git ls-files` confirms). A committed service-account key grants anyone with repo access Firestore/FCM admin. It must be removed from git history exposure going forward and the key rotated in Google Cloud.

- [ ] **Step 1: Add to `.gitignore`**

Append to `.gitignore`:

```
# Firebase service account keys — never commit
scripts/*service-account*.json
*.service-account.json
```

- [ ] **Step 2: Remove from the index (keep the local file for now)**

```bash
git rm --cached scripts/service-account-key.json
```

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore(security): stop tracking the Firebase service-account key"
```

- [ ] **Step 4: Manual action (documented, performed by the user)**

- Rotate the key in Google Cloud Console (IAM → Service Accounts → the account used by `FIREBASE_SERVICE_ACCOUNT_TRADEFLASH_L2966` → Keys → delete the leaked key, create a new one).
- Update the GitHub secret `FIREBASE_SERVICE_ACCOUNT_TRADEFLASH_L2966` with the new key JSON.
- Optionally purge the old key from git history later (`git filter-repo` / BFG) — a future clean-up, not required for this task.

---

### Task B5: End-to-end verification

**Files:** none (verification + deployment only)

- [ ] **Step 1: Unit verification**

Run: `node --test scripts/rotation/test/rotation.test.js`
Expected: PASS (7 tests)

Run: `flutter test test/features/social/domain/services/challenge_feed_merger_test.dart test/features/social/presentation/providers/public_challenges_provider_test.dart test/features/social/presentation/providers/challenge_bundle_provider_test.dart --timeout 120s`
Expected: PASS

Run: `dart analyze lib/features/social test/features/social`
Expected: `No issues found!`

- [ ] **Step 2: Manual Firestore smoke run (requires a credential; user performs)**

```bash
GOOGLE_APPLICATION_CREDENTIALS=<safe path to a NON-committed service account json> \
  node scripts/rotation/index.js
```

Expected: prints `Rotation done: N upserts, N updates, N notified`; verify a few docs in the `challenges` collection now carry `status`, `imageUrl`, `affiliateUrl`, `sponsor`, `sponsorshipEndDate`.

- [ ] **Step 3: Enable the cron**

Push to `main`; GitHub Actions runs the workflow automatically each day at 06:00 UTC. Confirm the first scheduled run succeeds in the Actions tab (or trigger via workflow_dispatch).

- [ ] **Step 4: Ship Part A with the next app release**

The feed unlock (Tasks A1-A4) ships in the next app release; after that, rotation changes are visible in-app with **no further app updates**.

---

## Notes for the implementer

- **Deployment order:** Part B (Tasks B1-B5) is deployable immediately (push to main → cron). Part A ships with the next app release; until then the rotated challenges exist in Firestore but aren't in the user feed.
- **Do NOT run the full test suite** during development — only the focused files listed. `node --test` for the JS rotation tests, `flutter test <file> --timeout 120s` for Dart.
- **Do NOT run multiple commands at once.**
- **Never `git add -A`** — the working tree has unrelated uncommitted changes; stage only the files each task names.
- **The repo's Firestore rules** already allow public reads on `challenges` (`firestore.rules:464`) — no rules change needed for Part A.
- **Existing scheduled functions** (daily decay, momentum, tribe recalc, quarterly challenges) are unrelated to the new cron; do not modify or deploy functions for this plan. If the user wants, the quarterly `onSchedule` can later be disabled since the script covers rotation — out of scope here.
- **Local alternative:** if GitHub Actions isn't preferred, the same script can run from a system cron on a machine that's always on — but GH Actions is the recommended durable "workspace cron" for this repo.
