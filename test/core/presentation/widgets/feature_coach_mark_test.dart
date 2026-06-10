import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/presentation/widgets/feature_coach_mark.dart';

void main() {
  testWidgets('FeatureCoachMark renders title, items, and triggers onDismiss', (tester) async {
    bool dismissed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FeatureCoachMark(
          title: 'Test Coach Mark',
          primaryColor: Colors.blue,
          items: const [
            CoachItemData(icon: Icons.star, title: 'Item 1', body: 'Body 1'),
          ],
          onDismiss: () => dismissed = true,
        ),
      ),
    ));

    expect(find.text('Test Coach Mark'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Body 1'), findsOneWidget);

    await tester.tap(find.text("GOT IT — LET'S GO"));
    await tester.pumpAndSettle();
    expect(dismissed, isTrue);
  });
}
