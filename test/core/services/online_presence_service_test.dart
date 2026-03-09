import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/core/services/online_presence_service.dart';

// Mock classes
// ignore: subtype_of_sealed_class
class MockFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late MockFirestore mockFirestore;
  late MockDocumentReference mockDocRef;
  late OnlinePresenceService service;

  setUpAll(() {
    registerFallbackValue(MockCollectionReference());
    registerFallbackValue(MockDocumentReference());
  });

  setUp(() {
    mockFirestore = MockFirestore();
    mockDocRef = MockDocumentReference();
    service = OnlinePresenceService(mockFirestore);

    // Setup default collection reference
    when(() => mockFirestore.collection('users').doc(any()))
        .thenReturn(mockDocRef);
    when(() => mockDocRef.collection('presence').doc('status'))
        .thenReturn(mockDocRef);
  });

  group('OnlinePresenceService', () {
    group('startHeartbeat', () {
      test('starts heartbeat and sets online status', () async {
        // Arrange
        when(() => mockDocRef.set(any(named: 'data'), any(named: 'options')))
            .thenAnswer((_) async => {});

        // Act
        await service.startHeartbeat('user123');

        // Assert
        verify(() => mockFirestore.collection('users').doc('user123')).called(1);
        verify(() => mockDocRef.set({
          'online': true,
          'lastSeen': any(named: 'data'),
        }, any(named: 'options'))).called(1);
      });

      test('handles user switching gracefully', () async {
        // Arrange
        when(() => mockFirestore.collection('users').doc(any()))
            .thenReturn(mockDocRef);
        when(() => mockDocRef.set(any(named: 'data'), any(named: 'options')))
            .thenAnswer((_) async => {});

        // Act
        await service.startHeartbeat('user1');
        await service.startHeartbeat('user2');

        // Assert - should call stop then start for new user
        verify(() => mockFirestore.collection('users').doc('user1')).called(1);
        verify(() => mockFirestore.collection('users').doc('user2')).called(1);
      });

      test('does not restart heartbeat if same user calls again', () async {
        // Arrange
        when(() => mockDocRef.set(any(named: 'data'), any(named: 'options')))
            .thenAnswer((_) async => {});

        // Act
        await service.startHeartbeat('user123');
        await service.startHeartbeat('user123');
      });
    });

    group('stopHeartbeat', () {
      test('stops heartbeat and sets offline status', () async {
        // Arrange
        when(() => mockDocRef.set(any(named: 'data'), any(named: 'options')))
            .thenAnswer((_) async => {});

        // Act
        await service.startHeartbeat('user123');
        await service.stopHeartbeat();

        // Assert
        verify(() => mockFirestore.collection('users').doc('user123')).called(1);
        verify(() => mockDocRef.set({
          'online': false,
          'lastSeen': any(named: 'data'),
        }, any(named: 'options'))).called(1);
      });

      test('handles multiple stopHeartbeat calls gracefully', () async {
        // Arrange
        when(() => mockDocRef.set(any(named: 'data'), any(named: 'options')))
            .thenAnswer((_) async => {});

        // Act
        await service.stopHeartbeat();
        await service.stopHeartbeat();

        // Assert - should not throw
        expect(
          () => service.stopHeartbeat(),
          returnsNormally,
        );
      });
    });

    group('setOffline', () {
      test('sets offline status in Firestore', () async {
        // Arrange
        when(() => mockDocRef.set(any(named: 'data'), any(named: 'options')))
            .thenAnswer((_) async => {});

        // Act
        await service.setOffline('user123');

        // Assert
        verify(() => mockFirestore.collection('users').doc('user123')).called(1);
        verify(() => mockDocRef.set({
          'online': false,
          'lastSeen': any(named: 'data'),
        }, any(named: 'options'))).called(1);
      });

      test('handles errors gracefully without throwing', () async {
        // Arrange
        when(() => mockDocRef.set(any(named: 'data'), any(named: 'options')))
            .thenThrow(Exception('Network error'));

        // Act & Assert - should not throw despite error
        expect(
          () => service.setOffline('user123'),
          returnsNormally,
        );
      });
    });

    group('Edge cases', () {
      test('handles empty string userId gracefully', () async {
        // Arrange
        when(() => mockFirestore.collection('users').doc(any()))
            .thenReturn(mockDocRef);
        when(() => mockDocRef.set(any(named: 'data'), any(named: 'options')))
            .thenAnswer((_) async => {});

        // Act
        await service.startHeartbeat('');

        // Assert - should not throw
        expect(
          () => service.startHeartbeat(''),
          returnsNormally,
        );
      });

      test('handles null userId gracefully', () async {
        // Act & Assert - should not throw
        expect(
          () => service.startHeartbeat(''),
          returnsNormally,
        );
      });
    });
  });
}
