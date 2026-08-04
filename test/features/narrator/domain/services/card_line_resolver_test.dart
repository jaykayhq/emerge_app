import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/services/card_line_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const day = DayStatus(
    completed: 1,
    total: 3,
    streak: 4,
    firstIncompleteName: 'Read 10 pages',
  );

  group('dayStatusLine', () {
    test('empty day invites the first habit', () {
      expect(
        dayStatusLine(const DayStatus(completed: 0, total: 0, streak: 0)),
        'This is where your day takes shape. Add a habit and I\'ll keep watch.',
      );
    });

    test('remaining habits name the first incomplete one', () {
      expect(dayStatusLine(day), '2 left today — start with Read 10 pages.');
    });

    test('remaining without a name stays simple', () {
      expect(
        dayStatusLine(const DayStatus(completed: 1, total: 3, streak: 0)),
        '2 left today.',
      );
    });

    test('all done with a streak names the streak', () {
      expect(
        dayStatusLine(const DayStatus(completed: 3, total: 3, streak: 4)),
        'All done for today. 4-day streak is starting to hold you.',
      );
    });

    test('all done without a streak stays simple', () {
      expect(
        dayStatusLine(const DayStatus(completed: 3, total: 3, streak: 0)),
        'All done for today. That\'s how momentum starts.',
      );
    });
  });

  group('resolveCardLine', () {
    test('pending milestone line wins', () {
      const pending = GenericLine('You are on fire.');
      final line = resolveCardLine(
        pendingLine: pending,
        insightText: 'Some old insight',
        day: day,
      );
      expect(line, same(pending));
    });

    test('insight text is used when nothing is pending', () {
      final line = resolveCardLine(
        pendingLine: null,
        insightText: 'Your best day is Thursday.',
        day: day,
      );
      expect(line!.text, 'Your best day is Thursday.');
    });

    test('day status is the fallback', () {
      final line = resolveCardLine(
        pendingLine: null,
        insightText: null,
        day: day,
      );
      expect(line!.text, '2 left today — start with Read 10 pages.');
    });

    test('empty-string insight falls through to day status', () {
      final line = resolveCardLine(
        pendingLine: null,
        insightText: '',
        day: day,
      );
      expect(line!.text, '2 left today — start with Read 10 pages.');
    });
  });
}
