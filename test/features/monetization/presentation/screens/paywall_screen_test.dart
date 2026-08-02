import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/monetization/presentation/providers/paywall_provider.dart';
import 'package:emerge_app/features/monetization/presentation/screens/paywall_screen.dart';

final loadingState = const PaywallState(isLoading: true);
final loadedState = const PaywallState(isLoading: false, offerings: null);

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
  testWidgets('shows Go Beyond the 5 headline and premium benefits',
      (tester) async {
    await tester.pumpWidget(createTest(loadingState));
    await tester.pump();

    expect(find.text('Go Beyond the 5'), findsOneWidget);
    expect(find.text('UNLIMITED HABITS'), findsOneWidget);
    expect(find.text('UNLIMITED CLUBS'), findsOneWidget);
    expect(find.text('UNLIMITED COACH ASKS'), findsOneWidget);
    expect(find.text('MORE WORLD THEMES'), findsOneWidget);
    expect(find.text('Free: 5 active habits · Premium: no cap'), findsOneWidget);
    expect(find.text('PREMIUM INSIGHTS'), findsOneWidget);
    expect(find.text('EXCLUSIVE STYLE'), findsOneWidget);
    expect(find.text('Restore'), findsOneWidget);
  });

  testWidgets('shows no packages available when offerings null',
      (tester) async {
    await tester.pumpWidget(createTest(loadedState));
    await tester.pump();

    expect(
      find.text('No subscription packages available currently.'),
      findsOneWidget,
    );
  });
}
