import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/data/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/challenge_catalog.dart';
import 'package:emerge_app/features/social/domain/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  final socialService = SocialActivityService(firestore: firestore);
  return FirestoreChallengeRepository(firestore, socialService);
});

final featuredChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final repository = ref.read(challengeRepositoryProvider);
  return repository.getChallenges(featuredOnly: true);
});

final allChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final repository = ref.read(challengeRepositoryProvider);
  return repository.getChallenges(featuredOnly: false);
});

final userChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final repository = ref.read(challengeRepositoryProvider);
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  return repository.getUserChallenges(user.id);
});

/// Challenges filtered by the current user's archetype
final archetypeChallengesProvider = FutureProvider<List<Challenge>>((
  ref,
) async {
  final repository = ref.read(challengeRepositoryProvider);
  final profile = ref.watch(userStatsStreamProvider).value;
  if (profile == null) return [];
  return repository.getChallengesByArchetype(profile.archetype.name);
});

/// Weekly spotlight challenge for the user's archetype
final weeklySpotlightProvider = FutureProvider<Challenge?>((ref) async {
  final repository = ref.read(challengeRepositoryProvider);
  final profile = ref.watch(userStatsStreamProvider).value;
  if (profile == null) return null;
  return repository.getWeeklySpotlight(archetypeId: profile.archetype.name);
});

/// Daily quest for the user's archetype
final dailyQuestProvider = FutureProvider<Challenge?>((ref) async {
  final profile = ref.watch(userStatsStreamProvider).value;
  if (profile == null) return null;
  return ChallengeCatalog.getDailyQuest(profile.archetype.name);
});

/// Leaderboard for a specific challenge
final challengeLeaderboardProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      challengeId,
    ) async {
      final repository = ref.read(challengeRepositoryProvider);
      return repository.getLeaderboard(challengeId);
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
