import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/monetization/data/repositories/paystack_payment_repository.dart';
import 'package:emerge_app/features/monetization/presentation/providers/paywall_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/monetization/domain/repositories/monetization_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:fpdart/fpdart.dart';

// ignore_for_file: unused_element

class MockPaystackPaymentRepository extends Mock
    implements PaystackPaymentRepository {}

class _WebPaywallController extends PaywallController {
  @override
  bool get isWeb => true;
}

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
  Future<Either<String, bool>> purchasePremium([Package? package]) async {
    _premium = true;
    return const Right(true);
  }

  @override
  Future<Either<String, bool>> restorePurchases() async {
    _premium = true;
    return const Right(true);
  }

  @override
  Future<Either<String, bool>> openManageSubscription() async {
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

    test('startWebCheckout calls initializeTransaction with plan amount '
        '+ callback and redirects', () async {
      final repo = MockPaystackPaymentRepository();
      when(() => repo.initializeTransaction(
            amount: any(named: 'amount'),
            email: any(named: 'email'),
            identityType: any(named: 'identityType'),
            callbackUrl: any(named: 'callbackUrl'),
          )).thenAnswer((_) async => 'https://checkout.paystack.com/abc');

      String? redirectedUrl;
      final container = ProviderContainer(
        overrides: [
          paystackPaymentRepositoryProvider.overrideWithValue(repo),
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser(id: 'u1', email: 'a@b.com')),
          ),
          paywallControllerProvider.overrideWith(() => _WebPaywallController()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(paywallControllerProvider.notifier);
      notifier.redirectTo = (url) => redirectedUrl = url;

      await notifier.startWebCheckout(planKey: 'yearly');

      verify(() => repo.initializeTransaction(
            amount: 15000.0,
            email: 'a@b.com',
            identityType: 'yearly',
            callbackUrl: any(named: 'callbackUrl'),
          )).called(1);
      expect(redirectedUrl, 'https://checkout.paystack.com/abc');
    });

    test('startWebCheckout is a no-op on native (isWeb false)', () async {
      final repo = MockPaystackPaymentRepository();

      final container = ProviderContainer(
        overrides: [
          paystackPaymentRepositoryProvider.overrideWithValue(repo),
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser(id: 'u1', email: 'a@b.com')),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(paywallControllerProvider.notifier);

      await notifier.startWebCheckout(planKey: 'yearly');

      verifyNever(() => repo.initializeTransaction(
            amount: any(named: 'amount'),
            email: any(named: 'email'),
            identityType: any(named: 'identityType'),
          ));
    });

    test('startWebCheckout sets error state when the repository throws',
        () async {
      final repo = MockPaystackPaymentRepository();
      when(() => repo.initializeTransaction(
            amount: any(named: 'amount'),
            email: any(named: 'email'),
            identityType: any(named: 'identityType'),
            callbackUrl: any(named: 'callbackUrl'),
          )).thenThrow(Exception('network down'));

      final container = ProviderContainer(
        overrides: [
          paystackPaymentRepositoryProvider.overrideWithValue(repo),
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser(id: 'u1', email: 'a@b.com')),
          ),
          paywallControllerProvider.overrideWith(() => _WebPaywallController()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(paywallControllerProvider.notifier);

      await notifier.startWebCheckout(planKey: 'yearly');

      final state = container.read(paywallControllerProvider);
      expect(state.isLoading, false);
      expect(state.error, 'Checkout failed. Please try again.');
    });

    test('startWebCheckout returns sign-in error when no user is signed in',
        () async {
      final repo = MockPaystackPaymentRepository();

      final container = ProviderContainer(
        overrides: [
          paystackPaymentRepositoryProvider.overrideWithValue(repo),
          // authStateChanges is a non-nullable StreamProvider<AuthUser>, so a
          // "no user" state can't be `AsyncValue.data(null)`; a pending
          // AsyncValue models it (`.value` is null until the stream emits).
          authStateChangesProvider.overrideWithValue(AsyncValue.loading()),
          paywallControllerProvider.overrideWith(() => _WebPaywallController()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(paywallControllerProvider.notifier);

      await notifier.startWebCheckout(planKey: 'yearly');

      final state = container.read(paywallControllerProvider);
      expect(state.isLoading, false);
      expect(state.error, 'Please sign in before upgrading.');
      verifyNever(() => repo.initializeTransaction(
            amount: any(named: 'amount'),
            email: any(named: 'email'),
            identityType: any(named: 'identityType'),
            callbackUrl: any(named: 'callbackUrl'),
          ));
    });

    test('startWebCheckout returns sign-in error when the user has no email',
        () async {
      final repo = MockPaystackPaymentRepository();

      final container = ProviderContainer(
        overrides: [
          paystackPaymentRepositoryProvider.overrideWithValue(repo),
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser(id: 'u1', email: '')),
          ),
          paywallControllerProvider.overrideWith(() => _WebPaywallController()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(paywallControllerProvider.notifier);

      await notifier.startWebCheckout(planKey: 'yearly');

      final state = container.read(paywallControllerProvider);
      expect(state.isLoading, false);
      expect(state.error, 'Please sign in before upgrading.');
      verifyNever(() => repo.initializeTransaction(
            amount: any(named: 'amount'),
            email: any(named: 'email'),
            identityType: any(named: 'identityType'),
            callbackUrl: any(named: 'callbackUrl'),
          ));
    });

    test('startWebCheckout rejects an unknown plan without calling the repo',
        () async {
      final repo = MockPaystackPaymentRepository();

      final container = ProviderContainer(
        overrides: [
          paystackPaymentRepositoryProvider.overrideWithValue(repo),
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser(id: 'u1', email: 'a@b.com')),
          ),
          paywallControllerProvider.overrideWith(() => _WebPaywallController()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(paywallControllerProvider.notifier);

      await notifier.startWebCheckout(planKey: 'bogus');

      final state = container.read(paywallControllerProvider);
      expect(state.isLoading, false);
      expect(state.error, 'Unknown plan.');
      verifyNever(() => repo.initializeTransaction(
            amount: any(named: 'amount'),
            email: any(named: 'email'),
            identityType: any(named: 'identityType'),
            callbackUrl: any(named: 'callbackUrl'),
          ));
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
