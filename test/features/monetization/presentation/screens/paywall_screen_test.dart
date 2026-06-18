import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/monetization/presentation/providers/paywall_provider.dart';
import 'package:emerge_app/features/monetization/presentation/screens/paywall_screen.dart';

final loadingState = const PaywallState(isLoading: true);
final loadedState = PaywallState(isLoading: false, offerings: null);

class _MockPaywallController extends PaywallController {
  final PaywallState _state;
  _MockPaywallController(this._state);

  @override
  PaywallState build() => _state;

  @override
  Future<void> fetchOfferings() async {}
}

Widget createTest(PaywallState state) {
  return ProviderScope(
    overrides: [
      paywallControllerProvider.overrideWith(
        () => _MockPaywallController(state),
      ),
    ],
    child: const MaterialApp(
      home: PaywallScreen(),
    ),
  );
}

void main() {
  testWidgets('renders paywall screen', (tester) async {
    await tester.pumpWidget(createTest(loadingState));
    await tester.pump();

    expect(find.text('Evolve Your Avatar.'), findsOneWidget);
    expect(find.text('Command Your Entropy.'), findsOneWidget);
    expect(find.text('Restore Purchases'), findsOneWidget);
  });

  testWidgets('shows no packages available when offerings null',
      (tester) async {
    await tester.pumpWidget(createTest(loadedState));
    await tester.pump();

    expect(
      find.text(
        'No subscription packages available currently.',
      ),
      findsOneWidget,
    );
  });
}
