import 'dart:async';
import 'package:emerge_app/core/drift/database.dart' hide isNull, isNotNull;
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/domain/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTribeMembershipDao extends Mock implements TribeMembershipDao {}
class MockChallengeRepository extends Mock implements ChallengeRepository {}

const _testMembership = UserTribeTableData(
  userId: 'u1',
  tribeId: 'tribe-athlete',
  membershipType: 'member',
  joinedAt: '2024-01-01',
  isActive: true,
);

/// Tribe data matching the membership, exposing archetypeId for filtering.
Tribe _testTribe() => Tribe(
  id: 'tribe-athlete',
  name: 'Athlete Club',
  description: '',
  imageUrl: '',
  ownerId: '',
  tags: [],
  levelRequirement: 0,
  rank: 0,
  totalXp: 0,
  memberCount: 0,
  archetypeId: 'athlete',
);

ProviderContainer _makeContainer({
  UserTribeTableData? membership,
}) {
  final dao = MockTribeMembershipDao();
  when(() => dao.watchActiveMembership(any())).thenAnswer(
    (_) => Stream.value(membership),
  );
  return ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWithValue(
        AsyncValue.data(const AuthUser(id: 'u1', email: 'u1@test.com')),
      ),
      tribeMembershipDaoProvider.overrideWithValue(dao),
    ],
  );
}

Future<T> _streamFirst<T>(StreamProvider<T> provider, ProviderContainer container) {
  final completer = Completer<T>();
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

void main() {
  group('activeMembershipProvider', () {
    test('returns null when dao returns null', () async {
      final container = _makeContainer(membership: null);
      final result = await _streamFirst(activeMembershipProvider, container);
      expect(result, isNull);
      container.dispose();
    });

    test('returns membership when user has active tribe', () async {
      final container = _makeContainer(membership: _testMembership);
      final result = await _streamFirst(activeMembershipProvider, container);
      expect(result, isNotNull);
      expect(result!.tribeId, 'tribe-athlete');
      expect(result.isActive, isTrue);
      container.dispose();
    });
  });

  group('tribeCircleProvider', () {
    test('returns empty list when no membership', () async {
      final container = _makeContainer(membership: null);
      final result = await _streamFirst(tribeCircleProvider, container);
      expect(result, isEmpty);
      container.dispose();
    });
  });

  group('tribeChallengesProvider', () {
    test('returns empty list when no membership', () async {
      final mockRepo = MockChallengeRepository();
      when(() => mockRepo.getChallenges(featuredOnly: false))
          .thenAnswer((_) async => []);
      final dao = MockTribeMembershipDao();
      when(() => dao.watchActiveMembership(any())).thenAnswer(
        (_) => Stream.value(null),
      );
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            AsyncValue.data(const AuthUser(id: 'u1', email: 'u1@test.com')),
          ),
          tribeMembershipDaoProvider.overrideWithValue(dao),
          challengeRepositoryProvider.overrideWithValue(mockRepo),
          allArchetypeClubsProvider.overrideWithValue(
            const AsyncValue<List<Tribe>>.data([]),
          ),
        ],
      );
      final result = await _streamFirst(tribeChallengesProvider, container);
      expect(result, isEmpty);
      container.dispose();
    });

    test('filters challenges by tribe archetype', () async {
      final mockRepo = MockChallengeRepository();
      when(() => mockRepo.getChallenges(featuredOnly: false)).thenAnswer(
        (_) async => [
          Challenge(
            id: 'c1',
            title: 'Athlete Challenge',
            description: '',
            imageUrl: '',
            reward: '',
            participants: 0,
            daysLeft: 7,
            totalDays: 7,
            currentDay: 1,
            status: ChallengeStatus.featured,
            xpReward: 100,
            steps: [],
            archetypeId: 'athlete',
          ),
          Challenge(
            id: 'c2',
            title: 'Stoic Challenge',
            description: '',
            imageUrl: '',
            reward: '',
            participants: 0,
            daysLeft: 7,
            totalDays: 7,
            currentDay: 1,
            status: ChallengeStatus.featured,
            xpReward: 100,
            steps: [],
            archetypeId: 'stoic',
          ),
          Challenge(
            id: 'c3',
            title: 'No Archetype',
            description: '',
            imageUrl: '',
            reward: '',
            participants: 0,
            daysLeft: 7,
            totalDays: 7,
            currentDay: 1,
            status: ChallengeStatus.featured,
            xpReward: 100,
            steps: [],
          ),
        ],
      );
      final dao = MockTribeMembershipDao();
      when(() => dao.watchActiveMembership(any())).thenAnswer(
        (_) => Stream.value(_testMembership),
      );
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            AsyncValue.data(const AuthUser(id: 'u1', email: 'u1@test.com')),
          ),
          tribeMembershipDaoProvider.overrideWithValue(dao),
          challengeRepositoryProvider.overrideWithValue(mockRepo),
          allArchetypeClubsProvider.overrideWithValue(
            AsyncValue.data([_testTribe()]),
          ),
        ],
      );
      final result = await _streamFirst(tribeChallengesProvider, container);
      expect(result.length, 2);
      expect(result.any((c) => c.id == 'c1'), isTrue);
      expect(result.any((c) => c.id == 'c3'), isTrue);
      container.dispose();
    });
  });
}
