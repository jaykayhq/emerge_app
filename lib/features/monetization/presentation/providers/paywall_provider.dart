import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'paywall_provider.g.dart';

class PaywallState extends Equatable {
  final bool isLoading;
  final Offerings? offerings;
  final String? error;
  final bool isSuccess;

  const PaywallState({
    this.isLoading = false,
    this.offerings,
    this.error,
    this.isSuccess = false,
  });

  PaywallState copyWith({
    bool? isLoading,
    Offerings? Function()? offerings,
    String? Function()? error,
    bool? isSuccess,
  }) {
    return PaywallState(
      isLoading: isLoading ?? this.isLoading,
      offerings: offerings != null ? offerings() : this.offerings,
      error: error != null ? error() : this.error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [isLoading, offerings, error, isSuccess];
}

@riverpod
class PaywallController extends _$PaywallController {
  @override
  PaywallState build() {
    return const PaywallState(isLoading: true);
  }

  Future<void> fetchOfferings() async {
    final repository = ref.read(monetizationRepositoryProvider);

    try {
      final result = await repository.getOfferings();
      result.fold(
        (error) => state = state.copyWith(isLoading: false, error: () => error),
        (offerings) => state = state.copyWith(
          isLoading: false,
          offerings: () => offerings,
          error: () => null,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: () => 'Failed to load premium packages.',
      );
    }
  }

  Future<void> purchasePackage(Package package) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final repository = ref.read(monetizationRepositoryProvider);
      final result = await repository.purchasePremium();

      result.fold(
        (error) => state = state.copyWith(isLoading: false, error: () => error),
        (isPremium) =>
            state = state.copyWith(isLoading: false, isSuccess: isPremium),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: () => 'Purchase failed or was cancelled.',
      );
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final repository = ref.read(monetizationRepositoryProvider);
      final result = await repository.restorePurchases();

      result.fold(
        (error) => state = state.copyWith(isLoading: false, error: () => error),
        (isPremium) =>
            state = state.copyWith(isLoading: false, isSuccess: isPremium),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: () => 'Failed to restore purchases.',
      );
    }
  }
}
