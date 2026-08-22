import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/services/social_notification_service.dart';
import 'package:emerge_app/features/social/data/repositories/friend_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreFriendRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreFriendRepository(
      firestore,
      null,
      SocialNotificationService(firestore),
    );
  });

  Future<void> seedUser(String uid, String name) async {
    await firestore.collection('users').doc(uid).set({
      'displayName': name,
      'archetype': 'stoic',
      'avatarStats': {'level': 3, 'currentXp': 120},
    });
  }

  group('sendPartnerRequest notifications', () {
    test('creates an in-app notification for the recipient', () async {
      await seedUser('alice', 'Alice');
      await seedUser('bob', 'Bob');

      await repo.sendPartnerRequest('alice', 'bob', 'Alice', 'stoic', 3);

      final notifications =
          await firestore.collection('users').doc('bob').collection('notifications').get();
      expect(notifications.docs, isNotEmpty,
          reason: 'recipient must be notified when a partner request arrives');
      final data = notifications.docs.first.data();
      expect(data['type'], 'friendRequest');
      expect(data['data']['senderId'], 'alice');
    });

    test('does not notify the sender', () async {
      await seedUser('alice', 'Alice');
      await seedUser('bob', 'Bob');

      await repo.sendPartnerRequest('alice', 'bob', 'Alice', 'stoic', 3);

      final senderNotifications =
          await firestore.collection('users').doc('alice').collection('notifications').get();
      expect(senderNotifications.docs, isEmpty);
    });
  });

  group('acceptPartnerRequest', () {
    test('notifies the original sender that the request was accepted',
        () async {
      await seedUser('alice', 'Alice');
      await seedUser('bob', 'Bob');

      final requestRef =
          await firestore.collection('partner_requests').add({
        'senderId': 'alice',
        'senderName': 'Alice',
        'senderArchetype': 'stoic',
        'senderLevel': 3,
        'recipientId': 'bob',
        'status': 'pending',
      });

      await repo.acceptPartnerRequest(requestRef.id);

      final notifications =
          await firestore.collection('users').doc('alice').collection('notifications').get();
      expect(notifications.docs, isNotEmpty,
          reason: 'sender must be notified when their request is accepted');
      final data = notifications.docs.first.data();
      expect(data['type'], 'friendRequestAccepted');
      expect(data['data']['friendId'], 'bob');
    });

    test('creates mutual friend records on both ends', () async {
      await seedUser('alice', 'Alice');
      await seedUser('bob', 'Bob');

      final requestRef = await firestore.collection('partner_requests').add({
        'senderId': 'alice',
        'senderName': 'Alice',
        'recipientId': 'bob',
        'status': 'pending',
      });

      await repo.acceptPartnerRequest(requestRef.id);

      final aliceFriends =
          await firestore.collection('users').doc('alice').collection('friends').get();
      final bobFriends =
          await firestore.collection('users').doc('bob').collection('friends').get();
      expect(aliceFriends.docs.map((d) => d.id), contains('bob'));
      expect(bobFriends.docs.map((d) => d.id), contains('alice'));
    });
  });

  group('watchOnlinePartners derives presence from heartbeat docs', () {
    test('returns only friends with a fresh online heartbeat', () async {
      await seedUser('me', 'Me');
      await seedUser('alice', 'Alice');
      await seedUser('bob', 'Bob');

      await repo.addFriend('me', 'alice');
      await repo.addFriend('me', 'bob');

      // Alice is online right now; Bob's heartbeat is stale.
      await firestore
          .collection('users')
          .doc('alice')
          .collection('presence')
          .doc('status')
          .set({
        'online': true,
        'lastSeen': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      });
      await firestore
          .collection('users')
          .doc('bob')
          .collection('presence')
          .doc('status')
          .set({
        'online': true,
        'lastSeen': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      });

      final online = await repo.watchOnlinePartners('me').first;
      expect(online.map((f) => f.id), ['alice']);
      expect(online.first.isOnline, isTrue);
    });

    test('excludes everyone when no presence docs exist yet', () async {
      await seedUser('me', 'Me');
      await seedUser('alice', 'Alice');
      await repo.addFriend('me', 'alice');

      final online = await repo.watchOnlinePartners('me').first;
      expect(online, isEmpty);
    });
  });
}
