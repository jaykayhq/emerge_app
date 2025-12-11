import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/firestore_gamification_repository.dart';
import 'package:emerge_app/features/gamification/data/repositories/firestore_user_profile_repository.dart';
import 'package:emerge_app/features/gamification/domain/entities/user_stats.dart';
import 'package:emerge_app/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:emerge_app/features/gamification/domain/repositories/user_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gamification_providers.g.dart';

@Riverpod(keepAlive: true)
GamificationRepository gamificationRepository(Ref ref) {
  return FirestoreGamificationRepository(FirebaseFirestore.instance);
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return FirestoreUserProfileRepository(FirebaseFirestore.instance);
});

@riverpod
Stream<UserStats> userStats(Ref ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final userId = userAsync.value?.id;

  if (userId == null) {
    return Stream.value(UserStats.empty);
  }

  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.watchUserStats(userId);
}

@riverpod
Stream<UserProfile?> userProfile(Ref ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final userId = userAsync.value?.id;

  if (userId == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(userProfileRepositoryProvider);
  return repository.watchProfile(userId);
}
