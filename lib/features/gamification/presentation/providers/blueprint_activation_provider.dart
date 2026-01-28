import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/blueprints_repository.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/domain/models/blueprint.dart';
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'blueprint_activation_provider.g.dart';

/// State for blueprint activation flow
class BlueprintActivationState extends Equatable {
  /// Currently selected blueprint for preview
  final Blueprint? selectedBlueprint;

  /// Whether activation is in progress
  final bool isActivating;

  /// List of recently activated blueprint IDs
  final Set<String> activatedBlueprintIds;

  /// Error message if activation failed
  final String? error;

  /// Success message after activation
  final String? successMessage;

  const BlueprintActivationState({
    this.selectedBlueprint,
    this.isActivating = false,
    this.activatedBlueprintIds = const {},
    this.error,
    this.successMessage,
  });

  /// Check if a blueprint has been activated
  bool isActivated(String blueprintId) =>
      activatedBlueprintIds.contains(blueprintId);

  BlueprintActivationState copyWith({
    Blueprint? selectedBlueprint,
    bool? isActivating,
    Set<String>? activatedBlueprintIds,
    String? error,
    String? successMessage,
  }) {
    return BlueprintActivationState(
      selectedBlueprint: selectedBlueprint ?? this.selectedBlueprint,
      isActivating: isActivating ?? this.isActivating,
      activatedBlueprintIds:
          activatedBlueprintIds ?? this.activatedBlueprintIds,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
    selectedBlueprint,
    isActivating,
    activatedBlueprintIds,
    error,
    successMessage,
  ];
}

/// Blueprint Activation Notifier
/// Handles the flow of selecting and activating blueprints
/// which creates habits and syncs to dashboard
@Riverpod(keepAlive: true)
class BlueprintActivationNotifier extends _$BlueprintActivationNotifier {
  @override
  BlueprintActivationState build() {
    return const BlueprintActivationState();
  }

  /// Select a blueprint for preview
  void selectBlueprint(Blueprint blueprint) {
    state = state.copyWith(
      selectedBlueprint: blueprint,
      error: null,
      successMessage: null,
    );
  }

  /// Clear the selected blueprint
  void clearSelection() {
    state = const BlueprintActivationState(
      activatedBlueprintIds: {},
    ).copyWith(activatedBlueprintIds: state.activatedBlueprintIds);
  }

  /// Activate the selected blueprint
  /// Creates all habits from the blueprint and syncs to dashboard
  Future<bool> activateSelectedBlueprint() async {
    final blueprint = state.selectedBlueprint;
    if (blueprint == null) {
      state = state.copyWith(error: 'No blueprint selected');
      return false;
    }

    return activateBlueprint(blueprint);
  }

  /// Activate a specific blueprint
  Future<bool> activateBlueprint(Blueprint blueprint) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) {
      state = state.copyWith(error: 'User not logged in');
      return false;
    }

    // Check if already activated
    if (state.activatedBlueprintIds.contains(blueprint.id)) {
      state = state.copyWith(
        error: 'This blueprint has already been activated',
      );
      return false;
    }

    state = state.copyWith(
      isActivating: true,
      error: null,
      successMessage: null,
    );

    try {
      // Use dashboard notifier to create habits with optimistic updates
      final dashboardNotifier = ref.read(
        dashboardStateNotifierProvider.notifier,
      );
      await dashboardNotifier.activateBlueprint(blueprint, user.id);

      // Log activity for gamification
      await _logBlueprintActivation(blueprint, user.id);

      // Mark as activated
      state = state.copyWith(
        isActivating: false,
        activatedBlueprintIds: {...state.activatedBlueprintIds, blueprint.id},
        successMessage:
            'Blueprint "${blueprint.title}" activated! ${blueprint.habits.length} habits created.',
        selectedBlueprint: null,
      );

      AppLogger.i('Blueprint activated: ${blueprint.id} - ${blueprint.title}');
      return true;
    } catch (e, s) {
      AppLogger.e('Failed to activate blueprint', e, s);
      state = state.copyWith(
        isActivating: false,
        error: 'Failed to activate blueprint: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> _logBlueprintActivation(
    Blueprint blueprint,
    String userId,
  ) async {
    try {
      final userStatsRepo = ref.read(userStatsRepositoryProvider);
      await userStatsRepo.logActivity(
        userId: userId,
        type: 'blueprint_activated',
        sourceId: blueprint.id,
        date: DateTime.now(),
      );
    } catch (e, s) {
      AppLogger.e('Failed to log blueprint activation', e, s);
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }
}

/// Provider for blueprint categories
@riverpod
Future<List<String>> blueprintCategories(Ref ref) async {
  final repo = ref.watch(blueprintsRepositoryProvider);
  return repo.getCategories();
}

/// Provider for blueprints by category with caching
@riverpod
Future<List<Blueprint>> blueprintsByCategory(Ref ref, String? category) async {
  final repo = ref.watch(blueprintsRepositoryProvider);
  return repo.getBlueprints(category: category);
}

/// Provider for featured blueprints (first 3 from each category)
@riverpod
Future<List<Blueprint>> featuredBlueprints(Ref ref) async {
  final repo = ref.watch(blueprintsRepositoryProvider);
  final allBlueprints = await repo.getBlueprints();

  // Group by category and take first from each
  final Map<String, Blueprint> featured = {};
  for (final blueprint in allBlueprints) {
    if (!featured.containsKey(blueprint.category)) {
      featured[blueprint.category] = blueprint;
    }
    if (featured.length >= 5) break;
  }

  return featured.values.toList();
}

/// Provider to check if a blueprint is already activated
@riverpod
bool isBlueprintActivated(Ref ref, String blueprintId) {
  final state = ref.watch(blueprintActivationNotifierProvider);
  return state.isActivated(blueprintId);
}

/// Provider for activation loading state
@riverpod
bool isBlueprintActivating(Ref ref) {
  final state = ref.watch(blueprintActivationNotifierProvider);
  return state.isActivating;
}
