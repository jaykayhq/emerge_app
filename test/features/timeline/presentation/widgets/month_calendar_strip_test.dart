// Widget tests for MonthCalendarStrip's per-day completion dot + percentage.
//
// The strip renders one card per day of the current month inside a horizontal
// ListView (with cacheExtent, so neighboring days are built too). To assert a
// *deterministic* set of percentage texts, the completionStatus map covers
// every day of the current month (the strip keys days with
// yyyy-MM-dd strings built from DateTime.now(), same as the tests below).
import 'package:emerge_app/features/timeline/domain/models/day_completion.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/month_calendar_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String _dayKey(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// completionStatus entry for every day of the current month.
Map<String, DayCompletion> _fullMonthStatus(
  DayCompletion Function() make,
) {
  final now = DateTime.now();
  final lastDay = DateTime(now.year, now.month + 1, 0);
  return {
    for (var d = 1; d <= lastDay.day; d++)
      _dayKey(DateTime(now.year, now.month, d)): make(),
  };
}

Future<void> _pumpStrip(WidgetTester tester, MonthCalendarStrip strip) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: strip)),
  );
  // Let the initial scroll-to-today animation and the AnimatedContainer
  // transitions settle (no pending-timer flakiness).
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('complete days render 100% and never "--"', (tester) async {
    await _pumpStrip(
      tester,
      MonthCalendarStrip(
        completionStatus: _fullMonthStatus(
          () => const DayCompletion(
            status: DayCompletionStatus.complete,
            percent: 100,
          ),
        ),
      ),
    );

    expect(find.text('100%'), findsWidgets);
    expect(find.text('--'), findsNothing);
  });

  testWidgets('partial days render their percent (50%)', (tester) async {
    await _pumpStrip(
      tester,
      MonthCalendarStrip(
        completionStatus: _fullMonthStatus(
          () => const DayCompletion(
            status: DayCompletionStatus.partial,
            percent: 50,
          ),
        ),
      ),
    );

    expect(find.text('50%'), findsWidgets);
    expect(find.text('100%'), findsNothing);
    expect(find.text('--'), findsNothing);
  });

  testWidgets('days without completion data render "--"', (tester) async {
    await _pumpStrip(tester, const MonthCalendarStrip());

    expect(find.text('--'), findsWidgets);
    expect(find.text('100%'), findsNothing);
  });
}
