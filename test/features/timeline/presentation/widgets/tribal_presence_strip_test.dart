import 'package:emerge_app/features/timeline/presentation/widgets/tribal_presence_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows tribe members done message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TribalPresenceStrip(
            memberCount: 3,
            habitLabel: 'morning habits',
          ),
        ),
      ),
    );

    expect(
      find.text('Tribe: 3 members done morning habits so far'),
      findsOneWidget,
    );
  });
}
