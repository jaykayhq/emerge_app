import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/repositories_barrel.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/challenge_catalog.dart';
import 'package:emerge_app/features/social/domain/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'challenge_provider.g.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final engine = LocalGameLoopEngine();
  final syncEngine = ref.watch(enhancedSyncEngineProvider);
  return DriftChallengeRepository(db, engine, syncEngine);
});

@Riverpod(keepAlive: true)
Future<List<Challenge>> featuredChallenges(Ref ref) async {
  final repository = ref.read(challengeRepositoryProvider);
  return repository.getChallenges(featuredOnly: true);
}

@Riverpod(keepAlive: true)
Future<List<Challenge>> allChallenges(Ref ref) async {
  final repository = ref.read(challengeRepositoryProvider);
  return repository.getChallenges(featuredOnly: false);
}

@Riverpod(keepAlive: true)
Future<List<Challenge>> userChallenges(Ref ref) async {
  final repository = ref.read(challengeRepositoryProvider);
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  return repository.getUserChallenges(user.id);
}

@Riverpod(keepAlive: true)
Future<List<Challenge>> archetypeChallenges(Ref ref) async {
  final repository = ref.read(challengeRepositoryProvider);
  final profile = ref.watch(userStatsStreamProvider).value;
  if (profile == null) return [];
  return repository.getChallengesByArchetype(profile.archetype.name);
}

@Riverpod(keepAlive: true)
Future<Challenge?> weeklySpotlight(Ref ref) async {
  final repository = ref.read(challengeRepositoryProvider);
  final profile = ref.watch(userStatsStreamProvider).value;
  if (profile == null) return null;
  return repository.getWeeklySpotlight(archetypeId: profile.archetype.name);
}

@Riverpod(keepAlive: true)
Future<Challenge?> dailyQuest(Ref ref) async {
  final profile = ref.watch(userStatsStreamProvider).value;
  if (profile == null) return null;
  return ChallengeCatalog.getDailyQuest(profile.archetype.name);
}

final challengeLeaderboardProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      challengeId,
    ) async {
      final repository = ref.read(challengeRepositoryProvider);
      return repository.getLeaderboard(challengeId);
    });

final challengeByIdProvider = FutureProvider.family<Challenge?, String>((
  ref,
  id,
) async {
  final repository = ref.read(challengeRepositoryProvider);
  return repository.getChallengeById(id);
});

final filteredChallengesProvider =
    FutureProvider.family<List<Challenge>, ChallengeStatus>((
      ref,
      status,
    ) async {
      if (status == ChallengeStatus.featured) {
        return ref.watch(featuredChallengesProvider.future);
      } else {
        final userChallenges = await ref.watch(userChallengesProvider.future);
        return userChallenges.where((c) => c.status == status).toList();
      }
    });

/// Challenges scoped to the user's active tribe by archetype matching.
final tribeChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  final membership = ref.watch(activeMembershipProvider).value;
  if (membership == null) return Stream.value([]);
  final clubs = ref.watch(allArchetypeClubsProvider).value ?? [];
  final tribe = clubs.where((t) => t.id == membership.tribeId).firstOrNull;
  final archetypeId = tribe?.archetypeId;
  final challengesAsync = ref.watch(allChallengesProvider);
  return challengesAsync.when(
    data: (challenges) => Stream.value(
      challenges.where((c) =>
        archetypeId == null ||
        c.archetypeId == null ||
        c.archetypeId == archetypeId,
      ).toList(),
    ),
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});
