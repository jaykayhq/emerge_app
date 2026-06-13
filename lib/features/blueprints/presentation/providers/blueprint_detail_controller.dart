import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
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

      final repository = ref.read(habitRepositoryProvider);
      final result = await repository.createHabitsFromBlueprint(
        userId: user.id,
        blueprint: blueprint,
        reminderTime: reminderTime,
      );

      result.fold(
        (failure) {
          throw Exception(failure.message);
        },
        (_) {
          state = const AsyncData(null);
        },
      );
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final blueprintDetailControllerProvider =
    AsyncNotifierProvider<BlueprintDetailController, void>(
        () => BlueprintDetailController());
