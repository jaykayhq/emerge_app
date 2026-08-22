import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/features/social/domain/services/friend_presence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 22, 12, 0);

  group('FriendPresence.isOnline', () {
    test('is false without a presence document', () {
      expect(
        FriendPresence.isOnline(onlineFlag: false, lastSeen: null, now: now),
        isFalse,
      );
    });

    test('is false when the online flag is not set', () {
      expect(
        FriendPresence.isOnline(
          onlineFlag: false,
          lastSeen: now.subtract(const Duration(seconds: 10)),
          now: now,
        ),
        isFalse,
      );
    });

    test('is true for a fresh heartbeat', () {
      expect(
        FriendPresence.isOnline(
          onlineFlag: true,
          lastSeen: now.subtract(const Duration(minutes: 2)),
          now: now,
        ),
        isTrue,
      );
    });

    test('expires after the heartbeat timeout', () {
      expect(
        FriendPresence.isOnline(
          onlineFlag: true,
          lastSeen: now.subtract(const Duration(minutes: 6)),
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('FriendPresence.markOnline', () {
    test('returns friends whose presence is fresh, flagged online', () {
      final alice = Friend(id: 'alice', name: 'Alice', archetype: FriendArchetype.stoic);
      final bob = Friend(id: 'bob', name: 'Bob', archetype: FriendArchetype.stoic);

      final result = FriendPresence.markOnline([alice, bob], {
        'alice': (onlineFlag: true, lastSeen: now.subtract(const Duration(minutes: 1))),
      }, now: now);

      expect(result.map((f) => f.id), ['alice']);
      expect(result.first.isOnline, isTrue);
    });

    test('drops friends with stale or missing presence', () {
      final alice = Friend(id: 'alice', name: 'Alice', archetype: FriendArchetype.stoic);
      final bob = Friend(id: 'bob', name: 'Bob', archetype: FriendArchetype.stoic);

      final result = FriendPresence.markOnline([alice, bob], {
        'alice': (onlineFlag: true, lastSeen: now.subtract(const Duration(minutes: 30))),
        // bob has no presence entry at all
      }, now: now);

      expect(result, isEmpty);
    });
  });
}
