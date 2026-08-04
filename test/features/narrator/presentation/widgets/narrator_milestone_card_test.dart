import 'dart:ui' show SemanticsAction;

import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_milestone_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const line = GenericLine('You missed a step. But you did not stop.');

  testWidgets('types the line out and tap-to-skips', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NarratorMilestoneCard(
            line: line,
            trigger: NarratorTrigger.streakBreakFirstMiss,
          ),
        ),
      ),
    );
    // The typed line is the only text containing 'You' (the label is
    // 'STREAK', the hint is 'Swipe ↑').
    await tester.pump(const Duration(milliseconds: 100)); // partial
    final partial = tester
        .widget<Text>(find.textContaining('You'))
        .textSpan!
        .toPlainText(includePlaceholders: false);
    expect(partial.length, lessThan(line.text.length));
    await tester.tap(find.textContaining('You')); // tap-to-skip
    await tester.pump();
    expect(
      tester
          .widget<Text>(find.textContaining('You'))
          .textSpan!
          .toPlainText(includePlaceholders: false),
      line.text,
    );
  });

  testWidgets('renders action chips and fires them', (tester) async {
    var tapped = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NarratorMilestoneCard(
            line: line,
            trigger: NarratorTrigger.eveningReflection,
            actions: [
              NarratorMilestoneAction(
                label: 'Log Reflection',
                onTap: () => tapped = 'log',
              ),
              NarratorMilestoneAction(
                label: 'Skip',
                onTap: () => tapped = 'skip',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2)); // finish typing
    await tester.tap(find.text('Log Reflection'));
    expect(tapped, 'log');
  });

  testWidgets('second action chip fires its callback', (tester) async {
    var tapped = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NarratorMilestoneCard(
            line: line,
            trigger: NarratorTrigger.eveningReflection,
            actions: [
              NarratorMilestoneAction(
                label: 'Log Reflection',
                onTap: () => tapped = 'log',
              ),
              NarratorMilestoneAction(
                label: 'Skip',
                onTap: () => tapped = 'skip',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2)); // finish typing
    await tester.tap(find.text('Skip'));
    expect(tapped, 'skip');
  });

  testWidgets('6s auto-dismiss still fires when actions are present', (
    tester,
  ) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NarratorMilestoneCard(
            line: line,
            trigger: NarratorTrigger.eveningReflection,
            actions: [
              NarratorMilestoneAction(label: 'Log Reflection', onTap: () {}),
            ],
            onDismissed: () => dismissed = true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 7)); // past the 6s auto-dismiss
    expect(dismissed, true);
  });

  // Semantics are enabled by default in testWidgets (semanticsEnabled: true).
  testWidgets('chip is individually activatable via semantics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NarratorMilestoneCard(
            line: line,
            trigger: NarratorTrigger.eveningReflection,
            actions: [
              NarratorMilestoneAction(label: 'Log Reflection', onTap: () {}),
            ],
          ),
        ),
      ),
    );
    final semantics = tester.getSemantics(find.text('Log Reflection'));
    expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), true);
    expect(semantics.label, contains('Log Reflection'));
  });

  testWidgets('chip tap cancels the auto-dismiss timer', (tester) async {
    var tapped = '';
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NarratorMilestoneCard(
            line: line,
            trigger: NarratorTrigger.eveningReflection,
            actions: [
              NarratorMilestoneAction(
                label: 'Log Reflection',
                onTap: () => tapped = 'log',
              ),
            ],
            onDismissed: () => dismissed = true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2)); // finish typing
    await tester.tap(find.text('Log Reflection'));
    await tester.pump();
    expect(tapped, 'log');
    // The tap cancelled the auto-dismiss timer: the card lingers well past
    // the 6s mark instead of being dismissed.
    await tester.pump(const Duration(seconds: 7));
    expect(dismissed, false);
    expect(tapped, 'log');
  });

  testWidgets('renders a PersonalLine with the PERSONAL badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NarratorMilestoneCard(
            line: PersonalLine(
              text: '14-day streak — Tuesday strongest.',
              dataBasis: 'x',
            ),
            trigger: NarratorTrigger.onFireState,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2)); // finish typing
    expect(find.text('14-day streak — Tuesday strongest.'), findsOneWidget);
    expect(find.text('PERSONAL'), findsOneWidget);
  });
}
