import 'package:emerge_app/features/pulse_feed/domain/models/pulse_feed_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PulseFeedCardType', () {
    test('has three values', () {
      expect(PulseFeedCardType.values.length, 3);
    });

    test('contains identityVote', () {
      expect(PulseFeedCardType.values,
          contains(PulseFeedCardType.identityVote));
    });

    test('contains tribeActivity', () {
      expect(PulseFeedCardType.values,
          contains(PulseFeedCardType.tribeActivity));
    });

    test('contains weeklyInsight', () {
      expect(PulseFeedCardType.values,
          contains(PulseFeedCardType.weeklyInsight));
    });
  });

  group('PulseFeedCard', () {
    final now = DateTime(2026, 7, 2, 10, 30);

    test('default constructor', () {
      final card = PulseFeedCard(
        id: 'card_1',
        type: PulseFeedCardType.identityVote,
        headline: 'Someone voted for you!',
        createdAt: now,
      );

      expect(card.id, 'card_1');
      expect(card.type, PulseFeedCardType.identityVote);
      expect(card.headline, 'Someone voted for you!');
      expect(card.subtext, isNull);
      expect(card.createdAt, now);
      expect(card.habitId, isNull);
      expect(card.tribeUserId, isNull);
    });

    test('constructor with all fields', () {
      final card = PulseFeedCard(
        id: 'card_2',
        type: PulseFeedCardType.tribeActivity,
        headline: 'Alice completed Morning Run',
        subtext: 'Streak: 15 days 🔥',
        createdAt: now,
        habitId: 'habit_abc',
        tribeUserId: 'user_123',
      );

      expect(card.id, 'card_2');
      expect(card.type, PulseFeedCardType.tribeActivity);
      expect(card.headline, 'Alice completed Morning Run');
      expect(card.subtext, 'Streak: 15 days 🔥');
      expect(card.createdAt, now);
      expect(card.habitId, 'habit_abc');
      expect(card.tribeUserId, 'user_123');
    });

    group('fromJson / toJson', () {
      test('roundtrip with all fields', () {
        final card = PulseFeedCard(
          id: 'card_roundtrip',
          type: PulseFeedCardType.weeklyInsight,
          headline: 'Your consistency is up 12% this week',
          subtext: 'Keep it going!',
          createdAt: now,
          habitId: 'habit_xyz',
          tribeUserId: 'user_456',
        );

        final json = card.toJson();
        final restored = PulseFeedCard.fromJson(json);

        expect(restored, equals(card));
        expect(restored.id, card.id);
        expect(restored.type, card.type);
        expect(restored.headline, card.headline);
        expect(restored.subtext, card.subtext);
        expect(restored.createdAt, card.createdAt);
        expect(restored.habitId, card.habitId);
        expect(restored.tribeUserId, card.tribeUserId);
      });

      test('roundtrip with only required fields', () {
        final card = PulseFeedCard(
          id: 'card_minimal',
          type: PulseFeedCardType.identityVote,
          headline: 'New vote!',
          createdAt: now,
        );

        final json = card.toJson();
        final restored = PulseFeedCard.fromJson(json);

        expect(restored, equals(card));
        expect(restored.subtext, isNull);
        expect(restored.habitId, isNull);
        expect(restored.tribeUserId, isNull);
      });

      test('fromJson handles missing fields with defaults', () {
        final restored = PulseFeedCard.fromJson({});
        expect(restored.id, '');
        expect(restored.type, PulseFeedCardType.tribeActivity);
        expect(restored.headline, '');
        expect(restored.subtext, isNull);
        expect(restored.createdAt, isA<DateTime>());
        expect(restored.habitId, isNull);
        expect(restored.tribeUserId, isNull);
      });

      test('fromJson parses createdAt as ISO string', () {
        final json = {
          'id': 'test',
          'type': 'identityVote',
          'headline': 'Test',
          'createdAt': '2026-07-02T10:30:00.000',
        };
        final restored = PulseFeedCard.fromJson(json);
        expect(restored.createdAt.year, 2026);
        expect(restored.createdAt.month, 7);
        expect(restored.createdAt.day, 2);
        expect(restored.createdAt.hour, 10);
        expect(restored.createdAt.minute, 30);
      });

      test('fromJson parses createdAt as timestamp milliseconds', () {
        final timestamp = now.millisecondsSinceEpoch;
        final json = {
          'id': 'test',
          'type': 'weeklyInsight',
          'headline': 'Test',
          'createdAt': timestamp,
        };
        final restored = PulseFeedCard.fromJson(json);
        expect(restored.createdAt, now);
      });

      test('fromJson defaults type to tribeActivity for unknown type', () {
        final json = {
          'id': 'test',
          'type': 'unknown_type',
          'headline': 'Test',
          'createdAt': '2026-07-02T10:30:00.000',
        };
        final restored = PulseFeedCard.fromJson(json);
        expect(restored.type, PulseFeedCardType.tribeActivity);
      });

      test('toJson omits null optional fields', () {
        final card = PulseFeedCard(
          id: 'no_nulls',
          type: PulseFeedCardType.identityVote,
          headline: 'No nulls',
          createdAt: now,
        );
        final json = card.toJson();
        expect(json.containsKey('subtext'), false);
        expect(json.containsKey('habitId'), false);
        expect(json.containsKey('tribeUserId'), false);
      });

      test('toJson includes non-null optional fields', () {
        final card = PulseFeedCard(
          id: 'with_nulls',
          type: PulseFeedCardType.tribeActivity,
          headline: 'With optionals',
          createdAt: now,
          subtext: 'sub',
          habitId: 'h1',
          tribeUserId: 'u1',
        );
        final json = card.toJson();
        expect(json['subtext'], 'sub');
        expect(json['habitId'], 'h1');
        expect(json['tribeUserId'], 'u1');
      });
    });

    group('equality', () {
      test('identical cards are equal', () {
        final a = PulseFeedCard(
          id: 'eq',
          type: PulseFeedCardType.identityVote,
          headline: 'Equal',
          createdAt: now,
        );
        final b = PulseFeedCard(
          id: 'eq',
          type: PulseFeedCardType.identityVote,
          headline: 'Equal',
          createdAt: now,
        );
        expect(a, equals(b));
      });

      test('different IDs are not equal', () {
        final a = PulseFeedCard(
          id: 'a',
          type: PulseFeedCardType.identityVote,
          headline: 'Test',
          createdAt: now,
        );
        final b = PulseFeedCard(
          id: 'b',
          type: PulseFeedCardType.identityVote,
          headline: 'Test',
          createdAt: now,
        );
        expect(a, isNot(equals(b)));
      });
    });

    test('toString returns meaningful representation', () {
      final card = PulseFeedCard(
        id: 'str_test',
        type: PulseFeedCardType.weeklyInsight,
        headline: 'Summary',
        createdAt: now,
      );
      final str = card.toString();
      expect(str, contains('PulseFeedCard'));
      expect(str, contains('str_test'));
      expect(str, contains('weeklyInsight'));
      expect(str, contains('Summary'));
    });
  });
}
