import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'paywall_provider.freezed.dart';
part 'paywall_provider.g.dart';

@freezed
abstract class PaywallState with _$PaywallState {
  const factory PaywallState({
    @Default(false) bool isLoading,
    Offerings? offerings,
    String? error,
    @Default(false) bool isSuccess,
  }) = _PaywallState;
}

@riverpod
class PaywallController extends _$PaywallController {
  @override
  PaywallState build() {
    // Initialize state synchronously
    // Don't call async methods in build to avoid initialization issues
    return const PaywallState(isLoading: true);
  }

  Future<void> fetchOfferings() async {
    final repository = ref.read(monetizationRepositoryProvider);

    try {
      final result = await repository.getOfferings();
      result.fold(
        (error) => state = state.copyWith(isLoading: false, error: error),
        (offerings) => state = state.copyWith(
          isLoading: false,
          offerings: offerings,
          error: null,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load premium packages.',
      );
    }
  }

  Future<void> purchasePackage(Package package) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(monetizationRepositoryProvider);
      final result = await repository.purchasePremium();
      
      result.fold(
        (error) => state = state.copyWith(isLoading: false, error: error),
        (isPremium) => state = state.copyWith(isLoading: false, isSuccess: isPremium),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Purchase failed or was cancelled.',
      );
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(monetizationRepositoryProvider);
      final result = await repository.restorePurchases();
      
      result.fold(
        (error) => state = state.copyWith(isLoading: false, error: error),
        (isPremium) => state = state.copyWith(isLoading: false, isSuccess: isPremium),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to restore purchases.',
      );
    }
  }
}
