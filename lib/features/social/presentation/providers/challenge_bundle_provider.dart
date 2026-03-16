import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/challenge_bundle.dart';
import 'package:emerge_app/features/social/domain/models/challenge_catalog.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'challenge_bundle_provider.g.dart';

/// Consolidated challenge data provider
/// Fetches all challenge data in a single batch to prevent multiple rebuild waves
@riverpod
class ChallengeBundle extends _$ChallengeBundle {
  @override
  Future<ChallengeBundleData> build() async {
    final repository = ref.read(challengeRepositoryProvider);
    final user = ref.watch(authStateChangesProvider).value;
    final profile = ref.watch(userStatsStreamProvider).value;

    // Return empty bundle if user or profile not ready
    if (user == null || profile == null) {
      return ChallengeBundleData.empty();
    }

    // Single batch fetch - all data in one async operation
    // This prevents the cascade of rebuilds from multiple independent providers
    final results = await Future.wait<dynamic>([
      // Weekly spotlight for user's archetype
      repository.getWeeklySpotlight(archetypeId: profile.archetype.name),
      // Daily quest from local catalog (instant, no network)
      Future.value(ChallengeCatalog.getDailyQuest(profile.archetype.name)),
      // User's active/completed challenges
      repository.getUserChallenges(user.id),
      // Archetype-specific challenges
      repository.getChallengesByArchetype(profile.archetype.name),
    ]);

    return ChallengeBundleData(
      weeklySpotlight: results[0] as Challenge?,
      dailyQuest: results[1] as Challenge?,
      userChallenges: results[2] as List<Challenge>,
      archetypeChallenges: results[3] as List<Challenge>,
    );
  }
}

/// Selector helper for weekly spotlight
@riverpod
Challenge? weeklySpotlightFromBundle(Ref ref) {
  final bundle = ref.watch(challengeBundleProvider).value;
  return bundle?.weeklySpotlight;
}

/// Selector helper for daily quest
@riverpod
Challenge? dailyQuestFromBundle(Ref ref) {
  final bundle = ref.watch(challengeBundleProvider).value;
  return bundle?.dailyQuest;
}

/// Selector helper for user challenges
@riverpod
List<Challenge> userChallengesFromBundle(Ref ref) {
  final bundle = ref.watch(challengeBundleProvider).value;
  return bundle?.userChallenges ?? [];
}

/// Selector helper for archetype challenges
@riverpod
List<Challenge> archetypeChallengesFromBundle(Ref ref) {
  final bundle = ref.watch(challengeBundleProvider).value;
  return bundle?.archetypeChallenges ?? [];
}
