import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/monetization/data/repositories/paystack_payment_repository.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'paywall_provider.g.dart';

/// Web plan amounts in NGN (matching the old static Payment Page prices).
const webPlans = <String, double>{'monthly': 2500.0, 'yearly': 15000.0};

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
  /// Test seam: injected redirect. Production (web) sets window.location.
  void Function(String url)? redirectTo;

  /// Whether the web (Paystack Payment Page) checkout path applies.
  /// `kIsWeb` is a compile-time constant (always false under `flutter
  /// test`), so tests subclass [PaywallController] and force this true to
  /// exercise the web path.
  bool get isWeb => kIsWeb;

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
      final result = await repository.purchasePremium(package);

      result.fold(
        (error) => state = state.copyWith(isLoading: false, error: () => error),
        (isPremium) {
          state = state.copyWith(isLoading: false, isSuccess: isPremium);
          if (isPremium) ref.invalidate(isPremiumProvider);
        },
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
        (isPremium) {
          state = state.copyWith(isLoading: false, isSuccess: isPremium);
          if (isPremium) ref.invalidate(isPremiumProvider);
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: () => 'Failed to restore purchases.',
      );
    }
  }

  /// Web-only: initializes a Paystack transaction and redirects the browser
  /// to the Payment Page. The webhook flips isPremium on charge.success.
  Future<void> startWebCheckout({required String planKey}) async {
    if (!isWeb) return;
    final amount = webPlans[planKey];
    if (amount == null) {
      state = state.copyWith(isLoading: false, error: () => 'Unknown plan.');
      return;
    }
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final authUser = ref.read(authStateChangesProvider).value;
      if (authUser == null || authUser.email.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: () => 'Please sign in before upgrading.',
        );
        return;
      }
      final repository = ref.read(paystackPaymentRepositoryProvider);
      // `Uri.base.origin` throws for non-http(s) bases (e.g. `file://` in the
      // test VM). On web the app is always served over http(s), so the origin
      // is real there; the empty fallback only affects non-web execution,
      // where the checkout path is exercised with a dummy callback URL.
      final uri = Uri.base;
      final origin = (uri.scheme == 'http' || uri.scheme == 'https')
          ? uri.origin
          : '';
      final authorizationUrl = await repository.initializeTransaction(
        amount: amount,
        email: authUser.email,
        identityType: planKey,
        callbackUrl: '$origin/order-confirmed',
      );
      state = state.copyWith(isLoading: false, error: () => null);
      redirectTo?.call(authorizationUrl);
    } catch (e) {
      AppLogger.w('Paystack web checkout failed', error: e);
      state = state.copyWith(
        isLoading: false,
        error: () => 'Checkout failed. Please try again.',
      );
    }
  }
}
