import 'dart:async';

import 'package:emerge_app/core/services/event_bus.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/core/drift_repositories/repositories_barrel.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/domain/services/gamification_service.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/services/momentum_service.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_stats_providers.g.dart';

final userStatsStreamProvider = StreamProvider<UserProfile>((ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value(const UserProfile(uid: ''));

  final repository = ref.watch(userStatsRepositoryProvider);
  return repository.watchUserStats(user.id).handleError((error, stackTrace) {
    AppLogger.e('userStatsStreamProvider error', error, stackTrace);
    return const UserProfile(uid: '');
  });
});

/// Provider that only emits when the user's archetype changes.
/// This prevents expensive MaterialApp rebuilds when only XP/stats change.
@riverpod
UserArchetype currentArchetype(Ref ref) {
  final profileAsync = ref.watch(userStatsStreamProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile.archetype,
    orElse: () => UserArchetype.none,
  );
}

/// Selector for onboarding completion status
@riverpod
bool isOnboardingComplete(Ref ref) {
  final profileAsync = ref.watch(userStatsStreamProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile.onboardingCompletedAt != null,
    orElse: () => false,
  );
}

/// Split provider that only watches avatarStats field
/// Prevents full profile rebuilds when only avatar stats change
@riverpod
Stream<UserAvatarStats> userAvatarStats(Ref ref) {
  final profileAsync = ref.watch(userStatsStreamProvider);
  return profileAsync.when(
    data: (profile) => Stream.value(profile.avatarStats),
    loading: () => Stream.value(const UserAvatarStats()),
    error: (error, stackTrace) => Stream.value(const UserAvatarStats()),
  );
}

/// Split provider that only watches level field
/// Useful for UI elements that only need level info
@riverpod
Stream<int> userLevel(Ref ref) {
  final profileAsync = ref.watch(userStatsStreamProvider);
  return profileAsync.when(
    data: (profile) => Stream.value(profile.avatarStats.level),
    loading: () => Stream.value(1),
    error: (error, stackTrace) => Stream.value(1),
  );
}

/// Split provider that only watches streak field
/// Useful for streak-specific UI components
@riverpod
Stream<int> userStreak(Ref ref) {
  final profileAsync = ref.watch(userStatsStreamProvider);
  return profileAsync.when(
    data: (profile) => Stream.value(profile.avatarStats.streak),
    loading: () => Stream.value(0),
    error: (error, stackTrace) => Stream.value(0),
  );
}

final userStatsControllerProvider = Provider((ref) {
  final repository = ref.watch(userStatsRepositoryProvider);
  final socialActivityService = ref.watch(socialActivityServiceProvider);
  final userAsync = ref.watch(authStateChangesProvider);
  final user = userAsync.value;
  final userId = user?.id ?? '';
  final userName = user?.displayName ?? 'Anonymous';

  final controller = UserStatsController(
    repository: repository,
    socialActivityService: socialActivityService,
    userId: userId,
    userName: userName,
  );
  ref.onDispose(controller.dispose);
  return controller;
});

class UserStatsController {
  final DriftUserStatsRepository repository;
  final SocialActivityService socialActivityService;
  final String userId;
  final String userName;
  StreamSubscription? _subscription;
  StreamSubscription? _undoSubscription;

  UserStatsController({
    required this.repository,
    required this.socialActivityService,
    required this.userId,
    required this.userName,
  }) {
    _init();
  }

  void _init() {
    _subscription = EventBus().on<HabitCompleted>().listen((event) async {
      await _handleHabitCompletion(event);
    });
    if (_subscription != null) {
      EventBus().registerSubscription(_subscription!);
    }

    _undoSubscription =
        EventBus().on<HabitCompletionUndone>().listen((event) async {
      await _handleHabitCompletionUndone(event);
    });
    if (_undoSubscription != null) {
      EventBus().registerSubscription(_undoSubscription!);
    }
  }

  void dispose() {
    if (_subscription != null) {
      EventBus().unregisterSubscription(_subscription!);
      _subscription?.cancel();
    }
    if (_undoSubscription != null) {
      EventBus().unregisterSubscription(_undoSubscription!);
      _undoSubscription?.cancel();
    }
  }

  /// Sole authoritative path for world health updates on habit completion.
  /// Uses the GamificationService zone-based model to compute global health.
  Future<void> _handleHabitCompletion(HabitCompleted event) async {
    if (userId.isEmpty || event.userId != userId) return;

    try {
      final profile = await repository.getUserStats(userId);
      final gamificationService = GamificationService();

      // Resolve the HabitAttribute from the game loop result
      final attribute = HabitAttribute.values.firstWhere(
        (a) => a.name == event.gameLoopResult.attribute,
        orElse: () => HabitAttribute.vitality,
      );

      // Compute zone-based world health (single authoritative path)
      final newWorldState = gamificationService.updateWorldFromAttribute(
        currentState: profile.worldState,
        attribute: attribute,
        completed: true,
      );

      // Persist the updated world state (zones + derived global scalar)
      final updatedProfile = profile.copyWith(worldState: newWorldState);
      await repository.saveUserStats(updatedProfile);

      AppLogger.d(
        'World health updated via zone model: '
        'entropy=${newWorldState.entropy.toStringAsFixed(3)}, '
        'health=${newWorldState.worldHealth.toStringAsFixed(3)}',
      );
    } catch (e, stack) {
      AppLogger.e('Error updating world health on completion', e, stack);
    }
  }

  /// Reverses world health when a habit completion is undone.
  Future<void> _handleHabitCompletionUndone(HabitCompletionUndone event) async {
    if (userId.isEmpty || event.userId != userId) return;

    try {
      final profile = await repository.getUserStats(userId);
      final gamificationService = GamificationService();

      final attribute = HabitAttribute.values.firstWhere(
        (a) => a.name == event.attribute,
        orElse: () => HabitAttribute.vitality,
      );

      // Reverse the zone-based world health
      final newWorldState = gamificationService.reverseWorldFromAttribute(
        currentState: profile.worldState,
        attribute: attribute,
      );

      final updatedProfile = profile.copyWith(worldState: newWorldState);
      await repository.saveUserStats(updatedProfile);

      AppLogger.d(
        'World health reversed via zone model: '
        'entropy=${newWorldState.entropy.toStringAsFixed(3)}',
      );
    } catch (e, stack) {
      AppLogger.e('Error reversing world health on undo', e, stack);
    }
  }

  /// Recalculate world health based on momentum
  Future<void> recalculateWorldHealth(List<Habit> habits) async {
    if (userId.isEmpty) return;
    try {
      final score = MomentumService().computeWorldHealth(habits);
      await repository.updateWorldHealth(userId, score);
      AppLogger.d('World health recalculated: $score');
    } catch (e) {
      AppLogger.e('Error recalculating world health', e);
    }
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

      // 1. Apply 100 Base XP evenly across targeted attributes, plus the specific boosts
      var updatedStats = currentProfile.avatarStats;

      final baseAttributeXp =
          100 ~/ (xpBoosts.isNotEmpty ? xpBoosts.length : 1);
      final remainder = 100 % (xpBoosts.isNotEmpty ? xpBoosts.length : 1);

      int i = 0;
      if (xpBoosts.isEmpty) {
        updatedStats = gamificationService.addXp(
          updatedStats,
          100,
          HabitAttribute.strength,
        );
      } else {
        for (final entry in xpBoosts.entries) {
          final attribute = HabitAttribute.values.firstWhere(
            (a) => a.name == entry.key,
            orElse: () => HabitAttribute.strength,
          );

          final baseAddition = baseAttributeXp + (i == 0 ? remainder : 0);
          updatedStats = gamificationService.addXp(
            updatedStats,
            entry.value + baseAddition,
            attribute,
          );
          i++;
        }
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
        entropy: (currentWorldState.entropy - 0.1).clamp(0.0, 1.0),
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

      // 5. Social Activity Logging
      final currentLevel = currentProfile.avatarStats.level;
      if (effectiveLevel > currentLevel) {
        await socialActivityService.logLevelUp(
          userId: userId,
          userName: userName,
          archetype: currentProfile.archetype.name,
          newLevel: effectiveLevel,
          totalXp: updatedStats.totalXp,
        );
      }

      await socialActivityService.logNodeClaim(
        userId: userId,
        userName: userName,
        archetype: currentProfile.archetype.name,
        nodeId: nodeId,
        nodeName: nodeId.split('_').last,
      );

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
