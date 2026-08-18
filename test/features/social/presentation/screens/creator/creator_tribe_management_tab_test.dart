import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_tribe_management_tab.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

/// In-memory [ChallengeRepository] that records catalog challenges and
/// exposes them through a stream, so a widget test can drive the real
/// create-challenge dialog and observe the published challenge arrive in
/// the creator's list (mirroring the Firestore stream the production
/// provider uses).
class _FakeChallengeRepository implements ChallengeRepository {
  final _challenges = <Challenge>[];
  final _controller = StreamController<List<Challenge>>.broadcast();

  @override
  Future<String> createCatalogChallenge(Challenge challenge) async {
    publish(challenge.copyWith(id: 'creator_ch_${_challenges.length + 1}'));
    return _challenges.last.id;
  }

  /// Adds [challenge] to the store and notifies listeners (the production
  /// counterpart is the Firestore snapshots stream emitting the new doc).
  void publish(Challenge challenge) {
    _challenges.add(challenge);
    _controller.add(List.unmodifiable(_challenges));
  }

  /// Emits the current store contents (used to drive the empty state).
  void emit() => _controller.add(List.unmodifiable(_challenges));

  @override
  Future<List<Challenge>> getChallenges({bool featuredOnly = false}) async =>
      [];

  @override
  Future<List<Challenge>> getUserChallenges(String userId) async => [];

  @override
  Future<List<Challenge>> getChallengesByArchetype(String archetypeId) async =>
      [];

  Stream<List<Challenge>> watchCreatorChallenges(String uid) =>
      _controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _creatorProfile = CreatorProfile(
  userId: 'creator-1',
  tribeId: 'tribe_creator_1',
);

Challenge _challenge(String title) => Challenge(
  id: 'ch_$title',
  title: title,
  description: 'Desc',
  imageUrl: 'img.png',
  reward: '100xp',
  participants: 0,
  daysLeft: 7,
  totalDays: 7,
  currentDay: 0,
  status: ChallengeStatus.active,
  xpReward: 100,
  steps: const [],
  createdBy: 'creator-1',
);

Widget _buildTest({
  required ChallengeRepository challengeRepo,
  required Stream<List<Challenge>> challengesStream,
}) {
  return ProviderScope(
    overrides: [
      creatorProfileProvider.overrideWith(
        (ref, uid) => Stream.value(_creatorProfile),
      ),
      realTimeTribeStatsProvider.overrideWith(
        (ref, tribeId) => const Stream.empty(),
      ),
      creatorAuthoredChallengesProvider.overrideWith(
        (ref, uid) => challengesStream,
      ),
      challengeRepositoryProvider.overrideWithValue(challengeRepo),
    ],
    child: const MaterialApp(home: CreatorTribeManagementTab()),
  );
}

Widget _buildEmptyTest() {
  return ProviderScope(
    overrides: [
      creatorProfileProvider.overrideWith((ref, uid) => Stream.value(null)),
      realTimeTribeStatsProvider.overrideWith(
        (ref, tribeId) => const Stream.empty(),
      ),
    ],
    child: const MaterialApp(home: CreatorTribeManagementTab()),
  );
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('CreatorTribeManagementTab renders no-tribe state', (
    tester,
  ) async {
    await tester.pumpWidget(_buildEmptyTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No Tribe Yet'), findsOneWidget);
    expect(
      find.text(
        'Publish a blueprint to automatically create your creator tribe.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders creator-published challenges in the tribe tab', (
    tester,
  ) async {
    final repo = _FakeChallengeRepository();
    await tester.pumpWidget(
      _buildTest(
        challengeRepo: repo,
        challengesStream: repo.watchCreatorChallenges('creator-1'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    repo.publish(_challenge('30-Day Art Sprint'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MY CHALLENGES'), findsOneWidget);
    expect(find.text('30-Day Art Sprint'), findsOneWidget);
  });

  testWidgets('shows an empty state when the creator has no challenges', (
    tester,
  ) async {
    final repo = _FakeChallengeRepository();
    await tester.pumpWidget(
      _buildTest(
        challengeRepo: repo,
        challengesStream: repo.watchCreatorChallenges('creator-1'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    repo.emit();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('No challenges published yet'), findsOneWidget);
  });

  testWidgets(
    'publishing a challenge from the dialog makes it appear in the list',
    (tester) async {
      final repo = _FakeChallengeRepository();
      await tester.pumpWidget(
        _buildTest(
          challengeRepo: repo,
          challengesStream: repo.watchCreatorChallenges('creator-1'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Open the create-challenge dialog from the Quick Actions card.
      await tester.tap(find.text('Create Challenge'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField).first, 'My New Challenge');
      await tester.tap(find.text('Publish Challenge'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The published challenge must now be visible in the creator's list.
      expect(find.text('My New Challenge'), findsOneWidget);
    },
  );
}
