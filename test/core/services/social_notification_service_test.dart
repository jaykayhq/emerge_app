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

// ignore: subtype_of_sealed_class
class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirestore mockFirestore;
  late MockCollectionReference mockUsersCollection;
  late MockCollectionReference mockNotificationsCollection;
  late MockDocumentReference mockUserDoc;
  late MockDocumentReference mockNotificationDoc;
  late MockBatch mockBatch;
  late SocialNotificationService service;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(MockBatch());
    registerFallbackValue(MockDocumentReference());
    registerFallbackValue(MockQuery());
    registerFallbackValue(MockCollectionReference());
    registerFallbackValue(
      AppNotification(
        id: '',
        type: AppNotificationType.friendRequest,
        title: '',
        body: '',
        createdAt: DateTime(2025),
      ),
    );
    registerFallbackValue(const {'unreadNotificationCount': 0});
    registerFallbackValue(SetOptions(merge: true));
  });

  setUp(() {
    mockFirestore = MockFirestore();
    mockUsersCollection = MockCollectionReference();
    mockNotificationsCollection = MockCollectionReference();
    mockUserDoc = MockDocumentReference();
    mockNotificationDoc = MockDocumentReference();
    mockBatch = MockBatch();
    service = SocialNotificationService(mockFirestore);

    clearInteractions(mockFirestore);
    clearInteractions(mockBatch);

    // Root: firestore.collection('users') -> mockUsersCollection
    when(
      () => mockFirestore.collection('users'),
    ).thenReturn(mockUsersCollection);
    when(() => mockFirestore.collection(any())).thenReturn(mockUsersCollection);

    // User Level: users.doc(id) -> mockUserDoc
    when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDoc);

    // Notification Level: userDoc.collection('notifications') -> mockNotificationsCollection
    when(
      () => mockUserDoc.collection('notifications'),
    ).thenReturn(mockNotificationsCollection);
    when(
      () => mockUserDoc.collection(any()),
    ).thenReturn(mockNotificationsCollection);

    // Notification Doc Level: notifications.doc(id) -> mockNotificationDoc
    when(
      () => mockNotificationsCollection.doc(any()),
    ).thenReturn(mockNotificationDoc);
    when(
      () => mockNotificationsCollection.add(any()),
    ).thenAnswer((_) async => mockNotificationDoc);

    // Mutation stubs for User Doc
    when(() => mockUserDoc.set(any(), any())).thenAnswer((_) async {});
    when(() => mockUserDoc.update(any())).thenAnswer((_) async {});

    // Mutation stubs for Notification Doc
    when(() => mockNotificationDoc.set(any(), any())).thenAnswer((_) async {});
    when(() => mockNotificationDoc.update(any())).thenAnswer((_) async {});
    when(() => mockNotificationDoc.delete()).thenAnswer((_) async {});
    when(
      () => mockNotificationDoc.get(),
    ).thenAnswer((_) async => MockDocumentSnapshot());

    // Batch setup
    mockBatch = MockBatch();
    when(() => mockFirestore.batch()).thenReturn(mockBatch);
    when(() => mockBatch.commit()).thenAnswer((_) async {});
    when(() => mockBatch.set(any(), any())).thenAnswer((_) {});
    when(() => mockBatch.update(any(), any())).thenAnswer((_) {});
    when(() => mockBatch.delete(any())).thenAnswer((_) {});

    // Query stubs
    final mockQuery = MockQuery();
    final mockQuerySnapshot = MockQuerySnapshot();
    when(
      () => mockNotificationsCollection.get(),
    ).thenAnswer((_) async => mockQuerySnapshot);
    when(
      () => mockNotificationsCollection.where(
        any(),
        isEqualTo: any(named: 'isEqualTo'),
      ),
    ).thenReturn(mockQuery);
    when(
      () => mockNotificationsCollection.where(
        any(),
        isLessThan: any(named: 'isLessThan'),
      ),
    ).thenReturn(mockQuery);
    when(
      () => mockNotificationsCollection.orderBy(
        any(),
        descending: any(named: 'descending'),
      ),
    ).thenReturn(mockQuery);

    when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
    when(
      () => mockQuery.where(any(), isEqualTo: any(named: 'isEqualTo')),
    ).thenReturn(mockQuery);
    when(
      () => mockQuery.orderBy(any(), descending: any(named: 'descending')),
    ).thenReturn(mockQuery);
    when(() => mockQuery.limit(any())).thenReturn(mockQuery);
    when(
      () => mockQuery.snapshots(),
    ).thenAnswer((_) => Stream.value(mockQuerySnapshot));
    when(() => mockQuerySnapshot.docs).thenReturn([]);
  });

  group('SocialNotificationService', () {
    group('sendNotification', () {
      test('sends notification and increments unread count', () async {
        // Arrange
        final notification = AppNotification(
          id: '123',
          type: AppNotificationType.challengeInvite,
          title: 'Title',
          body: 'Body',
          createdAt: DateTime.now(),
        );

        // Act
        await service.sendNotification('user123', notification);

        // Assert
        verify(() => mockNotificationsCollection.add(any())).called(1);
        verify(() => mockUserDoc.set(any(), any())).called(1);
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

        when(() => mockBatch.commit()).thenAnswer((_) async {});

        // Act
        await service.sendNotificationToMultiple([
          'user1',
          'user2',
        ], mockNotification);

        // Assert
        verify(() => mockFirestore.batch()).called(1);
        verify(() => mockBatch.commit()).called(1);
      });

      test('handles empty user list gracefully', () async {
        await service.sendNotificationToMultiple(
          [],
          AppNotification(
            id: '',
            type: AppNotificationType.challengeInvite,
            title: '',
            body: '',
            createdAt: DateTime.now(),
          ),
        );
      });
    });

    group('markAsRead', () {
      test('marks notification as read and decrements count', () async {
        // Act
        await service.markAsRead('user123', 'notif123');

        // Assert
        verify(() => mockNotificationsCollection.doc('notif123')).called(1);
        verify(() => mockNotificationDoc.update(any())).called(1);
        verify(() => mockUserDoc.update(any())).called(1);
      });
    });

    group('markAllAsRead', () {
      test('marks all unread notifications as read and resets count', () async {
        // Arrange
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDocSnapshot = MockQueryDocumentSnapshot();
        final mockQuery = MockQuery();

        when(
          () => mockNotificationsCollection.where(
            any(),
            isEqualTo: any(named: 'isEqualTo'),
          ),
        ).thenReturn(mockQuery);
        when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
        when(() => mockDocSnapshot.reference).thenReturn(mockNotificationDoc);
        when(() => mockBatch.commit()).thenAnswer((_) async {});

        // Act
        await service.markAllAsRead('user123');

        // Assert
        verify(
          () => mockNotificationsCollection.where('read', isEqualTo: false),
        ).called(1);
        verify(() => mockBatch.update(any(), any())).called(1);
        verify(
          () => mockUserDoc.update({'unreadNotificationCount': 0}),
        ).called(1);
        verify(() => mockBatch.commit()).called(1);
      });

      test('returns early when no unread notifications', () async {
        // Arrange
        final mockQuery = MockQuery();
        final mockQuerySnapshot = MockQuerySnapshot();
        when(
          () => mockNotificationsCollection.where('read', isEqualTo: false),
        ).thenReturn(mockQuery);
        when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([]);

        // Act & Assert - should not throw
        await service.markAllAsRead('user123');
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
          ).thenReturn(mockNotificationDoc);
          when(
            () => mockNotificationDoc.get(),
          ).thenAnswer((_) async => mockSnapshot);

          // Act
          await service.deleteNotification('user123', 'notif123');

          // Assert
          verify(() => mockNotificationDoc.delete()).called(1);
          verify(() => mockUserDoc.update(any())).called(1);
        },
      );

      test('deletes read notification without decrementing count', () async {
        // Arrange
        final mockSnapshot = MockDocumentSnapshot();
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.data()).thenReturn({'read': true});

        when(
          () => mockNotificationsCollection.doc(any()),
        ).thenReturn(mockNotificationDoc);
        when(
          () => mockNotificationDoc.get(),
        ).thenAnswer((_) async => mockSnapshot);

        // Act
        await service.deleteNotification('user123', 'notif123');

        // Assert
        verify(() => mockNotificationDoc.delete()).called(1);
        verifyNever(() => mockUserDoc.update(any()));
      });
    });

    group('deleteAllNotifications', () {
      test('deletes all notifications and resets count', () async {
        // Arrange
        final mockQuerySnapshot = MockQuerySnapshot();
        when(
          () => mockNotificationsCollection.get(),
        ).thenAnswer((_) async => mockQuerySnapshot);

        final mockDocSnapshot = MockQueryDocumentSnapshot();
        when(() => mockDocSnapshot.reference).thenReturn(mockNotificationDoc);
        when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);

        // Act
        await service.deleteAllNotifications('user123');

        // Assert
        verify(() => mockNotificationsCollection.get()).called(1);
        verify(() => mockBatch.delete(any())).called(1);
        verify(
          () => mockUserDoc.update({'unreadNotificationCount': 0}),
        ).called(1);
        verify(() => mockBatch.commit()).called(1);
      });

      test('handles errors gracefully without throwing', () async {
        // Arrange
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

    group('deleteExpiredNotifications', () {
      test('deletes expired notifications using batch', () async {
        // Arrange
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDocSnapshot = MockQueryDocumentSnapshot();
        final mockQuery = MockQuery();

        when(
          () => mockNotificationsCollection.where(
            any(),
            isLessThan: any(named: 'isLessThan'),
          ),
        ).thenReturn(mockQuery);
        when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
        when(() => mockDocSnapshot.reference).thenReturn(mockNotificationDoc);
        when(() => mockBatch.commit()).thenAnswer((_) async {});

        // Act
        await service.deleteExpiredNotifications('user1');

        // Assert
        verify(() => mockBatch.delete(any())).called(1);
        verify(() => mockBatch.commit()).called(1);
      });
    });
  });
}
