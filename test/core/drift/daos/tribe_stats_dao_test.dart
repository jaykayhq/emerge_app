import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/daos/tribe_stats_dao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TribeStatsDao dao;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    dao = TribeStatsDao(db);
  });

  tearDown(() => db.close());

  test('incrementContribution creates a row when none exists', () async {
    await dao.incrementContribution(
      'creator_tribe_1',
      xp: 25,
      habits: 3,
      challenges: 1,
    );

    final stats = await dao.getStats('creator_tribe_1');
    expect(stats, isNotNull);
    expect(stats!.totalXp, 25);
    expect(stats.totalHabitsCompleted, 3);
    expect(stats.totalChallengesCompleted, 1);
    expect(stats.userContributionXp, 25);
    expect(stats.userHabitsCompleted, 3);
    expect(stats.userChallengesCompleted, 1);
    // Creator tribes have no archetype — null must not break anything.
    expect(stats.archetypeId, isNull);
    expect(stats.memberCount, 0);
  });

  test('incrementMemberCount creates a row when none exists', () async {
    await dao.incrementMemberCount('creator_tribe_1', delta: 1);

    final stats = await dao.getStats('creator_tribe_1');
    expect(stats, isNotNull);
    expect(stats!.memberCount, 1);
    expect(stats.archetypeId, isNull);
  });

  test('incrementContribution increments an existing row', () async {
    await dao.upsertStats(
      TribeStatsTableCompanion(
        tribeId: const Value('tribeA'),
        totalXp: const Value(10),
        totalHabitsCompleted: const Value(2),
        totalChallengesCompleted: const Value(0),
        userContributionXp: const Value(10),
        userHabitsCompleted: const Value(2),
        userChallengesCompleted: const Value(0),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );

    await dao.incrementContribution('tribeA', xp: 25, habits: 3, challenges: 1);

    final stats = await dao.getStats('tribeA');
    expect(stats, isNotNull);
    expect(stats!.totalXp, 35);
    expect(stats.totalHabitsCompleted, 5);
    expect(stats.totalChallengesCompleted, 1);
    expect(stats.userContributionXp, 35);
  });
}
