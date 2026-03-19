import 'package:flutter/foundation.dart' show kIsWeb;
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
    _fetchOfferings();
    return const PaywallState(isLoading: true);
  }

  Future<void> _fetchOfferings() async {
    if (kIsWeb) {
      state = state.copyWith(
        isLoading: false,
        error: 'Premium subscriptions are currently available only on mobile.',
      );
      return;
    }

    try {
      final offerings = await Purchases.getOfferings();
      state = state.copyWith(
        isLoading: false,
        offerings: offerings,
        error: null,
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
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      final isPremium =
          purchaseResult.customerInfo.entitlements.all['premium']?.isActive ??
          false;
      state = state.copyWith(isLoading: false, isSuccess: isPremium);
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
      final customerInfo = await Purchases.restorePurchases();
      final isPremium =
          customerInfo.entitlements.all['premium']?.isActive ?? false;
      state = state.copyWith(isLoading: false, isSuccess: isPremium);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to restore purchases.',
      );
    }
  }
}
