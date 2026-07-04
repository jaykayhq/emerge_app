import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_summary_card.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';

void main() {
  testWidgets('renders with default text when no insight available',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          latestNarratorInsightProvider
              .overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NarratorSummaryCard(),
          ),
        ),
      ),
    );

    // Wait for async resolution
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Should show the header
    expect(find.text('Narrator'), findsOneWidget);
  });

  testWidgets('renders with insight text when available', (tester) async {
    final insight = NarratorNote(
      id: 'test-note',
      type: NarratorNoteType.aiInsight,
      data: {'shellText': 'You write best before 9 AM.'},
      recordedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          latestNarratorInsightProvider
              .overrideWith((ref) async => insight),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NarratorSummaryCard(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Should show the insight text
    expect(find.textContaining('You write best before 9 AM.'),
        findsOneWidget);
  });

  testWidgets('displays Hear more and Add a habit buttons', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          latestNarratorInsightProvider
              .overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NarratorSummaryCard(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Hear More'), findsOneWidget);
    expect(find.text('Add Habit'), findsOneWidget);
  });
}
