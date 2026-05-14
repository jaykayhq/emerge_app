import 'dart:async';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/domain/repositories/user_profile_repository.dart';
import 'package:emerge_app/features/gamification/domain/services/gamification_service.dart';
import 'package:emerge_app/core/drift_repositories/drift_user_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gamification_providers.g.dart';

@Riverpod(keepAlive: true)
GamificationService gamificationService(Ref ref) {
  return GamificationService();
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final userStatsRepo = ref.watch(userStatsRepositoryProvider);
  return DriftUserProfileRepository(userStatsRepo);
});

@riverpod
Stream<UserProfile?> userProfile(Ref ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final userId = userAsync.value?.id;
  if (userId == null) return Stream.value(null);
  final repository = ref.watch(userProfileRepositoryProvider);
  return repository.watchProfile(userId);
}
