import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';

// Mock classes
// ignore: subtype_of_sealed_class
class MockFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

class MockTransaction extends Mock implements Transaction {
  @override
  Transaction set<T>(DocumentReference<T> documentRef, T data, [SetOptions? options]) {
    // Return self for chaining
    return this;
  }
}

void main() {
  late ClubActivityService service;
  late MockFirestore mockFirestore;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(MockTransaction());
  });

  setUp(() {
    mockFirestore = MockFirestore();
    service = ClubActivityService(firestore: mockFirestore);
  });

  group('ClubActivityService', () {
    group('logHabitCompletion', () {
      test('completes without throwing when transaction succeeds', () async {
        // Arrange - Stub to return success immediately
        when(() => mockFirestore.runTransaction(any())).thenAnswer((_) async => Future.value());

        // Act & Assert - should complete without throwing
        expect(
          () => service.logHabitCompletion(
            userId: 'user123',
            userName: 'Test User',
            archetype: 'athlete',
            habitId: 'habit456',
            habitTitle: 'Morning Workout',
            xpGained: 50,
          ),
          returnsNormally,
        );
      });

      test('handles errors gracefully without throwing', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any()))
            .thenThrow(Exception('Firestore error'));

        // Act & Assert - should not throw
        expect(
          () => service.logHabitCompletion(
            userId: 'user123',
            userName: 'Test User',
            archetype: 'athlete',
            habitId: 'habit456',
            habitTitle: 'Morning Workout',
            xpGained: 50,
          ),
          returnsNormally,
        );
      });

      test('handles empty archetype gracefully', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any())).thenAnswer((_) async => Future.value());

        // Act & Assert - should not throw
        expect(
          () => service.logHabitCompletion(
            userId: 'user123',
            userName: 'Test User',
            archetype: '',
            habitId: 'habit456',
            habitTitle: 'Morning Workout',
            xpGained: 50,
          ),
          returnsNormally,
        );
      });

      test('handles whitespace archetype gracefully', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any())).thenAnswer((_) async => Future.value());

        // Act & Assert - should not throw
        expect(
          () => service.logHabitCompletion(
            userId: 'user123',
            userName: 'Test User',
            archetype: '   ',
            habitId: 'habit456',
            habitTitle: 'Morning Workout',
            xpGained: 50,
          ),
          returnsNormally,
        );
      });
    });

    group('logLevelUp', () {
      test('completes without throwing when transaction succeeds', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any())).thenAnswer((_) async => Future.value());

        // Act & Assert
        expect(
          () => service.logLevelUp(
            userId: 'user123',
            userName: 'Test User',
            archetype: 'scholar',
            newLevel: 15,
          ),
          returnsNormally,
        );
      });

      test('handles errors gracefully without throwing', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any()))
            .thenThrow(Exception('Firestore error'));

        // Act & Assert
        expect(
          () => service.logLevelUp(
            userId: 'user123',
            userName: 'Test User',
            archetype: 'scholar',
            newLevel: 15,
          ),
          returnsNormally,
        );
      });

      test('handles empty archetype gracefully', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any())).thenAnswer((_) async => Future.value());

        // Act & Assert
        expect(
          () => service.logLevelUp(
            userId: 'user123',
            userName: 'Test User',
            archetype: '',
            newLevel: 15,
          ),
          returnsNormally,
        );
      });
    });

    group('logChallengeComplete', () {
      test('completes without throwing when transaction succeeds', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any())).thenAnswer((_) async => Future.value());

        // Act & Assert
        expect(
          () => service.logChallengeComplete(
            userId: 'user123',
            userName: 'Test User',
            archetype: 'creator',
            challengeId: 'challenge789',
            challengeTitle: '30-Day Creation Sprint',
          ),
          returnsNormally,
        );
      });

      test('handles errors gracefully without throwing', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any()))
            .thenThrow(Exception('Firestore error'));

        // Act & Assert
        expect(
          () => service.logChallengeComplete(
            userId: 'user123',
            userName: 'Test User',
            archetype: 'creator',
            challengeId: 'challenge789',
            challengeTitle: '30-Day Creation Sprint',
          ),
          returnsNormally,
        );
      });

      test('handles empty archetype gracefully', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any())).thenAnswer((_) async => Future.value());

        // Act & Assert
        expect(
          () => service.logChallengeComplete(
            userId: 'user123',
            userName: 'Test User',
            archetype: '',
            challengeId: 'challenge789',
            challengeTitle: '30-Day Creation Sprint',
          ),
          returnsNormally,
        );
      });
    });
  });
}
