import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/insights/domain/entities/insights_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Recap', () {
    const testRecap = Recap(
      id: 'recap_1',
      period: 'Weekly',
      dateRange: 'Jun 10-16, 2025',
      habitsCompleted: 20,
      perfectDays: 5,
      xpGained: 450,
      focusTime: '12h',
      summary: 'Great week!',
      consistencyChange: 0.15,
    );

    test('constructor sets all fields correctly', () {
      expect(testRecap.id, 'recap_1');
      expect(testRecap.period, 'Weekly');
      expect(testRecap.dateRange, 'Jun 10-16, 2025');
      expect(testRecap.habitsCompleted, 20);
      expect(testRecap.perfectDays, 5);
      expect(testRecap.xpGained, 450);
      expect(testRecap.focusTime, '12h');
      expect(testRecap.summary, 'Great week!');
      expect(testRecap.consistencyChange, 0.15);
    });

    test('toMap/fromMap roundtrip with all fields', () {
      final map = testRecap.toMap();
      final restored = Recap.fromMap(map);

      expect(restored.id, testRecap.id);
      expect(restored.period, testRecap.period);
      expect(restored.dateRange, testRecap.dateRange);
      expect(restored.habitsCompleted, testRecap.habitsCompleted);
      expect(restored.perfectDays, testRecap.perfectDays);
      expect(restored.xpGained, testRecap.xpGained);
      expect(restored.focusTime, testRecap.focusTime);
      expect(restored.summary, testRecap.summary);
      expect(restored.consistencyChange, testRecap.consistencyChange);
    });

    test('fromMap with missing keys uses defaults', () {
      final restored = Recap.fromMap({});

      expect(restored.id, 'empty');
      expect(restored.period, 'Weekly');
      expect(restored.dateRange, '');
      expect(restored.habitsCompleted, 0);
      expect(restored.perfectDays, 0);
      expect(restored.xpGained, 0);
      expect(restored.focusTime, '0h');
      expect(restored.summary, '');
      expect(restored.consistencyChange, 0.0);
    });

    test('consistencyChange properly converted from num to double', () {
      final map = <String, dynamic>{
        'id': 'r1',
        'period': 'Monthly',
        'dateRange': 'June 2025',
        'habitsCompleted': 10,
        'perfectDays': 3,
        'xpGained': 200,
        'focusTime': '5h',
        'summary': 'Good',
        'consistencyChange': 0.5, // int, not double
      };
      final restored = Recap.fromMap(map);
      expect(restored.consistencyChange, isA<double>());
      expect(restored.consistencyChange, 0.5);
    });
  });

  group('Reflection', () {
    final now = DateTime(2025, 6, 16, 10, 30, 0);
    final testReflection = Reflection(
      id: 'ref_1',
      date: '2025-06-16',
      title: 'Day Insight',
      content: 'I noticed I work best in the morning.',
      type: 'insight',
      moodValue: 0.8,
      createdAt: now,
    );

    test('constructor with all fields including moodValue and createdAt', () {
      expect(testReflection.id, 'ref_1');
      expect(testReflection.date, '2025-06-16');
      expect(testReflection.title, 'Day Insight');
      expect(testReflection.content,
          'I noticed I work best in the morning.');
      expect(testReflection.type, 'insight');
      expect(testReflection.moodValue, 0.8);
      expect(testReflection.createdAt, now);
    });

    test('toMap/fromMap roundtrip', () {
      final map = testReflection.toMap(useServerTimestamp: false);
      final restored = Reflection.fromMap(map);

      expect(restored.id, testReflection.id);
      expect(restored.date, testReflection.date);
      expect(restored.title, testReflection.title);
      expect(restored.content, testReflection.content);
      expect(restored.type, testReflection.type);
      expect(restored.moodValue, testReflection.moodValue);
      expect(restored.createdAt, testReflection.createdAt);
    });

    test('fromMap handles Firestore Timestamp for createdAt', () {
      final map = <String, dynamic>{
        'id': 'ref_2',
        'date': '2025-06-15',
        'title': 'Test',
        'content': 'Content',
        'type': 'daily',
        'moodValue': 0.5,
        'createdAt': Timestamp.fromDate(now),
      };
      final restored = Reflection.fromMap(map);
      expect(restored.createdAt, now);
    });

    test('fromMap handles String for createdAt', () {
      final map = <String, dynamic>{
        'id': 'ref_3',
        'date': '2025-06-14',
        'title': 'Test',
        'content': 'Content',
        'type': 'pattern',
        'moodValue': 0.3,
        'createdAt': now.toIso8601String(),
      };
      final restored = Reflection.fromMap(map);
      expect(restored.createdAt, now);
    });

    test('fromMap with null moodValue and createdAt', () {
      final map = <String, dynamic>{
        'id': 'ref_4',
        'date': '2025-06-13',
        'title': 'No Mood',
        'content': 'Content',
        'type': 'suggestion',
      };
      final restored = Reflection.fromMap(map);
      expect(restored.moodValue, isNull);
      expect(restored.createdAt, isNull);
    });

    test('fromMap accepts optional docId parameter and takes priority', () {
      final map = <String, dynamic>{
        'id': 'wrong_id',
        'date': '2025-06-12',
        'title': 'Doc ID Test',
        'content': 'Content',
        'type': 'insight',
      };
      final restored = Reflection.fromMap(map, 'correct_id');
      expect(restored.id, 'correct_id');
    });

    test('fromMap with missing fields uses defaults', () {
      final restored = Reflection.fromMap({});

      expect(restored.id, '');
      expect(restored.date, '');
      expect(restored.title, '');
      expect(restored.content, '');
      expect(restored.type, 'insight');
      expect(restored.moodValue, isNull);
      expect(restored.createdAt, isNull);
    });
  });
}
