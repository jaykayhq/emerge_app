import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/next_identity_vote.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_stoking_dock.dart';

void main() {
  final testHabit = Habit(
    id: 'h1',
    userId: 'u1',
    title: 'Morning Meditation',
    attribute: HabitAttribute.spirit,
    createdAt: DateTime(2026, 1, 1),
    currentStreak: 5,
  );

  group('WorldStokingDock Widget Tests', () {
    testWidgets(
      'actionable state displays habit title, attribute tag, vitality impact, and fires onCastVote when tapped',
      (tester) async {
        bool castVoted = false;
        bool openedHabit = false;

        final vote = NextIdentityVote.actionable(
          habit: testHabit,
          attribute: HabitAttribute.spirit,
          vitalityImpactPercent: 15,
          isRecovery: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WorldStokingDock(
                vote: vote,
                onCastVote: () {
                  castVoted = true;
                },
                onOpenHabit: () {
                  openedHabit = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('Morning Meditation'), findsOneWidget);
        expect(find.textContaining('SPIRIT'), findsWidgets);
        expect(find.textContaining('+15%'), findsWidgets);

        // Tap the primary action button
        await tester.tap(find.textContaining('CAST VOTE'));
        await tester.pumpAndSettle();
        expect(castVoted, isTrue);

        // Tap the habit title / card body to open habit
        await tester.tap(find.text('Morning Meditation'));
        await tester.pumpAndSettle();
        expect(openedHabit, isTrue);
      },
    );

    testWidgets(
      'recovery state displays RECOVERY ACTION, DISPELS FOG, and fires callback',
      (tester) async {
        bool castVoted = false;

        final vote = NextIdentityVote.actionable(
          habit: testHabit,
          attribute: HabitAttribute.spirit,
          vitalityImpactPercent: 20,
          isRecovery: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WorldStokingDock(
                vote: vote,
                onCastVote: () {
                  castVoted = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('Morning Meditation'), findsOneWidget);
        expect(find.textContaining('RECOVERY ACTION'), findsWidgets);
        expect(find.textContaining('DISPELS FOG'), findsWidgets);

        // Tap button
        final voteButton = find.textContaining('CAST VOTE');
        await tester.tap(voteButton);
        await tester.pumpAndSettle();
        expect(castVoted, isTrue);
      },
    );

    testWidgets(
      'harmonized state displays Realm in Golden Bloom, VIEW RECAP, and fires onOpenRecap',
      (tester) async {
        bool recapOpened = false;

        final vote = NextIdentityVote.harmonized();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WorldStokingDock(
                vote: vote,
                onOpenRecap: () {
                  recapOpened = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('Realm in Golden Bloom'), findsOneWidget);
        expect(find.text('VIEW RECAP'), findsOneWidget);

        await tester.tap(find.text('VIEW RECAP'));
        await tester.pumpAndSettle();
        expect(recapOpened, isTrue);
      },
    );

    testWidgets(
      'empty state displays Ignite Your First Archetype, ADD HABIT, and fires onNewHabit',
      (tester) async {
        bool newHabitOpened = false;

        final vote = NextIdentityVote.empty();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WorldStokingDock(
                vote: vote,
                onNewHabit: () {
                  newHabitOpened = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('Ignite Your First Archetype'), findsOneWidget);
        expect(find.text('ADD HABIT'), findsOneWidget);

        await tester.tap(find.text('ADD HABIT'));
        await tester.pumpAndSettle();
        expect(newHabitOpened, isTrue);
      },
    );
  });
}
