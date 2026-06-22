# Dual-Hub Social Section Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the Tribe tab into an explicit dual hub (tribe + friends as peers) with an honest feed destination, a new partner-activity data source (fan-out-on-write), an address-book contacts discovery surface, honest quest labeling, and removal of orphaned dead code.

**Architecture:** The lobby (`TribeLobbyScreen`) becomes a true dual hub. A new `/social/activity` screen receives the previously-misrouted feed links. Partner activity is written via fan-out-on-write into `users/{partnerId}/partner_activity`, hooked into the existing `SocialActivityService` (the single funnel for all activity writes). A new `Your Circle` lobby section gives friends their official home. Quests split into "Your Quests" (active) and "Quests for You" (featured). Contacts = address-book discovery → invite as partner.

**Tech Stack:** Flutter, Riverpod 3.x with code-gen (`@riverpod`), Firestore (`cloud_firestore: ^6.6.0`), Drift (offline-first), `EnhancedSyncEngine` (queued writes), go_router, `mocktail` + `fake_cloud_firestore` (testing).

**Spec:** `docs/superpowers/specs/2026-06-21-dual-hub-social-section-design.md`

**Phases:** This plan is organized into 6 phases. Each phase is independently shippable and produces working, testable software. Phases 1–4 build the core restructure and the new data source. Phase 5 adds the contacts discovery surface. Phase 6 is cleanup (dead code + docs). Execute phases in order; commit after every task.

---

## Key Codebase Idioms (match these exactly)

These patterns are verified against the existing code. Copy them, do not invent variants.

**Repository (abstract + Firestore impl):**
```dart
abstract class XRepository { /* plain methods, Future/Stream */ }

class FirestoreXRepository implements XRepository {
  final FirebaseFirestore _firestore;
  FirestoreXRepository(this._firestore);
  // reads via chained .collection('users').doc(uid).collection('x').snapshots()
  // writes via _firestore.batch() ... await batch.commit()
}
```

**Provider for repo + stream provider:**
```dart
final xRepositoryProvider = Provider<XRepository>((ref) {
  return FirestoreXRepository(FirebaseFirestore.instance);
});

final xListProvider = StreamProvider.autoDispose<List<T>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);
  final repository = ref.watch(xRepositoryProvider);
  return repository.watchX(user.id);
});
```

**Current user id:** `final user = ref.watch(authStateChangesProvider).value;` then `user.id`. No other provider.

**Sync engine writes:** `await _syncEngine.enqueueSet(collectionPath: 'path', documentId: id, data: {...});`. The class is `EnhancedSyncEngine` (from `package:emerge_app/core/sync/sync_engine_barrel.dart`).

**Activity shape (untyped):** feeds are `List<Map<String, dynamic>>`. Fields: `id, type, userId, userName, data, timestamp`. `type` is a string like `'habit_complete'`.

**Entity:** `const` constructor with named params + `factory T.fromMap(Map<String,dynamic>)` + `Map<String,dynamic> toMap()`. No freezed/json_serializable.

**Router full-screen route:** `GoRoute(path: 'x', parentNavigatorKey: _rootNavigatorKey, builder: ...)`. Tab-local routes omit `parentNavigatorKey`.

**Test pump cadence:** `tester.pumpWidget(...)` → `tester.pump()` → `tester.pump(const Duration(milliseconds: 50))`. Avoid `pumpAndSettle` except after navigation taps.

**Generate Riverpod code:** run `dart run build_runner build --delete-conflicting-outputs` after editing any `@riverpod`-annotated function. Generated accessors are named `<functionName>Provider`.

---

## File Structure

**Create:**
| File | Responsibility |
|------|----------------|
| `lib/features/social/domain/repositories/partner_activity_repository.dart` | Abstract `PartnerActivityRepository` + Firestore impl `FirestorePartnerActivityRepository` |
| `lib/features/social/presentation/providers/partner_activity_provider.dart` | `partnerActivityRepositoryProvider`, `partnerActivityProvider` stream |
| `lib/features/social/presentation/screens/social_activity_screen.dart` | Two-tab activity screen at `/social/activity` |
| `lib/features/social/presentation/widgets/tribe_circle_section.dart` | Lobby "Your Circle" partners section |
| `lib/features/social/presentation/widgets/tribe_your_quests_section.dart` | Active-only quests section |
| `lib/features/social/presentation/widgets/tribe_quests_for_you_section.dart` | Featured-only quests section |
| `lib/features/social/presentation/screens/social_contacts_screen.dart` | Address-book contacts discovery screen |
| `lib/features/social/domain/services/contact_resolver.dart` | Contact phone/email → user lookup |

**Modify:**
| File | Change |
|------|--------|
| `lib/features/social/domain/services/club_activity_service.dart` | Add `PartnerLookup` callback param; add partner fan-out writes to each `logX` |
| `lib/features/social/presentation/providers/tribes_provider.dart` | Update `socialActivityServiceProvider` to pass partner-lookup callback |
| `lib/features/social/presentation/widgets/tribe_live_compact.dart` | Repoint "View More" → `/social/activity` |
| `lib/features/social/presentation/widgets/tribe_pulse_status_row.dart` | Repoint LIVE chip → `/social/activity` |
| `lib/features/social/presentation/screens/tribe_lobby_screen.dart` | New sliver order: insert Circle section, split quests |
| `lib/core/router/router.dart` | Register `/social/activity`, `/social/contacts` |
| `lib/features/social/presentation/screens/friends_screen.dart` | Add "Add from contacts" entry |
| `pubspec.yaml` | Add `permission_handler`, `fast_contacts` |

**Delete:**
| File | Reason |
|------|--------|
| `lib/features/social/presentation/screens/tribe_tab_content.dart` | Orphaned; references nonexistent `CommunityScreen`/`TribesScreen` |
| `lib/features/social/presentation/widgets/tribe_accountability_section.dart` | Superseded by `tribe_circle_section.dart` |
| `lib/features/social/presentation/widgets/tribe_active_quests_section.dart` | Superseded by the two split widgets |
| `lib/features/social/presentation/screens/accountability_screen.dart` | Hardcoded fake names; never routed |

---

## Phase 1: Quest Honesty Split (no backend changes)

Splits the lying "ACTIVE QUESTS" widget into two honest sections. Zero backend work — pure widget extraction from existing providers. Shippable on its own.

### Task 1.1: Create `TribeYourQuestsSection` (active only)

**Files:**
- Create: `lib/features/social/presentation/widgets/tribe_your_quests_section.dart`
- Test: `test/features/social/presentation/widgets/tribe_your_quests_section_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/social/presentation/widgets/tribe_your_quests_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_your_quests_section.dart';

Challenge _challenge({
  required String id,
  required String title,
  required int currentDay,
  required ChallengeStatus status,
}) =>
    Challenge(
      id: id,
      title: title,
      description: '',
      imageUrl: '',
      reward: '',
      participants: 0,
      daysLeft: 0,
      totalDays: 30,
      currentDay: currentDay,
      status: status,
      xpReward: 0,
      steps: const [],
    );

Widget buildTest({
  List<Challenge>? userChallenges,
  Future<List<Challenge>>? userChallengesAsync,
}) {
  return ProviderScope(
    overrides: [
      userChallengesProvider.overrideWith(
        (ref) =>
            userChallengesAsync ?? Future.value(userChallenges ?? <Challenge>[]),
      ),
    ],
    child: MaterialApp(
      home: const Scaffold(body: TribeYourQuestsSection()),
    ),
  );
}

void main() {
  testWidgets('header reads YOUR QUESTS', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('YOUR QUESTS'), findsOneWidget);
  });

  testWidgets('renders only active challenges, excludes completed/featured',
      (tester) async {
    await tester.pumpWidget(buildTest(userChallenges: [
      _challenge(
          id: 'a1', title: 'Active One', currentDay: 5, status: ChallengeStatus.active),
      _challenge(
          id: 'c1',
          title: 'Completed One',
          currentDay: 30,
          status: ChallengeStatus.completed),
    ]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Active One'), findsOneWidget);
    expect(find.text('Completed One'), findsNothing);
  });

  testWidgets('empty state prompts to pick one below', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('No quests in progress'), findsOneWidget);
  });

  testWidgets('shows loading indicator while pending', (tester) async {
    await tester.pumpWidget(
      buildTest(userChallengesAsync: Future.value(const <Challenge>[]).then((_) => const [].first)),
    );
    await tester.pump();
    // While the future has not completed, a spinner is shown.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/widgets/tribe_your_quests_section_test.dart`
Expected: FAIL — `tribe_your_quests_section.dart` does not exist (import error / Target of URI doesn't exist).

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/social/presentation/widgets/tribe_your_quests_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';

/// Quests the user has joined and is currently progressing.
/// Reads only [userChallengesProvider] filtered to
/// [ChallengeStatus.active]. Featured/available quests live in
/// [TribeQuestsForYouSection].
class TribeYourQuestsSection extends ConsumerWidget {
  const TribeYourQuestsSection({super.key});

  static IconData iconFor(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.fitness:
        return Icons.directions_run;
      case ChallengeCategory.mindfulness:
        return Icons.self_improvement;
      case ChallengeCategory.learning:
        return Icons.menu_book;
      case ChallengeCategory.productivity:
        return Icons.bolt;
      case ChallengeCategory.creative:
        return Icons.palette;
      case ChallengeCategory.faith:
        return Icons.auto_awesome;
      case ChallengeCategory.nutrition:
        return Icons.restaurant;
      case ChallengeCategory.all:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(userChallengesProvider);

    final List<Challenge> active =
        challengesAsync.value?.where((c) => c.status == ChallengeStatus.active).toList() ??
            <Challenge>[];

    active.sort((a, b) => b.currentDay.compareTo(a.currentDay));
    final top = active.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              const Text(
                'YOUR QUESTS',
                style: TextStyle(
                  color: EmergeColors.nebulaPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/social/challenges'),
                child: const Text(
                  'View All →',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (challengesAsync.isLoading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (top.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'No quests in progress — pick one below.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          )
        else
          Column(
            children: List.generate(top.length, (i) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _QuestRow(challenge: top[i]),
              );
            }),
          ),
      ],
    );
  }
}

class _QuestRow extends StatelessWidget {
  final Challenge challenge;
  const _QuestRow({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final progress = challenge.totalDays == 0
        ? 0.0
        : (challenge.currentDay / challenge.totalDays).clamp(0.0, 1.0);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/social/challenge/${challenge.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: EmergeColors.nebulaCtaGradient,
              ),
              alignment: Alignment.center,
              child: Icon(
                TribeYourQuestsSection.iconFor(challenge.category),
                color: Colors.black,
                size: 20,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    'Day ${challenge.currentDay}/${challenge.totalDays}',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const Gap(6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        EmergeColors.nebulaPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(8),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/widgets/tribe_your_quests_section_test.dart`
Expected: PASS — all 4 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/widgets/tribe_your_quests_section.dart test/features/social/presentation/widgets/tribe_your_quests_section_test.dart
git commit -m "feat(social): add TribeYourQuestsSection for active-only quests"
```

---

### Task 1.2: Create `TribeQuestsForYouSection` (featured only)

**Files:**
- Create: `lib/features/social/presentation/widgets/tribe_quests_for_you_section.dart`
- Test: `test/features/social/presentation/widgets/tribe_quests_for_you_section_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/social/presentation/widgets/tribe_quests_for_you_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_quests_for_you_section.dart';

Challenge _challenge({
  required String id,
  required String title,
  required int currentDay,
}) =>
    Challenge(
      id: id,
      title: title,
      description: '',
      imageUrl: '',
      reward: '',
      participants: 0,
      daysLeft: 0,
      totalDays: 30,
      currentDay: currentDay,
      status: ChallengeStatus.featured,
      xpReward: 0,
      steps: const [],
    );

Widget buildTest({Challenge? daily, Challenge? weekly}) {
  return ProviderScope(
    overrides: [
      dailyQuestFromBundleProvider.overrideWith((ref) => daily),
      weeklySpotlightFromBundleProvider.overrideWith((ref) => weekly),
    ],
    child: MaterialApp(
      home: const Scaffold(body: TribeQuestsForYouSection()),
    ),
  );
}

void main() {
  testWidgets('header reads QUESTS FOR YOU', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('QUESTS FOR YOU'), findsOneWidget);
  });

  testWidgets('renders daily and weekly featured quests', (tester) async {
    await tester.pumpWidget(buildTest(
      daily: _challenge(id: 'd1', title: 'Daily Quest', currentDay: 0),
      weekly: _challenge(id: 'w1', title: 'Weekly Spotlight', currentDay: 0),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Daily Quest'), findsOneWidget);
    expect(find.text('Weekly Spotlight'), findsOneWidget);
  });

  testWidgets('empty state when both null', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('No featured quests right now'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/widgets/tribe_quests_for_you_section_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/social/presentation/widgets/tribe_quests_for_you_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';

/// Featured quests available to join — the daily quest and weekly spotlight.
/// These are NOT active; they come from the static catalog with
/// [ChallengeStatus.featured]. Joined/active quests live in
/// [TribeYourQuestsSection].
class TribeQuestsForYouSection extends ConsumerWidget {
  const TribeQuestsForYouSection({super.key});

  static IconData iconFor(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.fitness:
        return Icons.directions_run;
      case ChallengeCategory.mindfulness:
        return Icons.self_improvement;
      case ChallengeCategory.learning:
        return Icons.menu_book;
      case ChallengeCategory.productivity:
        return Icons.bolt;
      case ChallengeCategory.creative:
        return Icons.palette;
      case ChallengeCategory.faith:
        return Icons.auto_awesome;
      case ChallengeCategory.nutrition:
        return Icons.restaurant;
      case ChallengeCategory.all:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyQuestFromBundleProvider);
    final weekly = ref.watch(weeklySpotlightFromBundleProvider);

    final pool = <Challenge>[
      ?daily,
      ?weekly,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: const Text(
            'QUESTS FOR YOU',
            style: TextStyle(
              color: EmergeColors.nebulaPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        if (pool.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'No featured quests right now.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          )
        else
          Column(
            children: List.generate(pool.length, (i) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _QuestRow(challenge: pool[i]),
              );
            }),
          ),
      ],
    );
  }
}

class _QuestRow extends StatelessWidget {
  final Challenge challenge;
  const _QuestRow({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/social/challenge/${challenge.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: EmergeColors.nebulaCtaGradient,
              ),
              alignment: Alignment.center,
              child: Icon(
                TribeQuestsForYouSection.iconFor(challenge.category),
                color: Colors.black,
                size: 20,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    '${challenge.totalDays}-day quest · Tap to join',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Gap(8),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/widgets/tribe_quests_for_you_section_test.dart`
Expected: PASS — all 3 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/widgets/tribe_quests_for_you_section.dart test/features/social/presentation/widgets/tribe_quests_for_you_section_test.dart
git commit -m "feat(social): add TribeQuestsForYouSection for featured quests"
```

---

## Phase 2: Honest Feed Destination

Creates the `/social/activity` screen and repoints the two misrouted feed links to it. The Partners tab is created empty here and wired up in Phase 3 (which builds the data source).

### Task 2.1: Create `SocialActivityScreen` shell with Tribe tab

**Files:**
- Create: `lib/features/social/presentation/screens/social_activity_screen.dart`
- Test: `test/features/social/presentation/screens/social_activity_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/social/presentation/screens/social_activity_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/social_activity_screen.dart';

Widget buildTest({String? tribeId}) {
  return ProviderScope(
    overrides: [
      clubActivityProvider.overrideWith((ref, arg) => Stream.value([
            {
              'id': 'e1',
              'type': 'habit_complete',
              'userName': 'Alex',
              'data': {'habitTitle': 'Cold Plunge'},
              'timestamp': DateTime.now().toUtc().toIso8601String(),
            },
          ])),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => SocialActivityScreen(tribeId: tribeId ?? 'morning_warriors'),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('renders Tribe tab and Partners tab headers', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('TRIBE'), findsOneWidget);
    expect(find.text('PARTNERS'), findsOneWidget);
  });

  testWidgets('Tribe tab shows club activity entries', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Alex'), findsOneWidget);
    expect(find.textContaining('Cold Plunge'), findsOneWidget);
  });

  testWidgets('Partners tab empty state prompts to add partner', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('PARTNERS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Find a partner'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/screens/social_activity_screen_test.dart`
Expected: FAIL — `social_activity_screen.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/social/presentation/screens/social_activity_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/presentation/providers/partner_activity_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

/// Honest destination for the live feed. Two tabs:
/// - Tribe:   full club activity feed (paginated, club-scoped)
/// - Partners: live partner-activity events (new data source)
///
/// Replaces the previous routing where the feed's "View More" wrongly
/// opened the partner-management screen.
class SocialActivityScreen extends ConsumerStatefulWidget {
  final String tribeId;
  const SocialActivityScreen({super.key, required this.tribeId});

  @override
  ConsumerState<SocialActivityScreen> createState() =>
      _SocialActivityScreenState();
}

class _SocialActivityScreenState extends ConsumerState<SocialActivityScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ACTIVITY'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _SegmentedTabs(
            current: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const Gap(12),
          Expanded(
            child: _tab == 0
                ? _TribeFeed(tribeId: widget.tribeId)
                : const _PartnersFeed(),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  const _SegmentedTabs({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _TabButton(label: 'TRIBE', selected: current == 0, onTap: () => onChanged(0))),
          const Gap(8),
          Expanded(child: _TabButton(label: 'PARTNERS', selected: current == 1, onTap: () => onChanged(1))),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? EmergeColors.nebulaPrimary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? EmergeColors.nebulaPrimary : Colors.white24,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TribeFeed extends ConsumerWidget {
  final String tribeId;
  const _TribeFeed({required this.tribeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(clubActivityProvider(tribeId));
    return activityAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Could not load activity.', style: TextStyle(color: Colors.white54))),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Text(
              'No tribe activity yet.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: entries.length,
          itemBuilder: (_, i) => _ActivityTile(entry: entries[i]),
        );
      },
    );
  }
}

class _PartnersFeed extends ConsumerWidget {
  const _PartnersFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(partnerActivityProvider);
    return activityAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Could not load partner activity.', style: TextStyle(color: Colors.white54))),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No partner activity yet.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
                const Gap(12),
                TextButton(
                  onPressed: () => context.push('/social/accountability'),
                  child: const Text('Find a partner →'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: entries.length,
          itemBuilder: (_, i) => _ActivityTile(entry: entries[i]),
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _ActivityTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final userName = entry['userName'] as String? ?? 'Someone';
    final type = entry['type'] as String? ?? 'activity';
    final data = (entry['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final detail = _describe(type, data);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: EmergeColors.glassWhite,
            child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?'),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const Gap(2),
                Text(detail, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _describe(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'habit_complete':
        return 'Completed ${data['habitTitle'] ?? 'a habit'}';
      case 'streak_milestone':
        return 'Hit a ${data['streakDays'] ?? ''}-day streak';
      case 'challenge_complete':
        return 'Completed ${data['challengeTitle'] ?? 'a quest'}';
      case 'partner_joined':
        return 'Added a partner: ${data['partnerName'] ?? ''}';
      case 'contract_committed':
        return 'Committed to ${data['habitTitle'] ?? 'a contract'}';
      default:
        return 'New activity';
    }
  }
}
```

- [ ] **Step 4: Run test to verify it fails** (expected — `partnerActivityProvider` not yet defined)

Run: `flutter test test/features/social/presentation/screens/social_activity_screen_test.dart`
Expected: FAIL — `partner_activity_provider.dart` import does not exist.

This is expected. Proceed to Task 2.2 which creates the stub provider; then re-run this test.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/screens/social_activity_screen.dart test/features/social/presentation/screens/social_activity_screen_test.dart
git commit -m "feat(social): add SocialActivityScreen shell with Tribe tab"
```

---

### Task 2.2: Create stub `partnerActivityProvider` (empty stream)

**Files:**
- Create: `lib/features/social/presentation/providers/partner_activity_provider.dart`

This creates a minimal provider so the screen compiles. The real repository backing it comes in Phase 3.

- [ ] **Step 1: Write the provider**

Create `lib/features/social/presentation/providers/partner_activity_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream of partner-activity events for the current user.
///
/// Reads `users/{me}/partner_activity` ordered by `createdAt` desc.
/// Returns an empty list stream when there is no authenticated user
/// or no partner-activity repository wired (Phase 3 wires the repo).
final partnerActivityProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  // Phase 3 wires the real repository. For now this returns an empty
  // stream so [SocialActivityScreen]'s Partners tab compiles and shows
  // its empty state.
  return Stream.value(<Map<String, dynamic>>[]);
});
```

- [ ] **Step 2: Run the screen test from Task 2.1 to verify it now passes**

Run: `flutter test test/features/social/presentation/screens/social_activity_screen_test.dart`
Expected: PASS — all 3 tests (including the Partners-tab empty state, since the stub returns empty).

- [ ] **Step 3: Commit**

```bash
git add lib/features/social/presentation/providers/partner_activity_provider.dart
git commit -m "feat(social): add stub partnerActivityProvider"
```

---

### Task 2.3: Register `/social/activity` route

**Files:**
- Modify: `lib/core/router/router.dart`

- [ ] **Step 1: Add the import**

In `lib/core/router/router.dart`, find the import for `friends_screen.dart` (around line 38):
```dart
import 'package:emerge_app/features/social/presentation/screens/friends_screen.dart';
```

Add immediately after it:
```dart
import 'package:emerge_app/features/social/presentation/screens/social_activity_screen.dart';
```

- [ ] **Step 2: Register the route**

Find the `/social/accountability` route block (around lines 428-432):
```dart
                  GoRoute(
                    path: 'accountability',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const FriendsScreen(),
                  ),
```

Add immediately after it:
```dart
                  GoRoute(
                    path: 'activity',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final tribeId =
                          state.uri.queryParameters['tribeId'] ?? '';
                      return SocialActivityScreen(tribeId: tribeId);
                    },
                  ),
```

- [ ] **Step 3: Verify the app still compiles**

Run: `flutter analyze lib/core/router/router.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/router/router.dart
git commit -m "feat(router): register /social/activity route"
```

---

### Task 2.4: Repoint the two feed links to `/social/activity`

**Files:**
- Modify: `lib/features/social/presentation/widgets/tribe_live_compact.dart`
- Modify: `lib/features/social/presentation/widgets/tribe_pulse_status_row.dart`
- Create: `test/features/social/presentation/widgets/tribe_live_compact_routing_test.dart`

- [ ] **Step 1: Write the failing routing test**

Create `test/features/social/presentation/widgets/tribe_live_compact_routing_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_live_compact.dart';

Widget buildTest() {
  return ProviderScope(
    overrides: [
      clubActivityProvider.overrideWith((ref, arg) => Stream.value([])),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: TribeLiveCompact(clubId: 'c1')),
          ),
          GoRoute(
            path: '/social/activity',
            builder: (_, _) => const Scaffold(body: Center(child: Text('ACTIVITY_SCREEN'))),
          ),
          GoRoute(
            path: '/social/accountability',
            builder: (_, _) => const Scaffold(body: Center(child: Text('FRIENDS_SCREEN'))),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('View More navigates to /social/activity, not /social/accountability',
      (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.textContaining('View More'));
    await tester.pumpAndSettle();

    expect(find.text('ACTIVITY_SCREEN'), findsOneWidget);
    expect(find.text('FRIENDS_SCREEN'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/widgets/tribe_live_compact_routing_test.dart`
Expected: FAIL — currently routes to `/social/accountability`, so it finds `FRIENDS_SCREEN` not `ACTIVITY_SCREEN`.

- [ ] **Step 3: Repoint the "View More" link**

In `lib/features/social/presentation/widgets/tribe_live_compact.dart`, find (around line 255-258):
```dart
  _ViewMoreLink(
    label: 'View More',
    onTap: () => context.push('/social/accountability'),
  ),
```

Replace with:
```dart
  _ViewMoreLink(
    label: 'View More',
    onTap: () => context.push('/social/activity?tribeId=$clubId'),
  ),
```

Note: `clubId` is the widget's field. If the enclosing `_LiveFeedBlock` does not have `clubId` in scope, thread it through from `TribeLiveCompact`. Verify by reading the file: `TribeLiveCompact` receives `clubId` (line 17) and passes it down. If `_LiveFeedBlock` needs it, add `final String clubId;` to its constructor and pass `clubId: clubId` where it is instantiated.

- [ ] **Step 4: Run the routing test to verify it passes**

Run: `flutter test test/features/social/presentation/widgets/tribe_live_compact_routing_test.dart`
Expected: PASS.

- [ ] **Step 5: Repoint the LIVE chip**

In `lib/features/social/presentation/widgets/tribe_pulse_status_row.dart`, find (around lines 87-92):
```dart
  _PulseChip(
    dotColor: _liveGreen,
    label: 'LIVE',
    value: '$activityCount signals',
    onTap: () => context.push('/social/accountability'),
  ),
```

Replace with:
```dart
  _PulseChip(
    dotColor: _liveGreen,
    label: 'LIVE',
    value: '$activityCount signals',
    onTap: () => context.push('/social/activity?tribeId=${userClub.id}'),
  ),
```

`userClub` is already a field on `TribePulseStatusRow` (confirmed — it receives `userClub` at construction). Verify by reading the widget constructor.

- [ ] **Step 6: Verify both widgets compile**

Run: `flutter analyze lib/features/social/presentation/widgets/tribe_live_compact.dart lib/features/social/presentation/widgets/tribe_pulse_status_row.dart`
Expected: No errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/social/presentation/widgets/tribe_live_compact.dart lib/features/social/presentation/widgets/tribe_pulse_status_row.dart test/features/social/presentation/widgets/tribe_live_compact_routing_test.dart
git commit -m "fix(social): repoint live feed links to /social/activity"
```

---

## Phase 3: Partner Activity Data Source (the new backend)

Builds the read repository and wires the real provider. Then hooks the write fan-out into `SocialActivityService`. This is the core new data source.

### Task 3.1: Create `PartnerActivityRepository` (read)

**Files:**
- Create: `lib/features/social/domain/repositories/partner_activity_repository.dart`
- Test: `test/features/social/domain/repositories/partner_activity_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/social/domain/repositories/partner_activity_repository_test.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/domain/repositories/partner_activity_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestorePartnerActivityRepository repo;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    repo = FirestorePartnerActivityRepository(firestore);

    // Seed two events for user 'me', one for 'other'.
    await firestore
        .collection('users')
        .doc('me')
        .collection('partner_activity')
        .doc('e1')
        .set({
      'type': 'habit_complete',
      'userId': 'partner1',
      'userName': 'Alex',
      'data': {'habitTitle': 'Cold Plunge'},
      'timestamp': '2026-06-20T10:00:00.000Z',
    });
    await firestore
        .collection('users')
        .doc('me')
        .collection('partner_activity')
        .doc('e2')
        .set({
      'type': 'streak_milestone',
      'userId': 'partner2',
      'userName': 'Sam',
      'data': {'streakDays': 7},
      'timestamp': '2026-06-21T08:00:00.000Z',
    });
  });

  test('watchPartnerActivity emits events ordered by timestamp desc', () async {
    final events = await repo.watchPartnerActivity('me').first;
    expect(events.length, 2);
    expect(events.first['userName'], 'Sam'); // newer timestamp first
    expect(events.last['userName'], 'Alex');
    // doc id injected into map
    expect(events.first.containsKey('id'), true);
  });

  test('watchPartnerActivity returns empty for unknown user', () async {
    final events = await repo.watchPartnerActivity('nobody').first;
    expect(events, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/domain/repositories/partner_activity_repository_test.dart`
Expected: FAIL — `partner_activity_repository.dart` does not exist.

- [ ] **Step 3: Write the implementation**

Create `lib/features/social/domain/repositories/partner_activity_repository.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads partner-activity events written by [SocialActivityService]'s
/// fan-out-on-write. Events live at
/// `users/{partnerId}/partner_activity/{eventId}` and are denormalized
/// (actor name/type/payload snapshotted at write time) so reads never
/// fan out to user profiles.
abstract class PartnerActivityRepository {
  /// Stream of partner-activity events for [userId], newest first.
  Stream<List<Map<String, dynamic>>> watchPartnerActivity(String userId);
}

class FirestorePartnerActivityRepository
    implements PartnerActivityRepository {
  final FirebaseFirestore _firestore;

  FirestorePartnerActivityRepository(this._firestore);

  @override
  Stream<List<Map<String, dynamic>>> watchPartnerActivity(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('partner_activity')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/domain/repositories/partner_activity_repository_test.dart`
Expected: PASS — both tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/domain/repositories/partner_activity_repository.dart test/features/social/domain/repositories/partner_activity_repository_test.dart
git commit -m "feat(social): add FirestorePartnerActivityRepository (read)"
```

---

### Task 3.2: Wire the real `partnerActivityProvider`

**Files:**
- Modify: `lib/features/social/presentation/providers/partner_activity_provider.dart`

- [ ] **Step 1: Replace the stub with the real provider**

Replace the entire contents of `lib/features/social/presentation/providers/partner_activity_provider.dart` with:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/domain/repositories/partner_activity_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final partnerActivityRepositoryProvider =
    Provider<PartnerActivityRepository>((ref) {
  return FirestorePartnerActivityRepository(FirebaseFirestore.instance);
});

/// Stream of partner-activity events for the current user.
/// Reads `users/{me}/partner_activity` ordered by `timestamp` desc.
/// Returns an empty list stream when there is no authenticated user.
final partnerActivityProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(<Map<String, dynamic>>[]);

  final repository = ref.watch(partnerActivityRepositoryProvider);
  return repository.watchPartnerActivity(user.id);
});
```

- [ ] **Step 2: Run the activity screen test to confirm it still passes**

Run: `flutter test test/features/social/presentation/screens/social_activity_screen_test.dart`
Expected: PASS — the screen test overrides `partnerActivityProvider`, so it is unaffected; but this confirms no compile break.

- [ ] **Step 3: Verify analyze**

Run: `flutter analyze lib/features/social/presentation/providers/partner_activity_provider.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/social/presentation/providers/partner_activity_provider.dart
git commit -m "feat(social): wire real partnerActivityProvider to repository"
```

---

### Task 3.3: Add partner fan-out to `SocialActivityService`

This is the core write-side change. We add a `PartnerLookup` callback to the service so it can resolve the actor's partner list without creating a dependency cycle (the friend repo already depends on this service; if the service depended back on the friend repo, that's a cycle). The callback reads Firestore directly.

**Files:**
- Modify: `lib/features/social/domain/services/club_activity_service.dart`
- Modify: `lib/features/social/presentation/providers/tribes_provider.dart`
- Create: `test/features/social/domain/services/club_activity_service_partner_fanout_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/social/domain/services/club_activity_service_partner_fanout_test.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_engine_barrel.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';

// Minimal fake leaderboard repo so the service can be constructed.
class _FakeLeaderboardRepo implements LeaderboardRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value();
}

void main() {
  late FakeFirebaseFirestore firestore;
  late EnhancedSyncEngine syncEngine;
  late SocialActivityService service;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    // Build a real Drift in-memory database for the activity DAO.
    final db = await AppDatabase.forTesting();
    final mutationQueue = db.mutationQueueDao;
    syncEngine = EnhancedSyncEngine(mutationQueue, firestore);
    service = SocialActivityService(
      syncEngine: syncEngine,
      activityDao: db.tribeActivityDao,
      leaderboardRepo: _FakeLeaderboardRepo(),
      // Partner lookup: read friends subcollection of the actor.
      getPartnerIds: (userId) async {
        final snap = await firestore
            .collection('users')
            .doc(userId)
            .collection('friends')
            .get();
        return snap.docs.map((d) => d.id).toList();
      },
    );

    // Seed: actor 'me' has two partners.
    await firestore.collection('users').doc('me').collection('friends').doc('p1').set({});
    await firestore.collection('users').doc('me').collection('friends').doc('p2').set({});
  });

  test(
      'logHabitCompletion fans out a partner_activity doc to each partner of the actor',
      () async {
    await service.logHabitCompletion(
      userId: 'me',
      userName: 'Me',
      archetype: 'athlete',
      habitId: 'h1',
      habitTitle: 'Cold Plunge',
      streakDay: 1,
      attribute: 'body',
    );

    // Drain the sync engine queue so writes apply to the fake Firestore.
    await syncEngine.drainForTesting();

    final p1 = await firestore
        .collection('users')
        .doc('p1')
        .collection('partner_activity')
        .get();
    final p2 = await firestore
        .collection('users')
        .doc('p2')
        .collection('partner_activity')
        .get();

    expect(p1.docs.length, 1);
    expect(p2.docs.length, 1);
    expect(p1.docs.first['type'], 'habit_complete');
    expect(p1.docs.first['userName'], 'Me'); // denormalized
    expect(p1.docs.first['data']['habitTitle'], 'Cold Plunge');
  });

  test('users with no partners produce no fan-out writes', () async {
    await service.logHabitCompletion(
      userId: 'loner',
      userName: 'Loner',
      archetype: 'athlete',
      habitId: 'h1',
      habitTitle: 'Meditate',
      streakDay: 1,
      attribute: 'mind',
    );
    await syncEngine.drainForTesting();

    final any = await firestore.collectionGroup('partner_activity').get();
    expect(any.docs.length, 0);
  });
}
```

**Note on testing helpers:** this test references `AppDatabase.forTesting()`, `EnhancedSyncEngine.drainForTesting()`, and `db.mutationQueueDao` / `db.tribeActivityDao`. If those exact names do not exist, read `lib/core/drift/database.dart` and `lib/core/sync/sync_engine.dart` and substitute the real in-memory-construction and queue-drain helpers. The intent is: construct an in-memory Drift DB, point the sync engine at the fake Firestore, call a `logX` method, drain the queue, assert the fan-out docs exist. Do not skip this test — it is the correctness proof for the write path.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/domain/services/club_activity_service_partner_fanout_test.dart`
Expected: FAIL — `getPartnerIds` is not a parameter of `SocialActivityService`, and no partner fan-out writes occur.

- [ ] **Step 3: Add the `PartnerLookup` callback and a `_fanOutToPartners` helper**

In `lib/features/social/domain/services/club_activity_service.dart`:

3a. Add a typedef near the top (after the imports, before `class SocialActivityService`):

```dart
/// Resolves the partner ids of an actor. Implemented as a Firestore read
/// (see [tribes_provider.dart]) to avoid a dependency cycle: the friend
/// repository depends on this service, so the service must not depend on
/// the friend repository.
typedef PartnerLookup = Future<List<String>> Function(String userId);
```

3b. Add the field + constructor param. Find the constructor (lines 32-38):
```dart
  final EnhancedSyncEngine _syncEngine;
  final TribeActivityDao _activityDao;
  final LeaderboardRepository _leaderboardRepo;

  SocialActivityService({
    required EnhancedSyncEngine syncEngine,
    required TribeActivityDao activityDao,
    required LeaderboardRepository leaderboardRepo,
  }) : _syncEngine = syncEngine,
       _activityDao = activityDao,
       _leaderboardRepo = leaderboardRepo;
```

Replace with:
```dart
  final EnhancedSyncEngine _syncEngine;
  final TribeActivityDao _activityDao;
  final LeaderboardRepository _leaderboardRepo;
  final PartnerLookup? _getPartnerIds;

  SocialActivityService({
    required EnhancedSyncEngine syncEngine,
    required TribeActivityDao activityDao,
    required LeaderboardRepository leaderboardRepo,
    PartnerLookup? getPartnerIds,
  }) : _syncEngine = syncEngine,
       _activityDao = activityDao,
       _leaderboardRepo = leaderboardRepo,
       _getPartnerIds = getPartnerIds;
```

3c. Add the fan-out helper as a private method inside the class (add after the constructor, before `_getClubIdForArchetype`):

```dart
  /// Fan-out-on-write: writes a denormalized partner-activity doc to each
  /// of the actor's partners. Skipped silently when there is no partner
  /// lookup (e.g. in legacy constructions) or when the actor has no partners.
  Future<void> _fanOutToPartners({
    required String actorId,
    required String actorName,
    required String type,
    required Map<String, dynamic> data,
    required String timestamp,
    required String eventId,
  }) async {
    final lookup = _getPartnerIds;
    if (lookup == null) return;
    final partnerIds = await lookup(actorId);
    for (final partnerId in partnerIds) {
      await _syncEngine.enqueueSet(
        collectionPath: 'users/$partnerId/partner_activity',
        documentId: eventId,
        data: {
          'type': type,
          'userId': actorId,
          'userName': actorName,
          'data': data,
          'timestamp': timestamp,
        },
      );
    }
  }
```

3d. Add a partner fan-out call to each `logX` method. For each method that already writes global + club, add a third `_fanOutToPartners(...)` call reusing the same `id`, `nowStr`, `type`, and `data`. Concretely, inside `logHabitCompletion` (after the club write, before the leaderboard update), add:

```dart
      // 3b. Fan out to partners
      await _fanOutToPartners(
        actorId: userId,
        actorName: userName,
        type: _kActivityTypeHabitComplete,
        data: {
          'habitId': habitId,
          'habitTitle': habitTitle,
          'streakDay': streakDay,
          'attribute': attribute,
        },
        timestamp: nowStr,
        eventId: id,
      );
```

Apply the equivalent addition to: `logLevelUp` (`data: {'newLevel': newLevel}`), `logChallengeComplete` (`data: {'challengeId': challengeId, 'challengeTitle': challengeTitle}`), `logStreakMilestone` (`data: {'streakDays': streakDays}`), `logNodeClaim` (`data: {'nodeId': nodeId, 'nodeName': nodeName}`), `logBadgeEarned` (`data: {'badgeId': badgeId, 'badgeName': badgeName}`), `logPartnerJoined` (`data: {'partnerName': partnerName}`), and `logContractCommitted` (`data: {'habitTitle': habitTitle, 'penalty': penalty}`). The generic `logActivity` method does not fan out (it has no actor context).

Each call reuses the local `id` and `nowStr` variables already declared in that method, and the matching `_kActivityType*` constant.

- [ ] **Step 4: Wire the partner-lookup callback in the provider**

In `lib/features/social/presentation/providers/tribes_provider.dart`, find `socialActivityServiceProvider` (lines 20-30). Add a partner-lookup callback that reads Firestore directly (avoiding the cycle):

```dart
final socialActivityServiceProvider = Provider<SocialActivityService>((ref) {
  final syncEngine = ref.watch(enhancedSyncEngineProvider);
  final activityDao = ref.watch(tribeActivityDaoProvider);
  final leaderboardRepo = ref.watch(leaderboardRepositoryProvider);

  return SocialActivityService(
    syncEngine: syncEngine,
    activityDao: activityDao,
    leaderboardRepo: leaderboardRepo,
    getPartnerIds: (userId) async {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();
      return snapshot.docs.map((d) => d.id).toList();
    },
  );
});
```

Add the import at the top of `tribes_provider.dart` if `cloud_firestore` is not already imported:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
```

- [ ] **Step 5: Run the fan-out test to verify it passes**

Run: `flutter test test/features/social/domain/services/club_activity_service_partner_fanout_test.dart`
Expected: PASS — both tests (fan-out to two partners; no fan-out for a user with no partners).

- [ ] **Step 6: Run the full service test suite to ensure no regressions**

Run: `flutter test test/features/social/domain/services/`
Expected: All previously-passing tests still pass. The new fan-out calls are additive and no-op when `_getPartnerIds` is null (e.g. in older test constructions that don't pass it).

- [ ] **Step 7: Commit**

```bash
git add lib/features/social/domain/services/club_activity_service.dart lib/features/social/presentation/providers/tribes_provider.dart test/features/social/domain/services/club_activity_service_partner_fanout_test.dart
git commit -m "feat(social): add partner-activity fan-out-on-write to SocialActivityService"
```

---

## Phase 4: Lobby Assembly — Your Circle + Quest Split

Mounts the new sections in `TribeLobbyScreen` with the new sliver order. This is where all the pieces come together visually.

### Task 4.1: Create `TribeCircleSection` (lobby partners home)

**Files:**
- Create: `lib/features/social/presentation/widgets/tribe_circle_section.dart`
- Test: `test/features/social/presentation/widgets/tribe_circle_section_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/social/presentation/widgets/tribe_circle_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/contract_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_circle_section.dart';

Widget buildTest({
  List<Friend> partners = const [],
  List<PartnerRequest> requests = const [],
  int contractCount = 0,
}) {
  return ProviderScope(
    overrides: [
      partnersListStreamProvider.overrideWith((ref) => Stream.value(partners)),
      pendingPartnerRequestsStreamProvider.overrideWith((ref) => Stream.value(requests)),
      activeOnlyContractsProvider.overrideWith((ref) => Stream.value(
            List.filled(contractCount, null).whereType().toList(),
          )),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: SingleChildScrollView(child: TribeCircleSection())),
          ),
        ],
      ),
    ),
  );
}

Friend _friend(String id, String name) => Friend(
      id: id,
      name: name,
      archetype: FriendArchetype.creator,
    );

void main() {
  testWidgets('header reads YOUR CIRCLE', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('YOUR CIRCLE'), findsOneWidget);
  });

  testWidgets('renders partner avatars', (tester) async {
    await tester.pumpWidget(buildTest(partners: [
      _friend('p1', 'Alex'),
      _friend('p2', 'Sam'),
    ]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
  });

  testWidgets('shows request badge when requests pending', (tester) async {
    await tester.pumpWidget(buildTest(
      requests: [
        PartnerRequest(
          id: 'r1', senderId: 's1', senderName: 'Pat', senderArchetype: 'creator',
          senderLevel: 1, recipientId: 'me', status: 'pending',
          createdAt: DateTime.now(),
        ),
      ],
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('1'), findsWidgets);
  });
}
```

**Note:** `activeOnlyContractsProvider` returns a stream of contract objects, not `List<Null>`. Read `lib/features/monetization/presentation/providers/contract_provider.dart` to find the real contract entity type and override with a stream of real contract instances. The override above is a placeholder for the shape; substitute the real type when writing this test.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/widgets/tribe_circle_section_test.dart`
Expected: FAIL — `tribe_circle_section.dart` does not exist.

- [ ] **Step 3: Write the implementation**

Create `lib/features/social/presentation/widgets/tribe_circle_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/contract_provider.dart';

/// The official lobby home for the user's accountability partners.
/// Replaces the two misrouted deep-links from the live feed. Tapping the
/// section navigates to [/social/accountability] (FriendsScreen).
///
/// Supersedes the orphaned [TribeAccountabilitySection], which is deleted
/// in Phase 6.
class TribeCircleSection extends ConsumerWidget {
  const TribeCircleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(partnersListStreamProvider);
    final contractsAsync = ref.watch(activeOnlyContractsProvider);
    final requestsAsync = ref.watch(pendingPartnerRequestsStreamProvider);

    return GestureDetector(
      onTap: () => context.push('/social/accountability'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'YOUR CIRCLE',
                  style: TextStyle(
                    color: EmergeColors.nebulaPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                requestsAsync.maybeWhen(
                  data: (reqs) => reqs.isEmpty
                      ? const SizedBox.shrink()
                      : _RequestBadge(count: reqs.length),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const Gap(12),
            SizedBox(
              height: 56,
              child: partnersAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => const Text(
                  'Could not load partners.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                data: (partners) {
                  if (partners.isEmpty) {
                    return Row(
                      children: [
                        Icon(Icons.person_add, color: Colors.white.withValues(alpha: 0.5), size: 20),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            'Add your first partner',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: partners.length,
                    separatorBuilder: (_, _) => const Gap(10),
                    itemBuilder: (_, i) => _PartnerAvatar(partner: partners[i]),
                  );
                },
              ),
            ),
            const Gap(10),
            contractsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (contracts) => Row(
                children: [
                  Icon(Icons.handshake, color: EmergeColors.yellow.withValues(alpha: 0.8), size: 14),
                  const Gap(6),
                  Text(
                    '${contracts.length} active contract${contracts.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerAvatar extends StatelessWidget {
  final Friend partner;
  const _PartnerAvatar({required this.partner});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: EmergeColors.glassWhite,
              child: Text(
                partner.name.isNotEmpty ? partner.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            if (partner.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black87, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        const Gap(3),
        Text(
          partner.name.split(' ').first,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _RequestBadge extends StatelessWidget {
  final int count;
  const _RequestBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: EmergeColors.coral,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/widgets/tribe_circle_section_test.dart`
Expected: PASS — all 3 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/widgets/tribe_circle_section.dart test/features/social/presentation/widgets/tribe_circle_section_test.dart
git commit -m "feat(social): add TribeCircleSection (lobby partners home)"
```

---

### Task 4.2: Assemble the new lobby sliver order

**Files:**
- Modify: `lib/features/social/presentation/screens/tribe_lobby_screen.dart`
- Create: `test/features/social/presentation/screens/tribe_lobby_screen_test.dart`

- [ ] **Step 1: Write a smoke test for the new lobby**

Create `test/features/social/presentation/screens/tribe_lobby_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_lobby_screen.dart';

Widget buildTest() {
  return ProviderScope(
    overrides: [
      allArchetypeClubsProvider.overrideWith((ref) => [
            const Tribe(id: 'morning_warriors', name: 'Morning Warriors', archetypeId: 'athlete', memberCount: 42),
          ]),
      userStatsStreamProvider.overrideWith((ref) => Stream.value(
            const UserProfile(uid: 'u1', archetype: UserArchetype.athlete),
          )),
      // TribeLiveCompact's internal provider:
      clubActivityProvider.overrideWith((ref, arg) => Stream.value([])),
    ],
    child: const MaterialApp(home: TribeLobbyScreen()),
  );
}

void main() {
  testWidgets('renders the new dual-hub sections in order', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('YOUR CIRCLE'), findsOneWidget);
    expect(find.text('YOUR QUESTS'), findsOneWidget);
    expect(find.text('QUESTS FOR YOU'), findsOneWidget);
  });
}
```

**Note:** `Tribe`, `allArchetypeClubsProvider`, `userStatsStreamProvider`, `UserProfile`, `UserArchetype` are the real names (verified in `tribe.dart`, `tribes_provider.dart`, `user_stats_providers.dart`, `user_extension.dart`). Confirm `Tribe`'s required constructor fields by reading `lib/features/social/domain/models/tribe.dart` and adjust the fixture if more fields are required.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/screens/tribe_lobby_screen_test.dart`
Expected: FAIL — `YOUR CIRCLE`, `YOUR QUESTS`, `QUESTS FOR YOU` do not all appear (old lobby uses `ACTIVE QUESTS` and has no circle section).

- [ ] **Step 3: Update the imports**

In `lib/features/social/presentation/screens/tribe_lobby_screen.dart`, find the import block. Replace the import of the old active-quests widget:
```dart
import 'package:emerge_app/features/social/presentation/widgets/tribe_active_quests_section.dart';
```
with the three new imports:
```dart
import 'package:emerge_app/features/social/presentation/widgets/tribe_circle_section.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_quests_for_you_section.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_your_quests_section.dart';
```

- [ ] **Step 4: Update the sliver list**

In `tribe_lobby_screen.dart`, find the sliver list (lines 59-104). Replace the block from `TribeLiveCompact` through `TribeActiveQuestsSection` with the new order:

Find:
```dart
                    SliverToBoxAdapter(
                      child: TribeLiveCompact(
                        clubId: userClub.id,
                        profile: profile,
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(8)),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: TribeCreatorsStrip(),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: TribeActiveQuestsSection(),
                    ),
```

Replace with:
```dart
                    SliverToBoxAdapter(
                      child: TribeCircleSection(),
                    ),
                    const SliverToBoxAdapter(child: Gap(8)),
                    SliverToBoxAdapter(
                      child: TribeLiveCompact(
                        clubId: userClub.id,
                        profile: profile,
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(8)),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: TribeCreatorsStrip(),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: TribeYourQuestsSection(),
                    ),
                    const SliverToBoxAdapter(child: Gap(4)),
                    const SliverToBoxAdapter(
                      child: TribeQuestsForYouSection(),
                    ),
```

Also update the doc comment (lines 25-27) to match the new sequence:
```dart
/// Sequence (identity-first):
///   Hero → Stats → Status chips → Your Circle (partners) →
///   Live (feed / leaderboard) → Creators → Your Quests → Quests For You →
///   sticky CTA bar
```

- [ ] **Step 5: Run the lobby smoke test to verify it passes**

Run: `flutter test test/features/social/presentation/screens/tribe_lobby_screen_test.dart`
Expected: PASS — all three new section headers appear.

- [ ] **Step 6: Verify the full social test suite passes**

Run: `flutter test test/features/social/`
Expected: All tests pass (including the now-stale `tribe_active_quests_section_test.dart`, which will FAIL because its widget was just removed from the lobby — see Phase 6 Task 6.1 which deletes it; for now, this is expected and acceptable as a known-broken test on a deleted widget, but to keep the suite green you may delete that test file now and note it in the Phase 6 commit).

**Decision point:** To keep CI green between phases, delete `test/features/social/presentation/widgets/tribe_active_quests_section_test.dart` and `lib/features/social/presentation/widgets/tribe_active_quests_section.dart` now (their replacements exist). This pulls Phase 6 Task 6.1's deletion forward. Recommended.

- [ ] **Step 7: Commit**

```bash
git add lib/features/social/presentation/screens/tribe_lobby_screen.dart test/features/social/presentation/screens/tribe_lobby_screen_test.dart
git commit -m "feat(social): assemble dual-hub lobby (circle + quest split)"
```

---

## Phase 5: Contacts Discovery (address book)

Adds the `/social/contacts` screen and the contact→user resolution. Adds two new dependencies.

### Task 5.1: Add dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the packages**

In `pubspec.yaml`, find the `dependencies:` block. Add (maintaining alphabetical-ish ordering with the existing entries):
```yaml
  fast_contacts: ^3.0.0
  permission_handler: ^11.3.1
```

- [ ] **Step 2: Fetch packages**

Run: `flutter pub get`
Expected: resolves successfully.

- [ ] **Step 3: Verify**

Run: `flutter analyze`
Expected: no new errors.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add fast_contacts and permission_handler deps"
```

---

### Task 5.2: Create `ContactResolver` (phone/email → user)

**Files:**
- Create: `lib/features/social/domain/services/contact_resolver.dart`
- Test: `test/features/social/domain/services/contact_resolver_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/social/domain/services/contact_resolver_test.dart`:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/domain/services/contact_resolver.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ContactResolver resolver;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    resolver = FirestoreContactResolver(firestore);

    // Seed two users with phone numbers.
    await firestore.collection('users').doc('u1').set({
      'displayName': 'Sarah',
      'phone': '+15550142',
      'email': 'sarah@example.com',
    });
    await firestore.collection('users').doc('u2').set({
      'displayName': 'Mike',
      'phone': '+15550188',
      'email': 'mike@example.com',
    });
  });

  test('resolves a contact whose phone matches an existing user', () async {
    const contacts = [
      ResolvedContact(name: 'Sarah Chen', phone: '+15550142', email: 'sarah@example.com'),
      const ResolvedContact(name: 'Unknown Friend', phone: '+15559999', email: null),
    ];
    final results = await resolver.resolve(contacts);
    expect(results.length, 2);
    expect(results.first.name, 'Sarah Chen');
    expect(results.first.matchedUserId, 'u1');
    expect(results.last.matchedUserId, isNull); // no match
  });

  test('matches by email when phone does not match', () async {
    const contacts = [
      ResolvedContact(name: 'Mike P', phone: '+15557777', email: 'mike@example.com'),
    ];
    final results = await resolver.resolve(contacts);
    expect(results.first.matchedUserId, 'u2');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/domain/services/contact_resolver_test.dart`
Expected: FAIL — `contact_resolver.dart` does not exist.

- [ ] **Step 3: Write the implementation**

Create `lib/features/social/domain/services/contact_resolver.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// A device contact normalized for resolution.
class ResolvedContact {
  final String name;
  final String? phone;
  final String? email;

  const ResolvedContact({required this.name, this.phone, this.email});
}

/// Result of resolving a contact against existing emerge users.
class ContactMatch {
  final ResolvedContact contact;
  final String? matchedUserId;
  final String? matchedDisplayName;

  const ContactMatch({
    required this.contact,
    this.matchedUserId,
    this.matchedDisplayName,
  });

  bool get isMatched => matchedUserId != null;
}

/// Matches device contacts to existing emerge users by phone or email.
/// Privacy: contacts are read on-device; only the phone/email needed for
/// the lookup are sent to Firestore, and resolution is a read, not a store.
abstract class ContactResolver {
  Future<List<ContactMatch>> resolve(List<ResolvedContact> contacts);
}

class FirestoreContactResolver implements ContactResolver {
  final FirebaseFirestore _firestore;
  FirestoreContactResolver(this._firestore);

  @override
  Future<List<ContactMatch>> resolve(List<ResolvedContact> contacts) async {
    final results = <ContactMatch>[];
    for (final c in contacts) {
      String? userId;
      String? displayName;

      if (c.phone != null) {
        final byPhone = await _firestore
            .collection('users')
            .where('phone', isEqualTo: c.phone)
            .limit(1)
            .get();
        if (byPhone.docs.isNotEmpty) {
          userId = byPhone.docs.first.id;
          displayName = byPhone.docs.first.data()['displayName'] as String?;
        }
      }

      if (userId == null && c.email != null) {
        final byEmail = await _firestore
            .collection('users')
            .where('email', isEqualTo: c.email)
            .limit(1)
            .get();
        if (byEmail.docs.isNotEmpty) {
          userId = byEmail.docs.first.id;
          displayName = byEmail.docs.first.data()['displayName'] as String?;
        }
      }

      results.add(ContactMatch(
        contact: c,
        matchedUserId: userId,
        matchedDisplayName: displayName,
      ));
    }
    return results;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/domain/services/contact_resolver_test.dart`
Expected: PASS — both tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/domain/services/contact_resolver.dart test/features/social/domain/services/contact_resolver_test.dart
git commit -m "feat(social): add ContactResolver for address-book discovery"
```

---

### Task 5.3: Create `SocialContactsScreen` and register route

**Files:**
- Create: `lib/features/social/presentation/screens/social_contacts_screen.dart`
- Modify: `lib/core/router/router.dart`

- [ ] **Step 1: Create the screen**

Create `lib/features/social/presentation/screens/social_contacts_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/services/contact_resolver.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';

final contactResolverProvider = Provider<ContactResolver>((ref) {
  // Uses FirebaseFirestore.instance internally; constructed without ref so
  // it stays a pure read service.
  return FirestoreContactResolver(_resolverFirestore(ref));
});

FirebaseFirestore _resolverFirestore(WidgetRef _) =>
    FirebaseFirestore.instance;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Address-book discovery surface: reads device contacts, matches them
/// against existing emerge users, and lets the user invite matches as
/// partners or send an invite code to non-matches.
///
/// Contacts are read on-device and never uploaded wholesale. Only the
/// phone/email needed for the lookup query are sent, and the lookup is a
/// read, not a store.
class SocialContactsScreen extends ConsumerStatefulWidget {
  const SocialContactsScreen({super.key});

  @override
  ConsumerState<SocialContactsScreen> createState() =>
      _SocialContactsScreenState();
}

class _SocialContactsScreenState extends ConsumerState<SocialContactsScreen> {
  bool _loading = false;
  String? _error;
  List<ContactMatch> _matches = const [];
  bool _permissionGranted = false;

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await Permission.contacts.status;
      if (!status.isGranted) {
        final result = await Permission.contacts.request();
        if (!result.isGranted) {
          setState(() {
            _loading = false;
            _permissionGranted = false;
          });
          return;
        }
      }
      _permissionGranted = true;

      // Read on-device via fast_contacts.
      final contacts = await FastContacts.getAllContacts();
      final resolved = contacts
          .map((c) => ResolvedContact(
                name: c.displayName,
                phone: c.phones.isNotEmpty ? c.phones.first.number : null,
                email: c.emails.isNotEmpty ? c.emails.first.address : null,
              ))
          .where((c) => c.phone != null || c.email != null)
          .toList();

      final resolver = ref.read(contactResolverProvider);
      final matches = await resolver.resolve(resolved);
      // Matches first, then unmatched.
      matches.sort((a, b) {
        if (a.isMatched == b.isMatched) return a.contact.name.compareTo(b.contact.name);
        return a.isMatched ? -1 : 1;
      });

      setState(() {
        _matches = matches;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not read contacts.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('FIND FROM CONTACTS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _matches.isEmpty && _permissionGranted
              ? _emptyState()
              : _matches.isEmpty
                  ? _permissionGate()
                  : _list(),
    );
  }

  Widget _permissionGate() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.contact_page, size: 48, color: Colors.white54),
            const Gap(16),
            const Text(
              'Find people you know from your address book.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const Gap(8),
            const Text(
              'Your contacts stay on your device. We only look up phone numbers and emails to find matches.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const Gap(24),
            EmergePrimaryButton(
              label: 'ALLOW CONTACTS',
              onPressed: _loadContacts,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No matches found yet.', style: TextStyle(color: Colors.white60)),
          const Gap(12),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Invite with a code instead →'),
          ),
        ],
      ),
    );
  }

  Widget _list() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _matches.length,
      itemBuilder: (_, i) {
        final m = _matches[i];
        return _ContactRow(match: m, ref: ref);
      },
    );
  }
}

class _ContactRow extends ConsumerWidget {
  final ContactMatch match;
  const _ContactRow({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: EmergeColors.glassWhite,
            child: Text(match.contact.name.isNotEmpty
                ? match.contact.name[0].toUpperCase()
                : '?'),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.contact.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                if (match.isMatched)
                  Text(match.matchedDisplayName ?? 'On Emerge',
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 11))
                else
                  const Text('Not on Emerge yet', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          if (match.isMatched)
            TextButton(
              onPressed: () {
                final user = ref.read(authStateChangesProvider).value;
                if (user == null) return;
                final repo = ref.read(friendRepositoryProvider);
                repo.sendPartnerRequest(user.id, match.matchedUserId!, user.displayName ?? 'You', 'creator', 1);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Partner request sent')),
                );
              },
              child: const Text('ADD'),
            )
          else
            TextButton(
              onPressed: () => context.push('/social/accountability'),
              child: const Text('INVITE'),
            ),
        ],
      ),
    );
  }
}
```

**Important fix before saving:** the file above has an `import` statement placed mid-file (after the helper function) — Dart requires all imports at the top. Reorder so `import 'package:cloud_firestore/cloud_firestore.dart';` is at the top with the others, and remove the mid-file `import`. Also, `FastContacts` and `EmergePrimaryButton` need imports: add `import 'package:fast_contacts/fast_contacts.dart';` and `import 'package:emerge_app/core/presentation/widgets/emerge_primary_button.dart';`. The `contactResolverProvider` defined at the top of this file is the canonical home for that provider (not `tribes_provider.dart`).

Also, the `sendPartnerRequest` signature is `sendPartnerRequest(fromId, toId, senderName, senderArchetype, senderLevel)` — verify the argument order against `friend_repository.dart` (it is `(String fromId, String toId, String senderName, String senderArchetype, int senderLevel)`) and that `senderArchetype` should be the *sender's* real archetype, not the hardcoded `'creator'`. Thread the sender's archetype from the user profile in a follow-up; for the minimal version, read it via `ref.read(userStatsStreamProvider).value?.archetype.name ?? 'creator'`.

- [ ] **Step 2: Register the route**

In `lib/core/router/router.dart`, add the import (near the `social_activity_screen.dart` import added in Task 2.3):
```dart
import 'package:emerge_app/features/social/presentation/screens/social_contacts_screen.dart';
```

Add the route after the `activity` route added in Task 2.3:
```dart
                  GoRoute(
                    path: 'contacts',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SocialContactsScreen(),
                  ),
```

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze lib/features/social/presentation/screens/social_contacts_screen.dart lib/core/router/router.dart`
Expected: No errors (after fixing the import placement noted in Step 1).

- [ ] **Step 4: Commit**

```bash
git add lib/features/social/presentation/screens/social_contacts_screen.dart lib/core/router/router.dart
git commit -m "feat(social): add SocialContactsScreen and /social/contacts route"
```

---

### Task 5.4: Add "Add from contacts" entry in FriendsScreen

**Files:**
- Modify: `lib/features/social/presentation/screens/friends_screen.dart`

- [ ] **Step 1: Add the entry affordance**

In `lib/features/social/presentation/screens/friends_screen.dart`, find the header area near the search bar / invite-code button. Add an "Add from contacts" button that navigates to `/social/contacts`. Read the file first to find the exact insertion point (the invite-code affordance is the natural neighbor).

Add a button (match the existing button styling):
```dart
OutlinedButton.icon(
  icon: const Icon(Icons.contact_page_outlined, size: 16),
  label: const Text('ADD FROM CONTACTS'),
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.white70,
    side: const BorderSide(color: Colors.white24),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
  ),
  onPressed: () => context.push('/social/contacts'),
),
```

Place it adjacent to the existing invite-code affordance so both discovery paths (code + contacts) are visible together.

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze lib/features/social/presentation/screens/friends_screen.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/social/presentation/screens/friends_screen.dart
git commit -m "feat(social): add 'Add from contacts' entry in FriendsScreen"
```

---

## Phase 6: Dead Code & Docs Cleanup

Removes the orphaned files and rewrites the lying docs.

### Task 6.1: Delete orphaned dead code

**Files:**
- Delete: `lib/features/social/presentation/screens/tribe_tab_content.dart`
- Delete: `lib/features/social/presentation/widgets/tribe_accountability_section.dart`
- Delete: `lib/features/social/presentation/widgets/tribe_active_quests_section.dart`
- Delete: `lib/features/social/presentation/screens/accountability_screen.dart`
- Delete (if Phase 4 Task 4.2 Step 6 did not already): `test/features/social/presentation/widgets/tribe_active_quests_section_test.dart`

- [ ] **Step 1: Confirm none are referenced by live routes**

Run these searches and confirm zero hits in `lib/` (test references are acceptable to remove):
- Search for `TribeTabContent` in `lib/`
- Search for `TribeAccountabilitySection` in `lib/`
- Search for `TribeActiveQuestsSection` in `lib/`
- Search for `AccountabilityScreen` in `lib/`

If any are referenced by a live route (not a comment), STOP and rewire that reference first.

- [ ] **Step 2: Delete the files**

```bash
git rm lib/features/social/presentation/screens/tribe_tab_content.dart
git rm lib/features/social/presentation/widgets/tribe_accountability_section.dart
git rm lib/features/social/presentation/widgets/tribe_active_quests_section.dart
git rm lib/features/social/presentation/screens/accountability_screen.dart
git rm test/features/social/presentation/widgets/tribe_active_quests_section_test.dart
```

(If `tribe_active_quests_section.dart` was already deleted in Phase 4 Task 4.2, `git rm` will report "did not match any files" — that's fine, skip it.)

- [ ] **Step 3: Verify the app still compiles and all tests pass**

Run: `flutter analyze`
Run: `flutter test`
Expected: No errors; all tests pass.

- [ ] **Step 4: Commit**

```bash
git commit -m "refactor(social): delete orphaned social widgets (tab content, accountability section, active quests section, placeholder screen)"
```

---

### Task 6.2: Rewrite `screens_overview.md`

**Files:**
- Modify: `docs/screens_overview.md` (find the actual path via glob; the spec referenced `screens_overview.md`)

- [ ] **Step 1: Locate the doc**

Find the file: `Glob` for `**/screens_overview.md`.

- [ ] **Step 2: Rewrite the social section**

Open the file. Find the social section (around lines 129-184 per the spec, describing a nonexistent `SocialScreen` at `/tribes` with `social_discover_tab.dart`, `/tribes/accountability`).

Replace that section with accurate documentation of the current `TribeLobbyScreen` dual-hub architecture:

```markdown
## Social / Tribe Tab (route: `/social`)

The Tribe tab is a **dual hub** — the social home for both the user's
archetype tribe (collective) and their accountability partners (personal).

**Screen:** `TribeLobbyScreen` (`lib/features/social/presentation/screens/tribe_lobby_screen.dart`)

**Lobby sliver order:**
1. Hero (tribe emoji + name)
2. Stats (members / streak / momentum)
3. Pulse chips (LIVE / MOMENTUM / STREAK / QUESTS)
4. Your Circle (accountability partners) → `/social/accountability`
5. Live feed (club activity, top 3) → `/social/activity`
6. Creators strip
7. Your Quests (joined, active) → `/social/challenges`
8. Quests For You (featured daily/weekly)

**Sub-routes (Branch 3 of the shell):**
- `/social` — `TribeLobbyScreen`
- `/social/activity` — `SocialActivityScreen` (Tribe + Partners tabs)
- `/social/accountability` — `FriendsScreen` (partner management)
- `/social/contacts` — `SocialContactsScreen` (address-book discovery)
- `/social/contracts` — `HabitContractScreen`
- `/social/leaderboard` — `LeaderboardScreen`
- `/social/all` — `AllTribesScreen`
- `/social/discover` — `CreatorsBrowseScreen`
- `/social/onboarding` — `SocialOnboardingScreen`
- `/social/challenges`, `/social/challenge/:id` — challenges
- `/social/creator/:id` — `CreatorProfileScreen`
- `/social/blueprint/:id` — `BlueprintDetailScreen`

**Three social graphs** (kept distinct):
- Tribe (archetype collective, club-scoped)
- Partners (1:1 accountability partners, `users/{uid}/friends`)
- Creators (asymmetric follow)

**Partner activity** is written via fan-out-on-write into
`users/{partnerId}/partner_activity` by `SocialActivityService`.
```

- [ ] **Step 3: Commit**

```bash
git add docs/screens_overview.md
git commit -m "docs: rewrite screens_overview social section to match dual-hub reality"
```

---

## Final Verification

- [ ] **Run the entire test suite**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Run static analysis**

Run: `flutter analyze`
Expected: No errors (warnings acceptable only if pre-existing).

- [ ] **Manual smoke test (where possible)**

If a device/emulator is available, navigate: Tribe tab → verify Your Circle, Your Quests, Quests For You sections appear in order; tap "View More" on the live feed → lands on Activity screen (not Friends); tap Your Circle → lands on Friends; in Friends, tap "Add from contacts" → contacts permission flow.

- [ ] **Final commit (if any stray changes)**

```bash
git add -A
git commit -m "chore: social section dual-hub verification pass"
```

---

## Spec Coverage Cross-Check

| Spec section | Tasks |
|--------------|-------|
| Restructured lobby IA | 4.2 |
| New `/social/activity` screen | 2.1, 2.2, 2.3 |
| Two feed links repointed | 2.4 |
| Partner Activity write path (fan-out) | 3.3 |
| Partner Activity read path | 3.1, 3.2 |
| Your Circle section | 4.1, 4.2 |
| Quest honesty split (Your / For You) | 1.1, 1.2, 4.2 |
| Contacts discovery screen | 5.1, 5.2, 5.3, 5.4 |
| Contact→user resolution | 5.2 |
| Delete dead code | 6.1 (+ 4.2 Step 6 forward) |
| Rewrite `screens_overview.md` | 6.2 |
