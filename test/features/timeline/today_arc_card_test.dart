import 'package:emerge_app/features/timeline/presentation/widgets/today_arc_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders percent + remaining count', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TodayArcCard(completed: 4, total: 6, streakDays: 12)),
      ),
    );
    expect(find.textContaining('67%'), findsOneWidget);
    expect(find.textContaining('2'), findsOneWidget); // "2 habits left"
  });

  testWidgets('renders "Start your streak" when no streak', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TodayArcCard(completed: 0, total: 0, streakDays: 0)),
      ),
    );
    expect(find.textContaining('Start'), findsOneWidget);
  });
}
