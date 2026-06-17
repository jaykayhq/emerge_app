import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
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
        (_) async {
          await ref.read(blueprintRepositoryProvider).incrementAdoptionCount(blueprint.id);
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
