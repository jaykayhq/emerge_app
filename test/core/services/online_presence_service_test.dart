import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/core/services/online_presence_service.dart';

// Mock classes
// ignore: subtype_of_sealed_class
class MockFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late MockFirestore mockFirestore;
  late MockCollectionReference mockUsersCollection;
  late MockCollectionReference mockPresenceCollection;
  late MockDocumentReference mockUserDoc;
  late MockDocumentReference mockPresenceDoc;
  late OnlinePresenceService service;

  setUpAll(() {
    registerFallbackValue(SetOptions(merge: true));
  });

  setUp(() {
    mockFirestore = MockFirestore();
    mockUsersCollection = MockCollectionReference();
    mockPresenceCollection = MockCollectionReference();
    mockUserDoc = MockDocumentReference();
    mockPresenceDoc = MockDocumentReference();
    service = OnlinePresenceService(mockFirestore);

    // Setup default collection reference chain
    when(() => mockFirestore.collection(any())).thenReturn(mockUsersCollection);
    when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDoc);
    when(() => mockUserDoc.collection(any())).thenReturn(mockPresenceCollection);
    when(() => mockPresenceCollection.doc(any())).thenReturn(mockPresenceDoc);
    
    // Default success for set
    when(() => mockPresenceDoc.set(any(), any())).thenAnswer((_) async => {});
  });

  group('OnlinePresenceService', () {
    test('startHeartbeat sets online status', () async {
      await service.startHeartbeat('user123');

      verify(() => mockPresenceDoc.set(any(), any())).called(1);
    });

    test('startHeartbeat handles user switching', () async {
      await service.startHeartbeat('user1');
      await service.startHeartbeat('user2');

      // First user start, then second user start (which calls stopHeartbeat for first)
      // stopHeartbeat doesn't call Firestore.
      // So set should be called twice (once for user1, once for user2)
      verify(() => mockPresenceDoc.set(any(), any())).called(2);
    });

    test('stopHeartbeat stops timer', () async {
      await service.startHeartbeat('user123');
      await service.stopHeartbeat();
      
      // Should not call set again after stop
      verify(() => mockPresenceDoc.set(any(), any())).called(1);
    });

    test('setOffline sets offline status', () async {
      await service.setOffline('user123');

      verify(() => mockPresenceDoc.set(
        any(that: containsPair('online', false)),
        any(),
      )).called(1);
    });

    test('handles errors gracefully', () async {
      when(() => mockPresenceDoc.set(any(), any())).thenThrow(Exception('error'));
      
      expect(() => service.setOffline('user123'), returnsNormally);
    });

    test('handles empty userId', () async {
      await service.startHeartbeat('');
      verifyNever(() => mockPresenceDoc.set(any(), any()));
    });
  });
}
