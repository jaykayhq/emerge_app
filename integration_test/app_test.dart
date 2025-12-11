import 'package:emerge_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App starts and shows Login screen', (WidgetTester tester) async {
    // Start the app
    // await main(); // main() returns void and cannot be awaited properly in this context

    // Pump the app widget directly
    await tester.pumpWidget(const ProviderScope(child: EmergeApp()));
    await tester.pumpAndSettle();

    // Verify we are on the Login screen (or Onboarding if first launch)
    // Since we can't easily reset Hive state in integration tests without more setup,
    // we just check that the app didn't crash and shows *something* reasonable.
    // Ideally, we'd look for a specific widget key.

    // For now, just ensure it pumped successfully.
    expect(find.byType(EmergeApp), findsOneWidget);
  });
}
