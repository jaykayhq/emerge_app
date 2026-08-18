import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/core/services/remote_config_service.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/habits/domain/services/free_tier_habit_gate.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter/material.dart';

class BlueprintDetailController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is idle
  }

  Future<void> adoptBlueprint(Blueprint blueprint, {TimeOfDay? reminderTime}) async {
    state = const AsyncLoading();

    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final isPremium = ref.read(isPremiumProvider).value ?? false;
      if (blueprint.isPremium && !isPremium) {
        throw Exception('Premium required');
      }

      // Check for duplicate adoption
      final existingHabits = ref.read(habitsProvider).value ?? [];
      final blueprintTitles = blueprint.habits.map((h) => h.title).toSet();
      if (existingHabits.any((h) => blueprintTitles.contains(h.title))) {
        throw Exception('Already adopted');
      }

      // Free-tier cap: adopting a blueprint creates several habits at once
      // (previously bypassed the 5-habit limit entirely). Same gate as
      // createHabit — active count + blueprint habits must fit the limit
      // unless premium.
      final activeHabitCount = existingHabits.where((h) => !h.isArchived).length;
      final freeHabitLimit = ref.read(remoteConfigServiceProvider).freeHabitLimit;
      final fitsFreeTier = FreeTierHabitGate.canAddHabits(
        activeHabitCount: activeHabitCount,
        habitsToAdd: blueprint.habits.length,
        freeLimit: freeHabitLimit,
        isPremium: isPremium,
      );
      if (!fitsFreeTier) {
        throw SubscriptionLimitReachedException(
          'You have reached the limit of $freeHabitLimit active habits on the '
          'free tier. Upgrade to Premium for unlimited habits!',
        );
      }

      final repository = ref.read(habitRepositoryProvider);
      final reminderTimeStr = reminderTime != null
          ? '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}'
          : null;
      final result = await repository.createHabitsFromBlueprint(
        userId: user.id,
        blueprint: blueprint,
        reminderTime: reminderTimeStr,
      );

      await result.fold(
        (failure) async {
          throw Exception(failure.message);
        },
        (_) async {},
      );

      // Adoption succeeded — flip to success BEFORE the side-effecting
      // counter write so a Firestore hiccup there can't strand the UI on
      // AsyncLoading with habits already created.
      state = const AsyncData(null);

      try {
        await ref.read(blueprintRepositoryProvider).incrementAdoptionCount(blueprint.id);
        // The single-doc provider may be cached with the stale pre-increment
        // count; force a re-fetch so deep-linked detail screens show the
        // fresh number.
        ref.invalidate(blueprintByIdProvider(blueprint.id));
      } catch (e) {
        debugPrint(
          'Blueprint adoption counter increment failed (best-effort) for '
          '${blueprint.id}: $e',
        );
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final blueprintDetailControllerProvider =
    AsyncNotifierProvider<BlueprintDetailController, void>(
        () => BlueprintDetailController());
