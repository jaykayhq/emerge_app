import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/monetization/presentation/providers/paywall_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/monetization/domain/repositories/monetization_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:fpdart/fpdart.dart';

// ignore_for_file: unused_element

class MockMonetizationRepository implements MonetizationRepository {
  bool _premium = false;
  final Offerings? _offerings;
  final String? _error;

  MockMonetizationRepository({
    bool premium = false,
    Offerings? offerings,
    String? error,
  }) : _premium = premium,
       _offerings = offerings,
       _error = error;

  @override
  Stream<bool> get premiumStatusStream => Stream.value(_premium);

  @override
  Future<void> initialize({String? uid}) async {
    // No-op in mock
  }

  @override
  Future<void> identify(String uid) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<Either<String, Offerings>> getOfferings() async {
    if (_error != null) return Left(_error);
    if (_offerings != null) return Right(_offerings);
    return const Left('No offerings');
  }

  @override
  Future<Either<String, bool>> get isPremium async => Right(_premium);

  @override
  Future<Either<String, bool>> purchasePremium() async {
    _premium = true;
    return const Right(true);
  }

  @override
  Future<Either<String, bool>> restorePurchases() async {
    _premium = true;
    return const Right(true);
  }

  @override
  Future<String?> get premiumPriceString async => '\$9.99';

  @override
  Future<Either<String, bool>> purchaseConsumable(String productId) async {
    return const Right(true);
  }

  @override
  Future<Either<String, Map<String, String>>> getConsumablePrices(
    List<String> productIds,
  ) async {
    return Right(<String, String>{});
  }
}

void main() {
  group('PaywallController', () {
    test('initial state has isLoading = true', () {
      final container = ProviderContainer(
        overrides: [
          monetizationRepositoryProvider.overrideWithValue(
            MockMonetizationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final state = container.read(paywallControllerProvider);
      expect(state.isLoading, true);
      expect(state.offerings, isNull);
      expect(state.error, isNull);
      expect(state.isSuccess, false);
    });

    test('fetchOfferings sets loading false on success', () async {
      final container = ProviderContainer(
        overrides: [
          monetizationRepositoryProvider.overrideWithValue(
            MockMonetizationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(paywallControllerProvider.notifier).fetchOfferings();

      final state = container.read(paywallControllerProvider);
      expect(state.isLoading, false);
    });
  });

  group('PaywallState', () {
    test('copyWith creates new state with updated values', () {
      const state = PaywallState(isLoading: true);
      final updated = state.copyWith(isLoading: false, isSuccess: true);
      expect(updated.isLoading, false);
      expect(updated.isSuccess, true);
      expect(updated.offerings, isNull);
      expect(updated.error, isNull);
    });

    test('props includes all fields', () {
      const state = PaywallState(isLoading: true, isSuccess: false);
      expect(state.props, [true, null, null, false]);
    });

    test('equality works correctly', () {
      const state1 = PaywallState(isLoading: true);
      const state2 = PaywallState(isLoading: true);
      const state3 = PaywallState(isLoading: false);
      expect(state1, state2);
      expect(state1, isNot(state3));
    });
  });

  group('MonetizationRepository', () {
    test('mock repo starts non-premium', () {
      final repo = MockMonetizationRepository();
      expect(repo.premiumPriceString, completion('\$9.99'));
    });

    test('mock repo purchase sets premium', () async {
      final repo = MockMonetizationRepository();
      final result = await repo.purchasePremium();
      expect(result.isRight(), true);
      result.fold((_) => fail('should be right'), (v) => expect(v, true));
    });

    test('mock repo restore returns premium', () async {
      final repo = MockMonetizationRepository();
      final result = await repo.restorePurchases();
      expect(result.isRight(), true);
    });
  });
}
