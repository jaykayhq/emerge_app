import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/welcome_screen.dart';
import '../../../../helpers/widget_test_utils.dart';

Widget _buildTest() {
  return createScreenUnderTest(screen: const WelcomeScreen());
}

void main() {
  testWidgets('renders without crash', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('displays title and welcome text', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pumpAndSettle();

    expect(find.text('Who do you wish to become?'), findsOneWidget);
    expect(find.text('Forge Your Identity. Build Your Habits.'), findsOneWidget);
  });

  testWidgets('get started button renders and is tappable', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pumpAndSettle();

    final button = find.ancestor(
      of: find.text('Begin Your Journey'),
      matching: find.byType(ElevatedButton),
    );
    expect(button, findsOneWidget);
    final ElevatedButton buttonWidget = tester.widget(button);
    expect(buttonWidget.onPressed, isNotNull);
  });
}
