import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Habit.toMap', () {
    test('emits JSON-encodable dates (no Timestamp) so the sync '
        'engine can jsonEncode the map at enqueue time', () {
      final created = DateTime(2026, 7, 27, 9, 30);
      final last = DateTime(2026, 7, 28, 12, 0);
      final habit = Habit(
        id: 'h1',
        userId: 'u1',
        title: 'Morning Run',
        createdAt: created,
        lastCompletedDate: last,
      );

      final map = habit.toMap();

      expect(map['createdAt'], isA<String>());
      expect(map['createdAt'], equals(created.toIso8601String()));
      expect(map['lastCompletedDate'], isA<String>());
      expect(map['lastCompletedDate'], equals(last.toIso8601String()));

      // The real failure mode: enqueueSet -> jsonEncode(data).
      // Must not throw "Instance of 'Timestamp'".
      expect(() => jsonEncode(map), returnsNormally);
    });

    test('emits lastCompletedDate as null when unset', () {
      final habit = Habit.empty();
      final map = habit.toMap();
      expect(map['lastCompletedDate'], isNull);
    });
  });

  group('Habit.fromMap', () {
    test('parses ISO string dates (local/Drift round-trip)', () {
      final created = DateTime(2026, 7, 27, 9, 30);
      final last = DateTime(2026, 7, 28, 12, 0);
      final habit = Habit.fromMap({
        'id': 'h1',
        'userId': 'u1',
        'title': 'Morning Run',
        'createdAt': created.toIso8601String(),
        'lastCompletedDate': last.toIso8601String(),
      });
      expect(habit.createdAt, equals(created));
      expect(habit.lastCompletedDate, equals(last));
    });

    test('parses Firestore Timestamp dates (remote read)', () {
      final created = DateTime(2026, 7, 27, 9, 30);
      final habit = Habit.fromMap({
        'id': 'h1',
        'userId': 'u1',
        'title': 'Morning Run',
        'createdAt': Timestamp.fromDate(created),
      });
      expect(habit.createdAt, equals(created));
    });
  });
}
