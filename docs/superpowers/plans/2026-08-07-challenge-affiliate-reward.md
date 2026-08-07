# Challenge Affiliate Reward Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users claim a sponsor's affiliate reward after completing a sponsored challenge, opening the affiliate URL and firing the `affiliate_link_clicked` analytics event.

**Architecture:** Three small units, mirroring the project's testable-design signature pattern (pure logic + injected side effects): a pure `affiliateRewardFor`/`affiliateRewardClaimable` helper (no Firebase), an `AffiliateRewardService` whose URL-open and analytics side effects are injected function types (no Firebase in tests), and a glassmorphic `SponsorRewardCard` display widget. The existing `ChallengeDetailScreen` computes the reward, shows the card, and calls the service on claim.

**Tech Stack:** Flutter, Riverpod (widget is plain `StatelessWidget`; screen already `ConsumerStatefulWidget`), `url_launcher` (already a dependency), `firebase_analytics` (already a dependency), `flutter_animate`/`gap` (existing).

**Spec:** `docs/superpowers/specs/2026-08-07-growth-monetization-gtm-design.md` §6, Tier-1 revenue item 1.

---

### Task 1: Pure affiliate-reward helper

**Files:**
- Create: `lib/features/social/domain/services/affiliate_reward.dart`
- Test: `test/features/social/domain/services/affiliate_reward_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/social/domain/services/affiliate_reward_test.dart`:

```dart
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/services/affiliate_reward.dart';
import 'package:flutter_test/flutter_test.dart';

Challenge _challenge({
  bool isSponsored = true,
  String? affiliateUrl = 'https://example.com/reward',
  String reward = 'Test Reward',
  String? rewardDescription,
  String? sponsor = 'Nike',
  AffiliateNetwork network = AffiliateNetwork.direct,
  int currentDay = 7,
  int totalDays = 7,
  ChallengeStatus status = ChallengeStatus.completed,
}) {
  return Challenge(
    id: 'c1',
    title: '30-Day Run',
    description: 'desc',
    imageUrl: '',
    reward: reward,
    participants: 10,
    daysLeft: 0,
    totalDays: totalDays,
    currentDay: currentDay,
    status: status,
    xpReward: 250,
    steps: const [],
    category: ChallengeCategory.fitness,
    sponsor: sponsor,
    isSponsored: isSponsored,
    affiliateUrl: affiliateUrl,
    rewardDescription: rewardDescription,
    affiliateNetwork: network,
  );
}

void main() {
  group('affiliateRewardFor', () {
    test('returns null for non-sponsored challenges', () {
      expect(affiliateRewardFor(_challenge(isSponsored: false)), isNull);
    });

    test('returns null when affiliate url is null or blank', () {
      expect(affiliateRewardFor(_challenge(affiliateUrl: null)), isNull);
      expect(affiliateRewardFor(_challenge(affiliateUrl: '   ')), isNull);
    });

    test('prefers rewardDescription over reward for the title', () {
      final reward = affiliateRewardFor(
        _challenge(rewardDescription: '20% off Nike', reward: 'Voucher'),
      );
      expect(reward, isNotNull);
      expect(reward!.title, '20% off Nike');
      expect(reward.sponsor, 'Nike');
      expect(reward.url, 'https://example.com/reward');
      expect(reward.network, AffiliateNetwork.direct);
    });

    test('falls back to reward text and generic sponsor', () {
      final reward = affiliateRewardFor(
        _challenge(rewardDescription: null, reward: 'Exclusive gear', sponsor: null),
      );
      expect(reward!.title, 'Exclusive gear');
      expect(reward.sponsor, 'Sponsor');
    });
  });

  group('affiliateRewardClaimable', () {
    test('true when status is completed', () {
      expect(
        affiliateRewardClaimable(_challenge(status: ChallengeStatus.completed)),
        isTrue,
      );
    });

    test('true when progress reached the final day while active', () {
      expect(
        affiliateRewardClaimable(
          _challenge(status: ChallengeStatus.active, currentDay: 7, totalDays: 7),
        ),
        isTrue,
      );
    });

    test('false while still in progress', () {
      expect(
        affiliateRewardClaimable(
          _challenge(status: ChallengeStatus.active, currentDay: 3, totalDays: 7),
        ),
        isFalse,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/domain/services/affiliate_reward_test.dart`
Expected: FAIL — `Error: Error when reading 'lib/features/social/domain/services/affiliate_reward.dart': No such file or directory`

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/social/domain/services/affiliate_reward.dart`:

```dart
import 'package:emerge_app/features/social/domain/models/challenge.dart';

/// A claimable sponsor reward surfaced from a completed sponsored challenge.
class AffiliateReward {
  final String url;
  final String title;
  final String sponsor;
  final AffiliateNetwork network;

  const AffiliateReward({
    required this.url,
    required this.title,
    required this.sponsor,
    required this.network,
  });
}

/// Returns the claimable sponsor reward for [challenge], or null when the
/// challenge is not sponsored or has no affiliate link configured.
AffiliateReward? affiliateRewardFor(Challenge challenge) {
  if (!challenge.isSponsored) return null;
  final url = challenge.affiliateUrl?.trim() ?? '';
  if (url.isEmpty) return null;

  final rewardDescription = challenge.rewardDescription?.trim();
  final title = (rewardDescription != null && rewardDescription.isNotEmpty)
      ? rewardDescription
      : (challenge.reward.trim().isNotEmpty ? challenge.reward.trim() : 'Sponsor reward');

  final sponsorName = challenge.sponsor?.trim();
  final sponsor = (sponsorName != null && sponsorName.isNotEmpty)
      ? sponsorName
      : 'Sponsor';

  return AffiliateReward(
    url: url,
    title: title,
    sponsor: sponsor,
    network: challenge.affiliateNetwork,
  );
}

/// Whether a challenge's sponsor reward may be claimed (the quest is finished).
bool affiliateRewardClaimable(Challenge challenge) {
  return challenge.status == ChallengeStatus.completed ||
      challenge.currentDay >= challenge.totalDays;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/domain/services/affiliate_reward_test.dart`
Expected: PASS (all 7 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/domain/services/affiliate_reward.dart test/features/social/domain/services/affiliate_reward_test.dart
git commit -m "feat(social): pure affiliate reward helper for sponsored challenges"
```

---

### Task 2: Affiliate reward service (URL open + analytics)

**Files:**
- Create: `lib/features/social/data/services/affiliate_reward_service.dart`
- Test: `test/features/social/data/services/affiliate_reward_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/social/data/services/affiliate_reward_service_test.dart`:

```dart
import 'package:emerge_app/features/social/data/services/affiliate_reward_service.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/services/affiliate_reward.dart';
import 'package:flutter_test/flutter_test.dart';

const _challenge = Challenge(
  id: 'c1',
  title: '30-Day Run',
  description: 'desc',
  imageUrl: '',
  reward: 'Test Reward',
  participants: 10,
  daysLeft: 0,
  totalDays: 7,
  currentDay: 7,
  status: ChallengeStatus.completed,
  xpReward: 250,
  steps: [],
  category: ChallengeCategory.fitness,
  sponsor: 'Nike',
  isSponsored: true,
  affiliateUrl: 'https://example.com/reward',
  rewardDescription: '20% off Nike',
  affiliateNetwork: AffiliateNetwork.direct,
);

void main() {
  test('logs affiliate_link_clicked then opens the url', () async {
    Uri? openedUri;
    String? loggedName;
    Map<String, Object>? loggedParams;
    final service = AffiliateRewardService(
      openUrl: (uri) async {
        openedUri = uri;
        return true;
      },
      logEvent: (name, params) async {
        loggedName = name;
        loggedParams = params;
      },
    );

    final ok = await service.claimReward(
      challenge: _challenge,
      reward: affiliateRewardFor(_challenge)!,
      userId: 'user_1',
    );

    expect(ok, isTrue);
    expect(openedUri, Uri.parse('https://example.com/reward'));
    expect(loggedName, 'affiliate_link_clicked');
    expect(loggedParams!['challenge_id'], 'c1');
    expect(loggedParams!['challenge_name'], '30-Day Run');
    expect(loggedParams!['partner_name'], 'Nike');
    expect(loggedParams!['affiliate_network'], 'direct');
    expect(loggedParams!['has_affiliate'], true);
    expect(loggedParams!['user_id'], 'user_1');
  });

  test('does not open urls with non-http schemes', () async {
    var opened = false;
    final service = AffiliateRewardService(
      openUrl: (uri) async {
        opened = true;
        return true;
      },
      logEvent: (name, params) async {},
    );
    const reward = AffiliateReward(
      url: 'javascript:alert(1)',
      title: 'x',
      sponsor: 'y',
      network: AffiliateNetwork.none,
    );

    final ok = await service.claimReward(challenge: _challenge, reward: reward);

    expect(ok, isFalse);
    expect(opened, isFalse);
  });

  test('returns false when the opener fails', () async {
    final service = AffiliateRewardService(
      openUrl: (uri) async => false,
      logEvent: (name, params) async {},
    );

    final ok = await service.claimReward(
      challenge: _challenge,
      reward: affiliateRewardFor(_challenge)!,
    );

    expect(ok, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/data/services/affiliate_reward_service_test.dart`
Expected: FAIL — `Error: Error when reading 'lib/features/social/data/services/affiliate_reward_service.dart': No such file or directory`

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/social/data/services/affiliate_reward_service.dart`:

```dart
import 'package:emerge_app/core/services/analytics_events.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/services/affiliate_reward.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UrlOpener = Future<bool> Function(Uri uri);
typedef EventLogger = Future<void> Function(String name, Map<String, Object> parameters);

/// Opens a sponsored challenge's affiliate reward link and records the click.
///
/// Side effects are injected so the service is testable without Firebase or
/// the platform URL launcher.
class AffiliateRewardService {
  AffiliateRewardService({UrlOpener? openUrl, EventLogger? logEvent})
      : _openUrl = openUrl ?? _defaultOpenUrl,
        _logEvent = logEvent ?? _defaultLogEvent;

  final UrlOpener _openUrl;
  final EventLogger _logEvent;

  static Future<bool> _defaultOpenUrl(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  static Future<void> _defaultLogEvent(
    String name,
    Map<String, Object> parameters,
  ) =>
      FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);

  /// Validates the reward URL, records [AnalyticsEvents.affiliateLinkClicked],
  /// then opens the link. Returns whether the link was opened.
  Future<bool> claimReward({
    required Challenge challenge,
    required AffiliateReward reward,
    String? userId,
  }) async {
    try {
      final uri = Uri.tryParse(reward.url);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return false;
      }
      await _logEvent(AnalyticsEvents.affiliateLinkClicked, {
        AnalyticsParameters.challengeId: challenge.id,
        AnalyticsParameters.challengeName: challenge.title,
        AnalyticsParameters.challengeCategory: challenge.category.name,
        AnalyticsParameters.partnerName: reward.sponsor,
        AnalyticsParameters.affiliateNetwork: reward.network.name,
        AnalyticsParameters.rewardDescription: reward.title,
        AnalyticsParameters.hasAffiliate: true,
        if (userId != null) AnalyticsParameters.userId: userId,
        if (challenge.affiliatePartnerId != null)
          AnalyticsParameters.partnerId: challenge.affiliatePartnerId!,
      });
      return _openUrl(uri);
    } catch (_) {
      return false;
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/data/services/affiliate_reward_service_test.dart`
Expected: PASS (all 3 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/data/services/affiliate_reward_service.dart test/features/social/data/services/affiliate_reward_service_test.dart
git commit -m "feat(social): affiliate reward service with click analytics"
```

---

### Task 3: Sponsor reward card widget

**Files:**
- Create: `lib/features/social/presentation/widgets/sponsor_reward_card.dart`
- Test: `test/features/social/presentation/widgets/sponsor_reward_card_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/social/presentation/widgets/sponsor_reward_card_test.dart`:

```dart
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/services/affiliate_reward.dart';
import 'package:emerge_app/features/social/presentation/widgets/sponsor_reward_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const reward = AffiliateReward(
    url: 'https://example.com/reward',
    title: '20% off Nike',
    sponsor: 'Nike',
    network: AffiliateNetwork.direct,
  );

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows reward title, sponsor and sponsor-reward label', (tester) async {
    await tester.pumpWidget(
      wrap(const SponsorRewardCard(reward: reward, claimable: false)),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('SPONSOR REWARD'), findsOneWidget);
    expect(find.text('20% off Nike'), findsOneWidget);
    expect(find.text('by Nike'), findsOneWidget);
  });

  testWidgets('shows claim button when claimable', (tester) async {
    await tester.pumpWidget(
      wrap(const SponsorRewardCard(reward: reward, claimable: true)),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('CLAIM REWARD'), findsOneWidget);
  });

  testWidgets('shows locked state when not claimable', (tester) async {
    await tester.pumpWidget(
      wrap(const SponsorRewardCard(reward: reward, claimable: false)),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Complete this quest to claim your reward'), findsOneWidget);
  });

  testWidgets('fires onClaim when the claim button is tapped', (tester) async {
    var claimed = false;
    await tester.pumpWidget(
      wrap(
        SponsorRewardCard(
          reward: reward,
          claimable: true,
          onClaim: () => claimed = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.text('CLAIM REWARD'));
    expect(claimed, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/widgets/sponsor_reward_card_test.dart`
Expected: FAIL — `Error: Error when reading 'lib/features/social/presentation/widgets/sponsor_reward_card.dart': No such file or directory`

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/social/presentation/widgets/sponsor_reward_card.dart`:

```dart
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/services/affiliate_reward.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

/// Glassmorphic card previewing a sponsored challenge's reward.
///
/// Claiming is only possible once the quest is finished; before that the card
/// shows a locked state so the sponsor stays visible during the quest.
class SponsorRewardCard extends StatelessWidget {
  final AffiliateReward reward;
  final bool claimable;
  final VoidCallback? onClaim;

  const SponsorRewardCard({
    super.key,
    required this.reward,
    required this.claimable,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            EmergeColors.yellow.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: EmergeColors.yellow.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: EmergeColors.yellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium, size: 12, color: EmergeColors.yellow),
                    Gap(4),
                    Text(
                      'SPONSOR REWARD',
                      style: TextStyle(
                        color: EmergeColors.yellow,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (reward.network != AffiliateNetwork.none)
                Text(
                  reward.network.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
          const Gap(12),
          Text(
            reward.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(4),
          Text(
            'by ${reward.sponsor}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
          const Gap(16),
          if (claimable)
            _ClaimButton(onClaim: onClaim)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Complete this quest to claim your reward',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.05);
  }
}

class _ClaimButton extends StatelessWidget {
  final VoidCallback? onClaim;

  const _ClaimButton({this.onClaim});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: EmergeColors.neonGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onClaim,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                'CLAIM REWARD',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/widgets/sponsor_reward_card_test.dart`
Expected: PASS (all 4 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/widgets/sponsor_reward_card.dart test/features/social/presentation/widgets/sponsor_reward_card_test.dart
git commit -m "feat(social): sponsor reward card widget"
```

---

### Task 4: Wire the card into the challenge detail screen

**Files:**
- Modify: `lib/features/social/presentation/screens/challenge_detail_screen.dart`
- Modify: `test/features/social/presentation/screens/challenge_detail_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Add this test to `test/features/social/presentation/screens/challenge_detail_screen_test.dart` (inside `void main()`, after the existing test):

```dart
  testWidgets('shows sponsor reward card with claim button for completed sponsored challenge', (
    tester,
  ) async {
    final sponsored = Challenge(
      id: 'test_sponsored',
      title: 'Sponsored Challenge',
      description: 'A sponsored challenge',
      imageUrl: '',
      reward: 'Voucher',
      participants: 50,
      daysLeft: 0,
      totalDays: 7,
      currentDay: 7,
      status: ChallengeStatus.completed,
      xpReward: 250,
      steps: [
        ChallengeStep(day: 1, title: 'Step One', description: 'Do step one'),
      ],
      category: ChallengeCategory.fitness,
      sponsor: 'Nike',
      isSponsored: true,
      affiliateUrl: 'https://example.com/reward',
      rewardDescription: '20% off Nike',
      affiliateNetwork: AffiliateNetwork.direct,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ChallengeDetailScreen(challenge: sponsored),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('SPONSOR REWARD'), findsOneWidget);
    expect(find.text('20% off Nike'), findsOneWidget);
    expect(find.text('CLAIM REWARD'), findsOneWidget);
  });
```

Note: `AffiliateNetwork` is already exported by `package:emerge_app/features/social/domain/models/challenge.dart`, which this test file already imports.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/screens/challenge_detail_screen_test.dart`
Expected: FAIL — `expect(find.text('SPONSOR REWARD'), findsOneWidget)` finds nothing

- [ ] **Step 3: Implement the wiring**

In `lib/features/social/presentation/screens/challenge_detail_screen.dart`:

1. Add imports after line 15 (`import '...quest_confirmation_sheet.dart';`):

```dart
import 'package:emerge_app/features/social/data/services/affiliate_reward_service.dart';
import 'package:emerge_app/features/social/domain/services/affiliate_reward.dart';
import 'package:emerge_app/features/social/presentation/widgets/sponsor_reward_card.dart';
```

2. Inside the `data: (challenge)` builder, after the two lines computing `progress` (currently lines 79-81), add:

```dart
        final affiliateReward = affiliateRewardFor(challenge);
        final rewardClaimable = affiliateRewardClaimable(challenge);
```

3. In the description `Column`, replace the block ending the description (currently lines 295-296):

```dart
                            ).animate().fadeIn(delay: 400.ms),
                            const Gap(32),
```

with:

```dart
                            ).animate().fadeIn(delay: 400.ms),
                            if (affiliateReward != null) ...[
                              const Gap(20),
                              SponsorRewardCard(
                                reward: affiliateReward,
                                claimable: rewardClaimable,
                                onClaim: () => _claimAffiliateReward(
                                  context,
                                  challenge,
                                  affiliateReward,
                                ),
                              ),
                            ],
                            const Gap(32),
```

4. Add this method after `_executeDayCompletion` (after line 671):

```dart
  Future<void> _claimAffiliateReward(
    BuildContext screenContext,
    Challenge challenge,
    AffiliateReward reward,
  ) async {
    final user = ref.read(authStateChangesProvider).value;
    final service = AffiliateRewardService();
    final launched = await service.claimReward(
      challenge: challenge,
      reward: reward,
      userId: user?.id,
    );
    if (!launched && screenContext.mounted) {
      ScaffoldMessenger.of(screenContext).showSnackBar(
        const SnackBar(
          content: Text('Could not open the reward link. Try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/social/presentation/screens/challenge_detail_screen_test.dart`
Expected: PASS (both tests — original render test and the new sponsored test)

Run: `flutter test test/features/social/presentation/widgets/sponsor_reward_card_test.dart test/features/social/data/services/affiliate_reward_service_test.dart test/features/social/domain/services/affiliate_reward_test.dart`
Expected: PASS (all new tests still green)

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/screens/challenge_detail_screen.dart test/features/social/presentation/screens/challenge_detail_screen_test.dart
git commit -m "feat(social): surface sponsor reward card on challenge detail"
```

---

### Task 5: Static analysis + focused verification

**Files:** none (verification only)

- [ ] **Step 1: Run static analysis**

Run: `dart analyze lib/features/social test/features/social`
Expected: `No issues found!` If the analyzer flags unused imports or style issues in the new files, fix them and re-run.

- [ ] **Step 2: Run all focused tests fresh**

Run: `flutter test test/features/social/domain/services/affiliate_reward_test.dart test/features/social/data/services/affiliate_reward_service_test.dart test/features/social/presentation/widgets/sponsor_reward_card_test.dart test/features/social/presentation/screens/challenge_detail_screen_test.dart`
Expected: PASS (all tests, zero failures)

- [ ] **Step 3: Final commit of any analyze fixes**

If Step 1 changed files:

```bash
git add -A lib/features/social test/features/social
git commit -m "chore(social): analyzer cleanups for affiliate reward"
```

---

## Notes for the implementer

- Do NOT run the full test suite — only the focused files listed above, plus `dart analyze`.
- Never hand-edit `*.g.dart` files; this plan creates none.
- `EmergeColors.yellow` and `EmergeColors.neonGradient` are existing tokens (verified in `challenge_detail_screen.dart` and `emerge_colors.dart`).
- `url_launcher` and `firebase_analytics` are existing dependencies — no `pubspec.yaml` change.
- After completion, the spec's remaining reforms (quiz landing page, recap 9:16 export, referral UI, week-1 loop) each get their own plan.
