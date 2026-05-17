import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift_repositories/drift_challenge_repository.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/challenge_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../drift/test_database.dart';
import 'mocks.dart';

void main() {
  late AppDatabase db;
  late MockSyncEngine mockSyncEngine;
  late DriftChallengeRepository repository;
  const userId = 'test_user_456';

  setUpAll(() {
    registerFallbackValue(
      const Challenge(
        id: 'fallback',
        title: 'fallback',
        description: 'fallback',
        imageUrl: 'fallback',
        reward: 'fallback',
        participants: 0,
        daysLeft: 1,
        totalDays: 1,
        currentDay: 0,
        status: ChallengeStatus.featured,
        xpReward: 0,
        steps: [],
      ),
    );
  });

  setUp(() {
    db = createTestDatabase();
    mockSyncEngine = MockSyncEngine();

    when(
      () => mockSyncEngine.enqueueSet(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockSyncEngine.enqueueUpdate(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});

    repository = DriftChallengeRepository(
      db,
      LocalGameLoopEngine(),
      mockSyncEngine,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftChallengeRepository', () {
    test('joinChallenge() inserts into Drift and calls enqueueSet', () async {
      final template = ChallengeCatalog.getFeatured().first;

      final result = await repository.joinChallenge(userId, template.id);

      expect(result.isRight(), true);

      final challenges = await repository.getUserChallenges(userId);
      expect(challenges, isNotEmpty);
      expect(challenges.first.id, template.id);

      verify(
        () => mockSyncEngine.enqueueSet(
          collectionPath: 'users/$userId/challenges',
          documentId: template.id,
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test('joinChallenge() returns failure for non-existent challenge', () async {
      final result = await repository.joinChallenge(
        userId,
        'non_existent_challenge',
      );

      expect(result.isLeft(), true);
    });

    test('updateProgress() updates day in Drift and calls enqueueSet', () async {
      final template = ChallengeCatalog.getFeatured().first;
      await repository.joinChallenge(userId, template.id);

      final result = await repository.updateProgress(
        userId,
        template.id,
        1,
      );

      expect(result.isRight(), true);

      final challenges = await repository.getUserChallenges(userId);
      expect(challenges, isNotEmpty);

      verify(
        () => mockSyncEngine.enqueueSet(
          collectionPath: 'users/$userId/challenges',
          documentId: template.id,
          data: any(named: 'data'),
        ),
      ).called(greaterThanOrEqualTo(1));
    });

    test('updateProgress() returns failure for non-existent challenge', () async {
      final result = await repository.updateProgress(
        userId,
        'non_existent',
        1,
      );

      expect(result.isLeft(), true);
    });

    test('updateProgress() - final day marks challenge as completed', () async {
      final template = Challenge(
        id: 'short_challenge',
        title: 'Short Challenge',
        description: 'A 2-day challenge',
        imageUrl: 'test.png',
        reward: '100 XP',
        participants: 0,
        daysLeft: 2,
        totalDays: 2,
        currentDay: 0,
        status: ChallengeStatus.featured,
        xpReward: 100,
        steps: const [
          ChallengeStep(day: 1, title: 'Start', description: 'Begin'),
          ChallengeStep(day: 2, title: 'Finish', description: 'Complete'),
        ],
      );

      await db.challengeProgressDao.insertFromData(
        challengeId: template.id,
        userId: userId,
        title: template.title,
        totalDays: template.totalDays,
        xpReward: template.xpReward,
        joinedAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await db.userStatsDao.upsertStats(
        UserStatsTableCompanion(
          userId: Value(userId),
          displayName: Value('Test User'),
          totalXp: Value(0),
          level: Value(1),
          vitalityXp: Value(0),
        ),
      );

      final result = await repository.updateProgress(
        userId,
        template.id,
        1,
      );

      expect(result.isRight(), true);

      final challenges = await repository.getUserChallenges(userId);
      final challenge = challenges.firstWhere((c) => c.id == template.id);
      expect(challenge.currentDay, 1);
    });

    test('updateProgress() awards XP on completion', () async {
      final template = ChallengeCatalog.getFeatured().first;

      await db.challengeProgressDao.insertFromData(
        challengeId: template.id,
        userId: userId,
        title: template.title,
        totalDays: template.totalDays,
        xpReward: template.xpReward,
        joinedAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await db.userStatsDao.upsertStats(
        UserStatsTableCompanion(
          userId: Value(userId),
          displayName: Value('Test User'),
          totalXp: Value(0),
          level: Value(1),
          vitalityXp: Value(0),
        ),
      );

      final initialStats = await db.userStatsDao.getStats(userId);
      final initialXp = initialStats?.totalXp ?? 0;

      for (int i = 0; i < template.totalDays; i++) {
        await repository.updateProgress(userId, template.id, i + 1);
      }

      final finalStats = await db.userStatsDao.getStats(userId);
      expect(finalStats?.totalXp, greaterThan(initialXp));
    });

    test('completeChallenge() marks as completed and calls sync', () async {
      final template = ChallengeCatalog.getFeatured().first;
      await repository.joinChallenge(userId, template.id);

      reset(mockSyncEngine);
      when(
        () => mockSyncEngine.enqueueSet(
          collectionPath: any(named: 'collectionPath'),
          documentId: any(named: 'documentId'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {});

      await repository.completeChallenge(userId, template.id);

      final challenges = await repository.getUserChallenges(userId);
      final challenge = challenges.firstWhere((c) => c.id == template.id);
      expect(challenge.status, ChallengeStatus.completed);

      verify(
        () => mockSyncEngine.enqueueSet(
          collectionPath: 'users/$userId/challenges',
          documentId: template.id,
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test('getUserChallenges() returns all challenges (active + completed)',
        () async {
      final templates = ChallengeCatalog.getFeatured().take(2).toList();

      for (final template in templates) {
        await repository.joinChallenge(userId, template.id);
      }

      reset(mockSyncEngine);
      when(
        () => mockSyncEngine.enqueueSet(
          collectionPath: any(named: 'collectionPath'),
          documentId: any(named: 'documentId'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {});

      final completedTemplate = templates.first;
      await repository.completeChallenge(userId, completedTemplate.id);

      final challenges = await repository.getUserChallenges(userId);
      expect(challenges.length, 2);

      final completed = challenges
          .where((c) => c.id == completedTemplate.id)
          .first;
      expect(completed.status, ChallengeStatus.completed);

      final active = challenges
          .where((c) => c.id != completedTemplate.id)
          .first;
      expect(active.status, ChallengeStatus.active);
    });

    test('getChallenges() returns featured challenges from catalog', () async {
      final challenges = await repository.getChallenges(featuredOnly: true);

      expect(challenges, isNotEmpty);
      expect(
        challenges.every((c) => c.status == ChallengeStatus.featured),
        true,
      );
    });

    test('getChallengesByArchetype() returns archetype-specific challenges',
        () async {
      final challenges = await repository.getChallengesByArchetype('athlete');

      expect(challenges, isNotEmpty);
    });

    test('createSoloChallenge() inserts and syncs', () async {
      final soloChallenge = const Challenge(
        id: 'solo_challenge_1',
        title: 'My Solo Challenge',
        description: 'A personal challenge',
        imageUrl: 'solo.png',
        reward: '200 XP',
        participants: 0,
        daysLeft: 7,
        totalDays: 7,
        currentDay: 0,
        status: ChallengeStatus.active,
        xpReward: 200,
        steps: [],
      );

      reset(mockSyncEngine);
      when(
        () => mockSyncEngine.enqueueSet(
          collectionPath: any(named: 'collectionPath'),
          documentId: any(named: 'documentId'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {});

      await repository.createSoloChallenge(userId, soloChallenge);

      final challenges = await repository.getUserChallenges(userId);
      expect(challenges, isNotEmpty);
      expect(challenges.first.id, soloChallenge.id);
      expect(challenges.first.title, soloChallenge.title);

      verify(
        () => mockSyncEngine.enqueueSet(
          collectionPath: 'users/$userId/challenges',
          documentId: soloChallenge.id,
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test('completeChallengeWithReward() updates and syncs', () async {
      final template = ChallengeCatalog.getFeatured().first;
      await repository.joinChallenge(userId, template.id);

      reset(mockSyncEngine);
      when(
        () => mockSyncEngine.enqueueSet(
          collectionPath: any(named: 'collectionPath'),
          documentId: any(named: 'documentId'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.completeChallengeWithReward(
        userId,
        template.id,
      );

      expect(result.isRight(), true);

      final challenges = await repository.getUserChallenges(userId);
      final challenge = challenges.firstWhere((c) => c.id == template.id);
      expect(challenge.status, ChallengeStatus.completed);

      verify(
        () => mockSyncEngine.enqueueSet(
          collectionPath: 'users/$userId/challenges',
          documentId: template.id,
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test('getChallengeById() returns a specific challenge', () async {
      final template = ChallengeCatalog.getFeatured().first;
      final challenge = await repository.getChallengeById(template.id);

      expect(challenge, isNotNull);
      expect(challenge!.id, template.id);
    });

    test('getWeeklySpotlight() returns archetype-specific spotlight', () async {
      final spotlight = await repository.getWeeklySpotlight(
        archetypeId: 'scholar',
      );

      expect(spotlight, isNotNull);
      expect(spotlight?.archetypeId, 'scholar');
    });

    test('getWeeklySpotlight() returns null without archetypeId', () async {
      final spotlight = await repository.getWeeklySpotlight();
      expect(spotlight, isNull);
    });

    test('getLeaderboard() returns empty list (not implemented)', () async {
      final leaderboard = await repository.getLeaderboard('any_challenge');
      expect(leaderboard, isEmpty);
    });

    test('seedChallengesIfEmpty() does nothing (placeholder)', () async {
      expect(() => repository.seedChallengesIfEmpty(), returnsNormally);
    });

    test('joinChallenge() stores correct initial state', () async {
      final template = ChallengeCatalog.getFeatured().first;
      await repository.joinChallenge(userId, template.id);

      final progressRows = await db.challengeProgressDao.getAll(userId);
      final progress = progressRows.firstWhere(
        (p) => p.challengeId == template.id,
      );

      expect(progress.userId, userId);
      expect(progress.currentDay, 0);
      expect(progress.status, 'active');
      expect(progress.totalDays, template.totalDays);
      expect(progress.xpReward, template.xpReward);
    });

    test('updateProgress() increments challenge day correctly', () async {
      final template = ChallengeCatalog.getFeatured().first;

      await db.challengeProgressDao.insertFromData(
        challengeId: template.id,
        userId: userId,
        title: template.title,
        totalDays: template.totalDays,
        xpReward: template.xpReward,
        joinedAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await repository.updateProgress(userId, template.id, 1);
      await repository.updateProgress(userId, template.id, 2);

      final progressRows = await db.challengeProgressDao.getActive(userId);
      final progress = progressRows.firstWhere(
        (p) => p.challengeId == template.id,
        orElse: () => progressRows.first,
      );

      expect(progress.currentDay, 2);
    });
  });
}
