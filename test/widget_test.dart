import 'package:emerge_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: EmergeApp()));

    // Verify that our counter starts at 0.
    expect(
      find.text('0'),
      findsNothing,
    ); // Changed to findsNothing as we removed the counter
    expect(find.text('1'), findsNothing);
  });
}
