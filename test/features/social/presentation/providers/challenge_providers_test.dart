import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChallengeRepository extends Mock implements ChallengeRepository {}

ProviderContainer _makeContainer({
  required ChallengeRepository challengeRepo,
  AuthUser? authUser,
  UserProfile? profile,
}) {
  return ProviderContainer(
    overrides: [
      challengeRepositoryProvider.overrideWithValue(challengeRepo),
      authStateChangesProvider.overrideWithValue(
        AsyncValue.data(authUser ?? const AuthUser(id: 'test', email: 'test@example.com')),
      ),
      if (profile != null)
        userStatsStreamProvider.overrideWith((ref) => Stream.value(profile)),
    ],
  );
}

void main() {
  late MockChallengeRepository mockRepo;

  setUp(() {
    mockRepo = MockChallengeRepository();
  });

  group('challengeRepositoryProvider', () {
    test('creates repository instance', () {
      final container = _makeContainer(challengeRepo: mockRepo);
      expect(container.read(challengeRepositoryProvider), mockRepo);
      container.dispose();
    });
  });

  group('featuredChallengesProvider', () {
    test('returns list of challenges', () async {
      when(() => mockRepo.getChallenges(featuredOnly: true)).thenAnswer((_) async => []);
      final container = _makeContainer(challengeRepo: mockRepo);
      final result = await container.read(featuredChallengesProvider.future);
      expect(result, isA<List>());
      container.dispose();
    });
  });

  group('allChallengesProvider', () {
    test('returns all challenges', () async {
      when(() => mockRepo.getChallenges(featuredOnly: false)).thenAnswer((_) async => []);
      final container = _makeContainer(challengeRepo: mockRepo);
      final result = await container.read(allChallengesProvider.future);
      expect(result, isA<List>());
      container.dispose();
    });
  });

  group('userChallengesProvider', () {
    test('returns empty when no user', () async {
      final container = ProviderContainer(
        overrides: [
          challengeRepositoryProvider.overrideWithValue(mockRepo),
          authStateChangesProvider.overrideWithValue(
            const AsyncValue<AuthUser>.loading(),
          ),
        ],
      );
      final result = await container.read(userChallengesProvider.future);
      expect(result, []);
      container.dispose();
    });

    test('returns challenges for user', () async {
      when(() => mockRepo.getUserChallenges('test')).thenAnswer((_) async => []);
      final container = _makeContainer(challengeRepo: mockRepo);
      final result = await container.read(userChallengesProvider.future);
      expect(result, isA<List>());
      container.dispose();
    });
  });

  group('archetypeChallengesProvider', () {
    test('returns challenges matching archetype', () async {
      when(() => mockRepo.getChallengesByArchetype('athlete')).thenAnswer((_) async => []);
      final container = _makeContainer(
        challengeRepo: mockRepo,
        profile: const UserProfile(uid: 'test', archetype: UserArchetype.athlete),
      );
      final result = await container.read(archetypeChallengesProvider.future);
      expect(result, isA<List>());
      container.dispose();
    });
  });

  group('dailyQuestProvider', () {
    test('returns a challenge', () async {
      final container = _makeContainer(
        challengeRepo: mockRepo,
        profile: const UserProfile(uid: 'test', archetype: UserArchetype.athlete),
      );
      final result = await container.read(dailyQuestProvider.future);
      expect(result, isA<Challenge?>());
      container.dispose();
    });
  });

  group('challengeByIdProvider', () {
    test('returns challenge by ID', () async {
      when(() => mockRepo.getChallengeById('ch-1')).thenAnswer((_) async => null);
      final container = _makeContainer(challengeRepo: mockRepo);
      final result = await container.read(challengeByIdProvider('ch-1').future);
      expect(result, isNull);
      container.dispose();
    });
  });

  group('filteredChallengesProvider', () {
    test('returns filtered list', () async {
      when(() => mockRepo.getChallenges(featuredOnly: true)).thenAnswer((_) async => []);
      when(() => mockRepo.getUserChallenges('test')).thenAnswer((_) async => []);
      final container = _makeContainer(challengeRepo: mockRepo);
      final result = await container.read(
        filteredChallengesProvider(ChallengeStatus.active).future,
      );
      expect(result, isA<List>());
      container.dispose();
    });
  });

  group('creatorAuthoredChallengesProvider', () {
    Map<String, dynamic> challengeMap({required String createdBy}) => {
      'title': 'Creator Challenge',
      'description': 'Desc',
      'imageUrl': 'img.png',
      'reward': '100xp',
      'participants': 0,
      'daysLeft': 7,
      'totalDays': 7,
      'currentDay': 0,
      'status': 'active',
      'xpReward': 100,
      'category': 'fitness',
      'affiliateNetwork': 'none',
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(DateTime(2026, 8, 1)),
      'steps': <Map<String, dynamic>>[],
    };

    Future<List<Challenge>> streamFirst(
      StreamProvider<List<Challenge>> provider,
      ProviderContainer container,
    ) {
      final completer = Completer<List<Challenge>>();
      final sub = container.listen(provider, (_, next) {
        if (next.hasValue && !completer.isCompleted) {
          completer.complete(next.requireValue);
        }
      });
      return completer.future.then((v) {
        sub.close();
        return v;
      });
    }

    test('streams only challenges authored by the given uid', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('challenges').doc('mine').set(
        challengeMap(createdBy: 'creator-1'),
      );
      await fakeFirestore.collection('challenges').doc('theirs').set(
        challengeMap(createdBy: 'creator-2'),
      );

      final container = ProviderContainer(
        overrides: [firestoreProvider.overrideWithValue(fakeFirestore)],
      );
      addTearDown(container.dispose);

      final challenges = await streamFirst(
        creatorAuthoredChallengesProvider('creator-1'),
        container,
      );

      expect(challenges, hasLength(1));
      expect(challenges.single.createdBy, 'creator-1');
      expect(challenges.single.title, 'Creator Challenge');
      // Server-written docs materialize createdAt as a Timestamp; the
      // provider's fromMap path must parse it without crashing.
      expect(challenges.single.createdAt, DateTime(2026, 8, 1));
    });

    test('emits empty list when the creator has no challenges', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final container = ProviderContainer(
        overrides: [firestoreProvider.overrideWithValue(fakeFirestore)],
      );
      addTearDown(container.dispose);

      final challenges = await streamFirst(
        creatorAuthoredChallengesProvider('creator-1'),
        container,
      );
      expect(challenges, isEmpty);
    });

    test('returns empty stream for an empty uid', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final challenges = await streamFirst(
        creatorAuthoredChallengesProvider(''),
        container,
      );
      expect(challenges, isEmpty);
    });
  });
}
