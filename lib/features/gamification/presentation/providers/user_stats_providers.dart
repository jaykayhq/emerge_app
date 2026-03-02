import 'dart:async';

import 'package:emerge_app/core/services/event_bus.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/domain/services/gamification_service.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
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
  final controller = UserStatsController(
    repository: repository,
    userId: userId,
  );
  ref.onDispose(controller.dispose);
  return controller;
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
    AppLogger.d(
      'Habit completed: ${event.habitId}, waiting for server update...',
    );

    // Log success for debugging
    AppLogger.i(
      'Habit completed event received: ${event.habitId} for user: ${event.userId}',
    );
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

      AppLogger.d('World state updated successfully');
    } catch (e) {
      AppLogger.e('Error updating world state', e);
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

      AppLogger.d('Building unlocked: $buildingId');
    } catch (e) {
      AppLogger.e('Error unlocking building', e);
      rethrow;
    }
  }

  /// Start a mission on a world node (marks it as in-progress)
  Future<void> startMission(String nodeId) async {
    if (userId.isEmpty) return;

    try {
      final currentProfile = await repository.getUserStats(userId);
      final currentWorldState = currentProfile.worldState;

      // Prevent duplicate starts
      if (currentWorldState.activeNodes.contains(nodeId) ||
          currentWorldState.claimedNodes.contains(nodeId)) {
        AppLogger.d('Node $nodeId already active or claimed');
        return;
      }

      final newWorldState = currentWorldState.copyWith(
        activeNodes: [...currentWorldState.activeNodes, nodeId],
      );

      final updatedProfile = currentProfile.copyWith(worldState: newWorldState);
      await repository.saveUserStats(updatedProfile);

      AppLogger.d('Mission started: $nodeId');
    } catch (e) {
      AppLogger.e('Error starting mission', e);
      rethrow;
    }
  }

  /// Complete a mission: distribute XP to attributes, recalculate level, move to claimed
  Future<void> completeMission(
    String nodeId,
    Map<String, int> xpBoosts,
    int nodeRequiredLevel,
  ) async {
    if (userId.isEmpty) return;

    try {
      final currentProfile = await repository.getUserStats(userId);
      final currentWorldState = currentProfile.worldState;
      final gamificationService = GamificationService();

      // Prevent duplicate claims
      if (currentWorldState.claimedNodes.contains(nodeId)) {
        AppLogger.d('Node $nodeId already claimed');
        return;
      }

      // 1. Apply XP boosts to each targeted attribute
      var updatedStats = currentProfile.avatarStats;
      for (final entry in xpBoosts.entries) {
        final attribute = HabitAttribute.values.firstWhere(
          (a) => a.name == entry.key,
          orElse: () => HabitAttribute.strength,
        );
        updatedStats = gamificationService.addXp(
          updatedStats,
          entry.value,
          attribute,
        );
      }

      // 2. Update world state: move from active to claimed
      final activeNodes = List<String>.from(currentWorldState.activeNodes)
        ..remove(nodeId);
      final claimedNodes = List<String>.from(currentWorldState.claimedNodes)
        ..add(nodeId);

      // 3. Update highest completed node level for node-gated progression
      final newHighest =
          nodeRequiredLevel > currentWorldState.highestCompletedNodeLevel
          ? nodeRequiredLevel
          : currentWorldState.highestCompletedNodeLevel;

      final newWorldState = currentWorldState.copyWith(
        activeNodes: activeNodes,
        claimedNodes: claimedNodes,
        highestCompletedNodeLevel: newHighest,
      );

      // 4. Cap level by node gate: min(xpLevel, highestCompletedNodeLevel + 1)
      final xpLevel = updatedStats.level;
      final nodeGate = newHighest + 1;
      final effectiveLevel = xpLevel < nodeGate ? xpLevel : nodeGate;
      updatedStats = updatedStats.copyWith(level: effectiveLevel);

      final updatedProfile = currentProfile.copyWith(
        worldState: newWorldState,
        avatarStats: updatedStats,
      );
      await repository.saveUserStats(updatedProfile);

      AppLogger.d(
        'Mission completed: $nodeId — XP distributed, level: $effectiveLevel',
      );
    } catch (e) {
      AppLogger.e('Error completing mission', e);
      rethrow;
    }
  }

  /// Mark the user as having Emerged — unlocks level 6+ progression
  Future<void> emerge() async {
    if (userId.isEmpty) return;

    try {
      final currentProfile = await repository.getUserStats(userId);
      if (currentProfile.hasEmerged) return; // Already emerged

      final updatedProfile = currentProfile.copyWith(hasEmerged: true);
      await repository.saveUserStats(updatedProfile);

      AppLogger.d('User has Emerged! Level gate removed.');
    } catch (e) {
      AppLogger.e('Error during emerge', e);
      rethrow;
    }
  }
}
