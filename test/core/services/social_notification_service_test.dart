import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/core/domain/entities/app_notification.dart';
import 'package:emerge_app/core/services/social_notification_service.dart';

// Mock classes
// ignore: subtype_of_sealed_class
class MockFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockBatch extends Mock implements WriteBatch {}

// ignore: subtype_of_sealed_class
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirestore mockFirestore;
  late MockCollectionReference mockNotificationsCollection;
  late MockDocumentReference mockDocRef;
  late SocialNotificationService service;

  setUpAll(() {
    registerFallbackValue(MockBatch());
  });

  setUp(() {
    mockFirestore = MockFirestore();
    mockNotificationsCollection = MockCollectionReference();
    mockDocRef = MockDocumentReference();
    service = SocialNotificationService(mockFirestore);

    // Setup default collection reference
    when(
      () => mockFirestore.collection('users').doc(any()),
    ).thenReturn(mockDocRef);
    when(
      () => mockDocRef.collection('notifications'),
    ).thenReturn(mockNotificationsCollection);
  });

  group('SocialNotificationService', () {
    group('sendNotification', () {
      test('sends notification and increments unread count', () async {
        // Arrange
        final mockNotification = AppNotification(
          id: '',
          type: AppNotificationType.friendRequest,
          title: 'Friend Request',
          body: 'Test user wants to be your friend',
          createdAt: DateTime.now(),
        );

        when(
          () => mockNotificationsCollection.add(any()),
        ).thenAnswer((_) async => mockDocRef);

        // Act
        final result = await service.sendNotification(
          'user123',
          mockNotification,
        );

        // Assert
        expect(result, isNotNull);
        verify(
          () => mockFirestore.collection('users').doc('user123'),
        ).called(1);
        verify(
          () => mockDocRef.update({
            'unreadNotificationCount': FieldValue.increment(1),
            'lastNotificationAt': any(named: 'lastNotificationAt'),
          }),
        ).called(1);
      });
    });

    group('sendNotificationToMultiple', () {
      test('sends notifications to multiple users in batch', () async {
        // Arrange
        final mockNotification = AppNotification(
          id: '',
          type: AppNotificationType.challengeInvite,
          title: 'Challenge Invite',
          body: 'Join this challenge!',
          createdAt: DateTime.now(),
        );

        when(
          () => mockFirestore.collection('users').doc(any()),
        ).thenReturn(mockDocRef);
        when(() => mockFirestore.batch()).thenReturn(MockBatch());

        // Act
        await service.sendNotificationToMultiple([
          'user1',
          'user2',
        ], mockNotification);

        // Assert
        verify(() => mockFirestore.batch()).called(1);
        verify(() => mockFirestore.collection('users').doc('user1')).called(1);
        verify(() => mockFirestore.collection('users').doc('user2')).called(1);
      });

      test('handles empty user list gracefully', () async {
        // Arrange
        final mockNotification = AppNotification(
          id: '',
          type: AppNotificationType.achievement,
          title: 'Achievement',
          body: 'Test',
          createdAt: DateTime.now(),
        );

        // Act & Assert - should not throw
        expect(
          () => service.sendNotificationToMultiple([], mockNotification),
          returnsNormally,
        );
      });
    });

    group('markAsRead', () {
      test('marks notification as read and decrements count', () async {
        // Arrange
        when(
          () => mockNotificationsCollection.doc(any()),
        ).thenReturn(mockDocRef);

        // Act
        await service.markAsRead('user123', 'notif123');

        // Assert
        verify(() => mockNotificationsCollection.doc('notif123')).called(1);
        verify(
          () =>
              mockDocRef.update({'read': true, 'readAt': any(named: 'readAt')}),
        ).called(1);
        verify(
          () => mockFirestore.collection('users').doc('user123').update({
            'unreadNotificationCount': FieldValue.increment(-1),
          }),
        ).called(1);
      });
    });

    group('markAllAsRead', () {
      test('marks all unread notifications as read and resets count', () async {
        // Arrange
        final mockQuery = MockQuery();
        final mockQuerySnapshot = MockQuerySnapshot();

        when(
          () => mockFirestore
              .collection('users')
              .doc('user123')
              .collection('notifications'),
        ).thenReturn(mockNotificationsCollection);
        when(
          () => mockNotificationsCollection.where('read', isEqualTo: false),
        ).thenReturn(mockQuery);
        when(
          () => mockQuery.snapshots(),
        ).thenAnswer((_) => Stream.value(mockQuerySnapshot));
        when(() => mockQuerySnapshot.docs).thenReturn([]);

        // Act
        await service.markAllAsRead('user123');

        // Assert
        verify(
          () => mockNotificationsCollection.where('read', isEqualTo: false),
        ).called(1);
        verify(
          () => mockFirestore.collection('users').doc('user123').update({
            'unreadNotificationCount': 0,
          }),
        ).called(1);
      });

      test('returns early when no unread notifications', () async {
        // Arrange
        when(
          () => mockFirestore
              .collection('users')
              .doc('user123')
              .collection('notifications'),
        ).thenReturn(mockNotificationsCollection);

        // Act & Assert - should not throw
        expect(() => service.markAllAsRead('user123'), returnsNormally);
      });
    });

    group('deleteNotification', () {
      test(
        'deletes notification and decrements count only if unread',
        () async {
          // Arrange
          final mockSnapshot = MockDocumentSnapshot();
          when(() => mockSnapshot.exists).thenReturn(true);
          when(() => mockSnapshot.data()).thenReturn({'read': false});

          when(
            () => mockNotificationsCollection.doc(any()),
          ).thenReturn(mockDocRef);
          when(() => mockDocRef.get()).thenAnswer((_) async => mockSnapshot);

          // Act
          await service.deleteNotification('user123', 'notif123');

          // Assert
          verify(() => mockDocRef.delete()).called(1);
          verify(
            () => mockFirestore.collection('users').doc('user123').update({
              'unreadNotificationCount': FieldValue.increment(-1),
            }),
          ).called(1);
        },
      );

      test('deletes read notification without decrementing count', () async {
        // Arrange
        final mockSnapshot = MockDocumentSnapshot();
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.data()).thenReturn({'read': true});

        when(
          () => mockNotificationsCollection.doc(any()),
        ).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockSnapshot);

        // Act
        await service.deleteNotification('user123', 'notif123');

        // Assert
        verify(() => mockDocRef.delete()).called(1);
        verifyNoMoreInteractions(
          mockFirestore.collection('users').doc('user123'),
        );
      });
    });

    group('deleteAllNotifications', () {
      test('deletes all notifications and resets count', () async {
        // Arrange
        final mockQuerySnapshot = MockQuerySnapshot();
        when(
          () => mockFirestore
              .collection('users')
              .doc('user123')
              .collection('notifications'),
        ).thenReturn(mockNotificationsCollection);
        when(
          () => mockNotificationsCollection.get(),
        ).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([]);

        // Act
        await service.deleteAllNotifications('user123');

        // Assert
        verify(() => mockNotificationsCollection.get()).called(1);
        verify(
          () => mockFirestore.collection('users').doc('user123').update({
            'unreadNotificationCount': 0,
          }),
        ).called(1);
      });

      test('handles errors gracefully without throwing', () async {
        // Arrange
        when(
          () => mockFirestore
              .collection('users')
              .doc('user123')
              .collection('notifications'),
        ).thenReturn(mockNotificationsCollection);
        when(
          () => mockNotificationsCollection.get(),
        ).thenThrow(Exception('Network error'));

        // Act & Assert - should not throw despite error
        expect(
          () => service.deleteAllNotifications('user123'),
          returnsNormally,
        );
      });
    });

    group('Notification helpers', () {
      test('createNotification creates correct structure', () {
        // Act
        final notification = service.createNotification(
          type: AppNotificationType.friendRequest,
          title: 'Friend Request',
          body: 'Test user wants to be your friend',
        );

        // Assert
        expect(notification.type, AppNotificationType.friendRequest);
        expect(notification.title, 'Friend Request');
        expect(notification.body, 'Test user wants to be your friend');
        expect(notification.id, '');
        expect(notification.createdAt, isNotNull);
      });

      test('createFriendRequestNotification has correct expiration', () {
        // Act
        final notification = service.createFriendRequestNotification(
          senderName: 'Alice',
          senderId: 'user1',
        );

        // Assert
        expect(notification.type, AppNotificationType.friendRequest);
        expect(notification.title, 'New Friend Request');
        expect(notification.data['senderId'], 'user1');
        expect(notification.data['senderName'], 'Alice');
        expect(notification.data['route'], '/social/friends');
        expect(notification.expiresAt, isNotNull);
        expect(
          notification.expiresAt!.difference(notification.createdAt).inDays,
          30,
        );
      });

      test('createChallengeInviteNotification has 7-day expiration', () {
        // Act
        final notification = service.createChallengeInviteNotification(
          challengeTitle: 'Daily Challenge',
          challengeId: 'challenge1',
          inviterName: 'Bob',
        );

        // Assert
        expect(notification.type, AppNotificationType.challengeInvite);
        expect(notification.expiresAt, isNotNull);
        expect(
          notification.expiresAt!.difference(notification.createdAt).inDays,
          7,
        );
      });

      test('createLevelUpNotification has correct data', () {
        // Act
        final notification = service.createLevelUpNotification(newLevel: 15);

        // Assert
        expect(notification.type, AppNotificationType.levelUp);
        expect(notification.title, 'Level Up!');
        expect(notification.data['newLevel'], 15);
        expect(notification.data['route'], '/profile');
      });
    });
  });
}
