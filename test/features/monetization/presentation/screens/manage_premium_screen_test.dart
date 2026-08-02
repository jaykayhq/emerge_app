import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/domain/repositories/monetization_repository.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/monetization/presentation/screens/manage_premium_screen.dart';
import 'package:emerge_app/features/monetization/data/services/manage_premium_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class _FakeMonetizationRepository implements MonetizationRepository {
  int openManageCalls = 0;
  @override
  Future<Either<String, bool>> openManageSubscription() async {
    openManageCalls++;
    return const Right(true);
  }
  // Unused members — fail loudly if touched.
  @override
  Future<Either<String, Map<String, String>>> getConsumablePrices(List<String> productIds) async => const Left('unused');
  @override
  Future<Either<String, bool>> get isPremium async => const Right(true);
  @override
  Future<Either<String, Offerings>> getOfferings() async => const Left('unused');
  @override
  Future<void> identify(String uid) async {}
  @override
  Future<void> initialize({String? uid}) async {}
  @override
  Future<Either<String, bool>> purchaseConsumable(String productId) async => const Left('unused');
  @override
  Future<Either<String, bool>> purchasePremium([Package? package]) async => const Right(true);
  @override
  Future<Either<String, bool>> restorePurchases() async => const Right(true);
  @override
  Future<String?> get premiumPriceString async => '\$4.99/mo';
  @override
  Stream<bool> get premiumStatusStream => const Stream.empty();
  @override
  Future<void> reset() async {}
}

class _FakeManagePremiumService extends ManagePremiumService {
  _FakeManagePremiumService() : super(_FakeCaller());
  int cancelCalls = 0;
  int pauseCalls = 0;

  @override
  Future<Either<String, void>> cancel() async {
    cancelCalls++;
    return const Right(null);
  }

  @override
  Future<Either<String, void>> pause() async {
    pauseCalls++;
    return const Right(null);
  }
}

class _FakeCaller implements ManagePremiumCaller {
  @override
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data) async {
    return {'ok': true};
  }
}

class _FakeIsPremium extends IsPremium {
  final bool premium;
  _FakeIsPremium(this.premium);

  @override
  Future<bool> build() async => premium;
}

ProviderScope _pump({
  required MonetizationRepository repo,
  required ManagePremiumService service,
}) {
  return ProviderScope(
    overrides: [
      monetizationRepositoryProvider.overrideWithValue(repo),
      managePremiumServiceProvider.overrideWithValue(service),
      isPremiumProvider.overrideWith(() => _FakeIsPremium(true)),
      userStreakProvider.overrideWith((ref) => Stream.value(0)),
      habitsProvider.overrideWith((ref) => Stream.value(const [])),
    ],
    child: const MaterialApp(home: ManagePremiumScreen()),
  );
}

void main() {
  testWidgets('renders plan status and the cancel entry', (tester) async {
    await tester.pumpWidget(_pump(
      repo: _FakeMonetizationRepository(),
      service: _FakeManagePremiumService(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Manage Premium'), findsOneWidget);
    expect(find.text('Cancel subscription'), findsOneWidget);
  });

  testWidgets('cancel flow: recap -> pause step -> confirm opens store manage page',
      (tester) async {
    final repo = _FakeMonetizationRepository();
    final service = _FakeManagePremiumService();
    await tester.pumpWidget(_pump(repo: repo, service: service));
    await tester.pumpAndSettle();

    // Step 1 — loss framing + endowment recap.
    await tester.tap(find.text('Cancel subscription'));
    await tester.pumpAndSettle();
    expect(find.textContaining("You're about to lose"), findsOneWidget);
    expect(find.text('Keep Premium'), findsOneWidget);

    // Step 2 — pause/save step.
    await tester.tap(find.text('Continue cancelling'));
    await tester.pumpAndSettle();
    expect(find.text('Pause instead?'), findsOneWidget);

    // Step 3 — confirm; native opens the store manage page, never a callable.
    await tester.tap(find.text('Cancel anyway'));
    await tester.pumpAndSettle();
    expect(repo.openManageCalls, 1);
    expect(service.cancelCalls, 0);
    expect(find.textContaining('Finish cancelling in Google Play'), findsOneWidget);
  });

  testWidgets(
      'native confirm CTA is inert after store-open: no second store call, no done state',
      (tester) async {
    final repo = _FakeMonetizationRepository();
    final service = _FakeManagePremiumService();
    await tester.pumpWidget(_pump(repo: repo, service: service));
    await tester.pumpAndSettle();

    // Reach the confirm step the same way the flow test does.
    await tester.tap(find.text('Cancel subscription'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue cancelling'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel anyway'));
    await tester.pumpAndSettle();
    expect(repo.openManageCalls, 1);

    // The store page already opened — the CTA must be inert, pointing at Play.
    final confirmButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Finish in Google Play'),
    );
    expect(confirmButton.onPressed, isNull);

    // Tapping it must not re-open the store nor claim cancellation.
    await tester.tap(find.text('Finish in Google Play'));
    await tester.pumpAndSettle();
    expect(repo.openManageCalls, 1);
    expect(find.text('Premium cancelled'), findsNothing);
  });
}
