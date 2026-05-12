import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/core/domain/entities/app_notification.dart';
import 'package:emerge_app/core/services/social_notification_service.dart';

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

// ignore: subtype_of_sealed_class
class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockBatch extends Mock implements WriteBatch {}

// ignore: subtype_of_sealed_class
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

void main() {
  late MockFirestore mockFirestore;
  late MockCollectionReference mockUsersCollection;
  late MockCollectionReference mockNotificationsCollection;
  late MockDocumentReference mockUserDocRef;
  late MockDocumentReference mockNotificationDocRef;
  late SocialNotificationService service;

  setUpAll(() {
    registerFallbackValue(MockBatch());
    registerFallbackValue(MockDocumentReference());
    registerFallbackValue(MockQuery());
    registerFallbackValue(MockQuerySnapshot());
    registerFallbackValue(AppNotification(
      id: '',
      type: AppNotificationType.friendRequest,
      title: '',
      body: '',
      createdAt: DateTime(2025),
    ));
    registerFallbackValue('');
  });

  setUp(() {
    mockFirestore = MockFirestore();
    mockUsersCollection = MockCollectionReference();
    mockNotificationsCollection = MockCollectionReference();
    mockUserDocRef = MockDocumentReference();
    mockNotificationDocRef = MockDocumentReference();
    service = SocialNotificationService(mockFirestore);

    // Setup basic chain
    when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
    when(() => mockFirestore.collection(any())).thenReturn(mockUsersCollection);
    
    when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDocRef);
    
    when(() => mockUserDocRef.collection('notifications')).thenReturn(mockNotificationsCollection);
    when(() => mockUserDocRef.collection(any())).thenReturn(mockNotificationsCollection);
    
    when(() => mockNotificationsCollection.doc(any())).thenReturn(mockNotificationDocRef);
    when(() => mockNotificationsCollection.add(any())).thenAnswer((_) async => mockNotificationDocRef);
    
    // Mutation methods
    when(() => mockUserDocRef.set(any(), any())).thenAnswer((_) async {});
    when(() => mockUserDocRef.update(any())).thenAnswer((_) async {});
    
    when(() => mockNotificationDocRef.set(any(), any())).thenAnswer((_) async {});
    when(() => mockNotificationDocRef.update(any())).thenAnswer((_) async {});
    when(() => mockNotificationDocRef.delete()).thenAnswer((_) async {});
    
    // Query methods
    final mockQuery = MockQuery();
    final mockQuerySnapshot = MockQuerySnapshot();
    when(() => mockNotificationsCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
    when(() => mockNotificationsCollection.where(any(), isEqualTo: any(named: 'isEqualTo'))).thenReturn(mockQuery);
    when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
    when(() => mockQuerySnapshot.docs).thenReturn([]);

    // Batch
    final mockBatch = MockBatch();
    when(() => mockFirestore.batch()).thenReturn(mockBatch);
    when(() => mockBatch.commit()).thenAnswer((_) async {});
    when(() => mockBatch.set(any(), any())).thenAnswer((_) {});
    when(() => mockBatch.update(any(), any())).thenAnswer((_) {});
    when(() => mockBatch.delete(any())).thenAnswer((_) {});
  });

  group('SocialNotificationService Basic Tests', () {
    test('sendNotification works', () async {
      final notification = AppNotification(
        id: '1',
        type: AppNotificationType.friendRequest,
        title: 'Hi',
        body: 'Test',
        createdAt: DateTime.now(),
      );
      
      await service.sendNotification('user1', notification);
      
      verify(() => mockNotificationsCollection.add(any())).called(1);
      verify(() => mockUserDocRef.set(any(), any())).called(1);
    });

    test('markAsRead works', () async {
      await service.markAsRead('user1', 'notif1');
      verify(() => mockNotificationDocRef.update(any())).called(1);
      verify(() => mockUserDocRef.update(any())).called(1);
    });
  });
}
