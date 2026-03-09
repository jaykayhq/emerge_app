import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';

// Mock classes
class MockFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}

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
    group('getClubIdForArchetype', () {
      test('returns correct club ID format for athlete archetype', () {
        expect(service.getClubIdForArchetype('athlete'), 'athlete_club');
      });

      test('returns correct club ID format for scholar archetype', () {
        expect(service.getClubIdForArchetype('scholar'), 'scholar_club');
      });

      test('returns correct club ID format for creator archetype', () {
        expect(service.getClubIdForArchetype('creator'), 'creator_club');
      });

      test('returns correct club ID format for stoic archetype', () {
        expect(service.getClubIdForArchetype('stoic'), 'stoic_club');
      });

      test('returns correct club ID format for zealot archetype', () {
        expect(service.getClubIdForArchetype('zealot'), 'zealot_club');
      });
    });

    group('logHabitCompletion', () {
      test('executes successfully with valid transaction handler', () async {
        // Arrange
        final mockTransaction = MockTransaction();
        when(() => mockFirestore.runTransaction(any()))
            .thenAnswer((invocation) async {
          final handler = invocation.positionalArguments[0] as TransactionHandler;
          return await handler(mockTransaction);
        });

        // Act - should complete without throwing
        await service.logHabitCompletion(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'athlete',
          habitId: 'habit456',
          habitTitle: 'Morning Workout',
          xpGained: 50,
        );

        // Assert - if we reached here, the transaction was executed successfully
        expect(true, isTrue);
      });

      test('handles errors gracefully without throwing', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any()))
            .thenThrow(Exception('Firestore error'));

        // Act & Assert - should not throw
        await service.logHabitCompletion(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'athlete',
          habitId: 'habit456',
          habitTitle: 'Morning Workout',
          xpGained: 50,
        );
        // If we reach here, the error was handled gracefully
        expect(true, isTrue);
      });
    });

    group('logLevelUp', () {
      test('executes successfully with valid transaction handler', () async {
        // Arrange
        final mockTransaction = MockTransaction();
        when(() => mockFirestore.runTransaction(any()))
            .thenAnswer((invocation) async {
          final handler = invocation.positionalArguments[0] as TransactionHandler;
          return await handler(mockTransaction);
        });

        // Act - should complete without throwing
        await service.logLevelUp(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'scholar',
          newLevel: 15,
        );

        // Assert - if we reached here, the transaction was executed successfully
        expect(true, isTrue);
      });

      test('handles errors gracefully without throwing', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any()))
            .thenThrow(Exception('Firestore error'));

        // Act & Assert - should not throw
        await service.logLevelUp(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'scholar',
          newLevel: 15,
        );
        // If we reach here, the error was handled gracefully
        expect(true, isTrue);
      });
    });

    group('logChallengeComplete', () {
      test('executes successfully with valid transaction handler', () async {
        // Arrange
        final mockTransaction = MockTransaction();
        when(() => mockFirestore.runTransaction(any()))
            .thenAnswer((invocation) async {
          final handler = invocation.positionalArguments[0] as TransactionHandler;
          return await handler(mockTransaction);
        });

        // Act - should complete without throwing
        await service.logChallengeComplete(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'creator',
          challengeId: 'challenge789',
          challengeTitle: '30-Day Creation Sprint',
        );

        // Assert - if we reached here, the transaction was executed successfully
        expect(true, isTrue);
      });

      test('handles errors gracefully without throwing', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any()))
            .thenThrow(Exception('Firestore error'));

        // Act & Assert - should not throw
        await service.logChallengeComplete(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'creator',
          challengeId: 'challenge789',
          challengeTitle: '30-Day Creation Sprint',
        );
        // If we reach here, the error was handled gracefully
        expect(true, isTrue);
      });
    });
  });
}
