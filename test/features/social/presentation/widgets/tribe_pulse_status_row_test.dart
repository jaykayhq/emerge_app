import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_pulse_status_row.dart';

final testUserClub = Tribe(
  id: 'tribe_athlete',
  name: 'Iron Vanguard',
  description: '',
  imageUrl: '',
  memberCount: 12,
  ownerId: 'owner_1',
  tags: const [],
  levelRequirement: 0,
  rank: 1,
  totalXp: 0,
  archetypeId: 'athlete',
);

UserProfile makeProfile({int momentumScore = 50, int streak = 7}) {
  return UserProfile(
    uid: 'test_user',
    displayName: 'Test User',
    archetype: UserArchetype.athlete,
    avatarStats: UserAvatarStats(streak: streak, momentumScore: momentumScore),
  );
}

Challenge makeChallenge({
  required String id,
  required ChallengeStatus status,
}) {
  return Challenge(
    id: id,
    title: 'C $id',
    description: '',
    imageUrl: '',
    reward: '',
    participants: 0,
    daysLeft: 0,
    totalDays: 1,
    currentDay: 1,
    status: status,
    xpReward: 0,
    steps: const [],
  );
}

Widget buildPulseTest({
  required UserProfile profile,
  Stream<List<Map<String, dynamic>>>? activityStream,
  List<Challenge>? challenges,
}) {
  final overrideChallenges = challenges ?? <Challenge>[];
  final overrideActivity = activityStream ?? const Stream<List<Map<String, dynamic>>>.empty();
  return ProviderScope(
    overrides: [
      clubActivityProvider.overrideWith((ref, _) => overrideActivity),
      userChallengesProvider.overrideWith((ref) async => overrideChallenges),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: TribePulseStatusRow(userClub: testUserClub, profile: profile),
      ),
    ),
  );
}

void main() {
  testWidgets('renders all four chip labels', (tester) async {
    await tester.pumpWidget(buildPulseTest(profile: makeProfile()));
    await tester.pump();

    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('MOMENTUM'), findsOneWidget);
    expect(find.text('STREAK'), findsOneWidget);
    expect(find.text('QUESTS'), findsOneWidget);
  });

  testWidgets('LIVE chip shows activity count from stream', (tester) async {
    final stream = Stream<List<Map<String, dynamic>>>.value([
      {'type': 'habit_complete'},
      {'type': 'level_up'},
      {'type': 'badge_earned'},
    ]);
    await tester.pumpWidget(
      buildPulseTest(profile: makeProfile(), activityStream: stream),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('3 signals'), findsOneWidget);
  });

  testWidgets('QUESTS chip counts only active challenges', (tester) async {
    final challenges = [
      makeChallenge(id: 'a', status: ChallengeStatus.active),
      makeChallenge(id: 'b', status: ChallengeStatus.active),
      makeChallenge(id: 'c', status: ChallengeStatus.active),
      makeChallenge(id: 'd', status: ChallengeStatus.completed),
      makeChallenge(id: 'e', status: ChallengeStatus.featured),
    ];
    await tester.pumpWidget(
      buildPulseTest(profile: makeProfile(), challenges: challenges),
    );
    await tester.pump();

    expect(find.text('3 active'), findsOneWidget);
  });

  testWidgets('STREAK chip shows days from avatarStats.streak', (tester) async {
    await tester.pumpWidget(buildPulseTest(profile: makeProfile(streak: 12)));
    await tester.pump();

    expect(find.text('12d'), findsOneWidget);
  });

  testWidgets('MOMENTUM chip shows onFire label at high score', (tester) async {
    await tester.pumpWidget(buildPulseTest(profile: makeProfile(momentumScore: 95)));
    await tester.pump();

    expect(find.text('On Fire'), findsOneWidget);
  });

  testWidgets('MOMENTUM chip shows Strong label at high-mid score', (tester) async {
    await tester.pumpWidget(buildPulseTest(profile: makeProfile(momentumScore: 75)));
    await tester.pump();

    expect(find.text('Strong'), findsOneWidget);
  });

  testWidgets('MOMENTUM chip shows Building label at mid score', (tester) async {
    await tester.pumpWidget(buildPulseTest(profile: makeProfile(momentumScore: 55)));
    await tester.pump();

    expect(find.text('Building'), findsOneWidget);
  });

  testWidgets('MOMENTUM chip shows At Risk label at low-mid score', (tester) async {
    await tester.pumpWidget(buildPulseTest(profile: makeProfile(momentumScore: 35)));
    await tester.pump();

    expect(find.text('At Risk'), findsOneWidget);
  });

  testWidgets('MOMENTUM chip shows Recovery label at low score', (tester) async {
    await tester.pumpWidget(buildPulseTest(profile: makeProfile(momentumScore: 15)));
    await tester.pump();

    expect(find.text('Recovery'), findsOneWidget);
  });

  testWidgets('MOMENTUM chip shows Reset label at zero score', (tester) async {
    await tester.pumpWidget(buildPulseTest(profile: makeProfile(momentumScore: 5)));
    await tester.pump();

    expect(find.text('Reset'), findsOneWidget);
  });

  testWidgets('LIVE chip navigates to /social/activity, not /social/accountability',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: TribePulseStatusRow(
              userClub: testUserClub,
              profile: makeProfile(),
            ),
          ),
        ),
        GoRoute(
          path: '/social/activity',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('ACTIVITY_SCREEN'))),
        ),
        GoRoute(
          path: '/social/accountability',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('FRIENDS_SCREEN'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubActivityProvider.overrideWith(
            (ref, _) => Stream.value([
              {'type': 'habit_complete'},
            ]),
          ),
          userChallengesProvider.overrideWith((ref) async => <Challenge>[]),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    // Tap the LIVE chip (it shows the label 'LIVE' and a value text).
    await tester.tap(find.text('LIVE'));
    await tester.pumpAndSettle();

    expect(find.text('ACTIVITY_SCREEN'), findsOneWidget);
    expect(find.text('FRIENDS_SCREEN'), findsNothing);
  });
}
