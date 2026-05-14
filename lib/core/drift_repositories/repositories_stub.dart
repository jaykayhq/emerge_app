/// Web‑safe stubs for all Drift*Repository classes.
///
/// These classes are never instantiated on web — every provider selects
/// Firestore*Repository instead.  They exist only to satisfy the compiler.

import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/core/sync/sync_engine_barrel.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/habit_activity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/domain/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/features/gamification/domain/repositories/user_profile_repository.dart';
import 'package:fpdart/fpdart.dart';

// ---------------------------------------------------------------------------
// DriftHabitRepository
// ---------------------------------------------------------------------------
class DriftHabitRepository implements HabitRepository {
  DriftHabitRepository({
    required AppDatabase db,
    required LocalGameLoopEngine gameLoopEngine,
    required EnhancedSyncEngine syncEngine,
    required SocialActivityService socialService,
  });

  @override
  Future<Either<Failure, Unit>> createHabit(Habit habit) async =>
      Left(ServerFailure('Not available on web'));
  @override
  Future<Either<Failure, Unit>> updateHabit(Habit habit) async =>
      Left(ServerFailure('Not available on web'));
  @override
  Future<Either<Failure, Unit>> deleteHabit(String habitId) async =>
      Left(ServerFailure('Not available on web'));
  @override
  Future<Either<Failure, bool>> completeHabit(
    String habitId,
    DateTime date,
  ) async => Left(ServerFailure('Not available on web'));
  @override
  Future<Habit?> getHabit(String habitId) async => null;
  @override
  Future<List<Habit>> getHabitsByAnchor(String anchorHabitId) async => [];
  @override
  Future<List<HabitActivity>> getActivity(
    String userId,
    DateTime start,
    DateTime end,
  ) async => [];
  @override
  Future<Either<Failure, Unit>> createHabitsFromBlueprint({
    required String userId,
    required Blueprint blueprint,
    String? reminderTime,
  }) async => Left(ServerFailure('Not available on web'));
  @override
  Stream<List<Habit>> watchHabits(String userId) => const Stream.empty();
}

// ---------------------------------------------------------------------------
// DriftTribeRepository (matches TribeRepository interface exactly)
// ---------------------------------------------------------------------------
class DriftTribeRepository implements TribeRepository {
  DriftTribeRepository(AppDatabase db, EnhancedSyncEngine syncEngine);

  @override
  Future<Tribe?> getArchetypeClub(String archetypeId) async => null;
  @override
  Future<List<Tribe>> getArchetypeClubs() async => [];
  @override
  Stream<List<Tribe>> watchArchetypeClubs() => const Stream.empty();
  @override
  Future<List<Map<String, dynamic>>> getClubContributors(
    String tribeId, {
    int limit = 10,
  }) async => [];
  @override
  Future<List<Map<String, dynamic>>> getClubActivity(
    String tribeId, {
    int limit = 20,
  }) async => [];
  @override
  Stream<List<Map<String, dynamic>>> watchClubActivity(
    String tribeId, {
    int limit = 20,
  }) => const Stream.empty();
  @override
  Stream<List<Map<String, dynamic>>> watchGlobalActivity({int limit = 30}) =>
      const Stream.empty();
  @override
  Future<void> joinClub(String userId, String tribeId) async {}
  @override
  Future<void> leaveClub(String userId, String tribeId) async {}
  @override
  Future<List<Tribe>> getUserTribes(String userId) async => [];
  @override
  Future<void> seedTribesIfEmpty() async {}
}

// ---------------------------------------------------------------------------
// DriftChallengeRepository (matches ChallengeRepository interface exactly)
// ---------------------------------------------------------------------------
class DriftChallengeRepository implements ChallengeRepository {
  DriftChallengeRepository(
    AppDatabase db,
    LocalGameLoopEngine engine,
    EnhancedSyncEngine syncEngine,
  );

  @override
  Future<List<Challenge>> getChallenges({bool featuredOnly = false}) async => [];
  @override
  Future<List<Challenge>> getUserChallenges(String userId) async => [];
  @override
  Future<Either<Failure, Unit>> joinChallenge(
    String userId,
    String challengeId,
  ) async => Left(ServerFailure('Not available on web'));
  @override
  Future<void> createSoloChallenge(
    String userId,
    Challenge challenge,
  ) async {}
  @override
  Future<Either<Failure, Unit>> updateProgress(
    String userId,
    String challengeId,
    int progress,
  ) async => Left(ServerFailure('Not available on web'));
  @override
  Future<void> completeChallenge(String userId, String challengeId) async {}
  @override
  Future<Either<Failure, Unit>> completeChallengeWithReward(
    String userId,
    String challengeId,
  ) async => Left(ServerFailure('Not available on web'));
  @override
  Future<List<Challenge>> getChallengesByArchetype(
    String archetypeId,
  ) async => [];
  @override
  Future<Challenge?> getWeeklySpotlight({String? archetypeId}) async => null;
  @override
  Future<List<Map<String, dynamic>>> getLeaderboard(
    String challengeId, {
    int limit = 3,
  }) async => [];
  @override
  Future<Challenge?> getChallengeById(String id) async => null;
  @override
  Future<void> seedChallengesIfEmpty() async {}
}

// ---------------------------------------------------------------------------
// DriftLeaderboardRepository (matches LeaderboardRepository interface exactly)
// ---------------------------------------------------------------------------
class DriftLeaderboardRepository implements LeaderboardRepository {
  DriftLeaderboardRepository(AppDatabase db, EnhancedSyncEngine syncEngine);

  @override
  Stream<List<LeaderboardEntry>> watchClubLeaderboard([String? clubId]) =>
      const Stream.empty();
  @override
  Stream<List<LeaderboardEntry>> watchChallengeLeaderboard([
    String? challengeId,
  ]) => const Stream.empty();
  @override
  Future<Either<Failure, Unit>> updateUserScore(
    String userId, {
    required int xp,
    required int level,
    required UserArchetype archetype,
    String? userName,
    String? clubId,
    String? challengeId,
    bool isIncrement = false,
  }) async => Left(ServerFailure('Not available on web'));
}

// ---------------------------------------------------------------------------
// DriftUserStatsRepository (used by FirestoreUserStatsRepository and providers)
// ---------------------------------------------------------------------------
class DriftUserStatsRepository {
  DriftUserStatsRepository(AppDatabase db, EnhancedSyncEngine syncEngine);

  Future<UserProfile?> getUserStats(String uid) async => null;
  Stream<UserProfile?> watchUserStats(String uid) => const Stream.empty();
  Future<void> saveUserStats(UserProfile profile) async {}
  Future<void> updateWorldHealth(String uid, int score) async {}
  Future<void> syncUserIdentity(UserProfile profile) async {}
  Future<Map<String, dynamic>?> getRecap(
    String userId,
    String recapId,
  ) async => null;
  Future<Map<String, dynamic>?> getLatestRecap(String userId) async => null;
  Future<List<Map<String, dynamic>>> getRecaps(
    String userId, {
    int limit = 20,
  }) async => [];
  Future<List<Map<String, dynamic>>> getWeeklyActivity(
    String uid,
    DateTime start,
    DateTime end,
  ) async => [];
  Future<void> saveRecap(String userId, Map<String, dynamic> data) async {}
}

// ---------------------------------------------------------------------------
// DriftUserProfileRepository (matches UserProfileRepository interface exactly)
// ---------------------------------------------------------------------------
class DriftUserProfileRepository implements UserProfileRepository {
  DriftUserProfileRepository(DriftUserStatsRepository userStatsRepo);

  @override
  Future<Either<String, Unit>> createProfile(UserProfile profile) async =>
      Left('Not available on web');
  @override
  Future<Either<String, Unit>> updateProfile(UserProfile profile) async =>
      Left('Not available on web');
  @override
  Future<Either<String, UserProfile>> getProfile(String uid) async =>
      Left('Not available on web');
  @override
  Stream<UserProfile?> watchProfile(String uid) => const Stream.empty();
}
