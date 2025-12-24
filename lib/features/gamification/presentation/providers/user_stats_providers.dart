import 'dart:async';

import 'package:emerge_app/core/services/event_bus.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/domain/services/gamification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gamificationServiceProvider = Provider((ref) => GamificationService());

final userStatsStreamProvider = StreamProvider<UserProfile>((ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value(const UserProfile(uid: ''));

  final repository = ref.watch(userStatsRepositoryProvider);
  return repository.watchUserStats(user.id);
});

final userStatsControllerProvider = Provider((ref) {
  final repository = ref.watch(userStatsRepositoryProvider);
  final userAsync = ref.watch(authStateChangesProvider);
  final userId = userAsync.value?.id ?? '';
  return UserStatsController(repository: repository, userId: userId);
});

class UserStatsController {
  final UserStatsRepository repository;
  final String userId;
  StreamSubscription? _subscription;

  UserStatsController({required this.repository, required this.userId}) {
    _init();
  }

  void _init() {
    _subscription = EventBus().on<HabitCompleted>().listen((event) async {
      await _handleHabitCompletion(event);
    });
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<void> _handleHabitCompletion(HabitCompleted event) async {
    // Logic moved to Backend (Cloud Functions).
    // FirestoreHabitRepository now logs the activity, which triggers the Function.
    // The Client just listens to the UserProfile stream for updates.

    // We can use this hook for local UI feedback (confetti, toast, etc.)
    // but NO data mutation.
    debugPrint(
      'Habit completed: ${event.habitId}, waiting for server update...',
    );

    // Log success for debugging
    AppLogger.i('Habit completed event received: ${event.habitId} for user: ${event.userId}');
  }

  /// Update the world state (for building placements, etc.)
  Future<void> updateWorldState(UserWorldState newWorldState) async {
    if (userId.isEmpty) return;

    try {
      // Get current profile
      final currentProfile = await repository.getUserStats(userId);

      // Update with new world state
      final updatedProfile = currentProfile.copyWith(worldState: newWorldState);

      // Save to Firestore
      await repository.saveUserStats(updatedProfile);

      debugPrint('World state updated successfully');
    } catch (e) {
      debugPrint('Error updating world state: $e');
      rethrow;
    }
  }

  /// Unlock a building in the world
  Future<void> unlockBuilding(String buildingId) async {
    if (userId.isEmpty) return;

    try {
      final currentProfile = await repository.getUserStats(userId);
      final gamificationService = GamificationService();

      final newWorldState = gamificationService.unlockBuilding(
        currentProfile.worldState,
        buildingId,
      );

      final updatedProfile = currentProfile.copyWith(worldState: newWorldState);
      await repository.saveUserStats(updatedProfile);

      debugPrint('Building unlocked: $buildingId');
    } catch (e) {
      debugPrint('Error unlocking building: $e');
      rethrow;
    }
  }
}
