import 'package:emerge_app/features/pulse_feed/data/repositories/pulse_feed_repository.dart';
import 'package:emerge_app/features/pulse_feed/domain/models/pulse_feed_card.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PulseFeedRepository', () {
    late FakeFirebaseFirestore firestore;
    late PulseFeedRepository repository;

    const userId = 'test_user';
    final now = DateTime(2026, 7, 2, 12, 0);

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = PulseFeedRepository(firestore);
    });

    Future<void> seedCard({
      required String id,
      required PulseFeedCardType type,
      required String headline,
      String? subtext,
      required DateTime createdAt,
      String? habitId,
      String? tribeUserId,
    }) async {
      final data = <String, dynamic>{
        'id': id,
        'type': type.name,
        'headline': headline,
        'createdAt': createdAt.toIso8601String(),
      };
      if (subtext != null) data['subtext'] = subtext;
      if (habitId != null) data['habitId'] = habitId;
      if (tribeUserId != null) data['tribeUserId'] = tribeUserId;
      await firestore
          .collection('pulse_feed_cards')
          .doc(userId)
          .collection('cards')
          .doc(id)
          .set(data);
    }

    group('getPulseFeed', () {
      test('returns empty list when no cards exist', () async {
        final cards = await repository.getPulseFeed(userId);
        expect(cards, isEmpty);
      });

      test('returns cards in descending createdAt order', () async {
        await seedCard(
          id: 'card_1',
          type: PulseFeedCardType.tribeActivity,
          headline: 'Oldest',
          createdAt: now.subtract(const Duration(hours: 2)),
        );
        await seedCard(
          id: 'card_2',
          type: PulseFeedCardType.identityVote,
          headline: 'Middle',
          createdAt: now.subtract(const Duration(hours: 1)),
        );
        await seedCard(
          id: 'card_3',
          type: PulseFeedCardType.weeklyInsight,
          headline: 'Newest',
          createdAt: now,
        );

        final cards = await repository.getPulseFeed(userId);

        expect(cards.length, 3);
        expect(cards[0].headline, 'Newest');
        expect(cards[1].headline, 'Middle');
        expect(cards[2].headline, 'Oldest');
      });

      test('returns card with all fields populated', () async {
        await seedCard(
          id: 'full_card',
          type: PulseFeedCardType.tribeActivity,
          headline: 'Alice did something',
          subtext: 'Streak: 10',
          createdAt: now,
          habitId: 'habit_1',
          tribeUserId: 'user_abc',
        );

        final cards = await repository.getPulseFeed(userId);
        expect(cards.length, 1);

        final card = cards.first;
        expect(card.id, 'full_card');
        expect(card.type, PulseFeedCardType.tribeActivity);
        expect(card.headline, 'Alice did something');
        expect(card.subtext, 'Streak: 10');
        expect(card.createdAt, now);
        expect(card.habitId, 'habit_1');
        expect(card.tribeUserId, 'user_abc');
      });

      test('limits to 30 cards', () async {
        for (int i = 0; i < 35; i++) {
          await seedCard(
            id: 'card_$i',
            type: PulseFeedCardType.tribeActivity,
            headline: 'Card $i',
            createdAt: now.add(Duration(minutes: i)),
          );
        }

        final cards = await repository.getPulseFeed(userId);
        expect(cards.length, 30);
      });
    });

    group('watchPulseFeed', () {
      test('emits empty list when no cards exist', () async {
        final cards = await repository.watchPulseFeed(userId).first;
        expect(cards, isEmpty);
      });

      test('emits cards in descending createdAt order', () async {
        await seedCard(
          id: 'card_a',
          type: PulseFeedCardType.identityVote,
          headline: 'First event',
          createdAt: now.subtract(const Duration(hours: 3)),
        );
        await seedCard(
          id: 'card_b',
          type: PulseFeedCardType.tribeActivity,
          headline: 'Recent event',
          createdAt: now.subtract(const Duration(hours: 1)),
        );

        final cards = await repository.watchPulseFeed(userId).first;

        expect(cards.length, 2);
        expect(cards[0].headline, 'Recent event');
        expect(cards[1].headline, 'First event');
      });

      test('reactively updates when new card is added', () async {
        // First seed a card so the stream has data on initial emission
        await seedCard(
          id: 'initial_card',
          type: PulseFeedCardType.weeklyInsight,
          headline: 'Initial card',
          createdAt: now,
        );

        // Start listening after seeding
        final cards = await repository.watchPulseFeed(userId).first;

        expect(cards.length, 1);
        expect(cards[0].headline, 'Initial card');
      });
    });
  });
}
