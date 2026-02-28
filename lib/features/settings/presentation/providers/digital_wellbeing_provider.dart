import 'package:emerge_app/features/settings/data/services/digital_wellbeing_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WellbeingState {
  final bool isGoogleFitConnected;
  final bool isScreenTimeConnected;

  const WellbeingState({
    required this.isGoogleFitConnected,
    required this.isScreenTimeConnected,
  });

  WellbeingState copyWith({
    bool? isGoogleFitConnected,
    bool? isScreenTimeConnected,
  }) {
    return WellbeingState(
      isGoogleFitConnected: isGoogleFitConnected ?? this.isGoogleFitConnected,
      isScreenTimeConnected:
          isScreenTimeConnected ?? this.isScreenTimeConnected,
    );
  }
}

class DigitalWellbeingNotifier extends AsyncNotifier<WellbeingState> {
  @override
  Future<WellbeingState> build() async {
    final service = ref.watch(digitalWellbeingServiceProvider);
    return WellbeingState(
      isGoogleFitConnected: await service.isGoogleFitConnected(),
      isScreenTimeConnected: await service.isScreenTimeConnected(),
    );
  }

  Future<void> toggleGoogleFit(bool connect) async {
    final previousState = state.value;
    state = const AsyncLoading();
    try {
      await ref.read(digitalWellbeingServiceProvider).toggleGoogleFit(connect);
      state = AsyncData(previousState!.copyWith(isGoogleFitConnected: connect));
    } catch (e, stack) {
      state = AsyncError(e, stack);
      // Revert on error
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      rethrow;
    }
  }

  Future<void> toggleScreenTime(bool connect) async {
    final previousState = state.value;
    state = const AsyncLoading();
    try {
      await ref.read(digitalWellbeingServiceProvider).toggleScreenTime(connect);
      state = AsyncData(
        previousState!.copyWith(isScreenTimeConnected: connect),
      );
    } catch (e, stack) {
      state = AsyncError(e, stack);
      // Revert on error
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      rethrow;
    }
  }
}

final digitalWellbeingProvider =
    AsyncNotifierProvider<DigitalWellbeingNotifier, WellbeingState>(
      DigitalWellbeingNotifier.new,
    );
