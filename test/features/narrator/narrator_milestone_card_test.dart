import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_milestone_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders PersonalLine with dataBasis badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NarratorMilestoneCard(
            line: const PersonalLine(
              text: '14-day streak — Tuesday strongest.',
              dataBasis: 'Tuesday streak',
            ),
            trigger: NarratorTrigger.onFireState,
          ),
        ),
      ),
    );
    expect(find.text('14-day streak — Tuesday strongest.'), findsOneWidget);
    expect(find.text('PERSONAL'), findsOneWidget);
  });

  testWidgets('auto-dismisses after duration', (tester) async {
    bool dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NarratorMilestoneCard(
            line: const GenericLine('hi'),
            trigger: NarratorTrigger.levelUp,
            autoDismissAfter: const Duration(milliseconds: 100),
            onDismissed: () => dismissed = true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(dismissed, isTrue);
  });
}
