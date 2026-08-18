// test/features/gamification/presentation/widgets/recap_share_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/recap_share_sheet.dart';

void main() {
  final recap = UserWeeklyRecap(
    id: 'r1',
    userId: 'u1',
    startDate: DateTime(2026, 8, 10),
    endDate: DateTime(2026, 8, 16),
    totalHabitsCompleted: 42,
    perfectDays: 5,
    totalXpEarned: 500,
    topHabitName: 'Read',
    currentLevel: 7,
    worldGrowthPercentage: 0.4,
  );

  testWidgets('shows both share options', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => RecapShareSheet(recap: recap, currentIndex: 1),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Share current slide'), findsOneWidget);
    expect(find.text('Share all slides'), findsOneWidget);
    expect(find.text('Could not share the recap image.'), findsNothing);
  });

  testWidgets('surfaces an export failure inline in the sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => RecapShareSheet(
                  recap: recap,
                  currentIndex: 1,
                  onExportOverride: () async => false,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share current slide'));
    await tester.pumpAndSettle();

    // The failure must be visible inside the sheet — a floating snackbar
    // would be hidden behind the modal barrier.
    expect(find.text('Could not share the recap image.'), findsOneWidget);
    expect(find.text('Share your recap'), findsOneWidget);
  });

  testWidgets('closes the sheet on a successful export', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => RecapShareSheet(
                  recap: recap,
                  currentIndex: 1,
                  onExportOverride: () async => true,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share current slide'));
    await tester.pumpAndSettle();

    expect(find.text('Share your recap'), findsNothing);
  });
}