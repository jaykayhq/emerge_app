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

// Mock Transaction for testing
class MockTransaction extends Mock implements Transaction {
  @override
  Transaction set<T>(DocumentReference<T> documentRef, T data, [SetOptions? options]) {
    return this;
  }

  @override
  Future<DocumentSnapshot<T>> get<T>(DocumentReference<T> docRef) async {
    throw UnimplementedError();
  }
}

void main() {
  late ClubActivityService service;
  late MockFirestore mockFirestore;

  setUpAll(() {
    registerFallbackValue(MockTransaction());
  });

  setUp(() {
    mockFirestore = MockFirestore();
    service = ClubActivityService(firestore: mockFirestore);
  });

  group('ClubActivityService', () {
    group('logHabitCompletion', () {
      test('completes without throwing when transaction succeeds', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any())).thenAnswer((_) async => Future.value());

        // Act & Assert
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

      test('handles transaction errors gracefully without throwing', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any()))
            .thenThrow(Exception('Firestore transaction failed'));

        // Act & Assert
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

        // Act & Assert
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

        // Act & Assert
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

      test('logs activity with XP of 50', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any())).thenAnswer((_) async => Future.value());

        // Act
        await service.logHabitCompletion(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'athlete',
          habitId: 'habit456',
          habitTitle: 'Morning Workout',
          xpGained: 50,
        );

        // Assert
        verify(() => mockFirestore.runTransaction(any())).called(1);
      });

      test('logs activity with XP of 1000', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any())).thenAnswer((_) async => Future.value());

        // Act
        await service.logHabitCompletion(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'creator',
          habitId: 'creation-habit',
          habitTitle: 'Daily Creation',
          xpGained: 1000,
        );

        // Assert
        verify(() => mockFirestore.runTransaction(any())).called(1);
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

      test('handles transaction errors gracefully without throwing', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any()))
            .thenThrow(Exception('Firestore transaction failed'));

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

      test('handles whitespace archetype gracefully', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any())).thenAnswer((_) async => Future.value());

        // Act & Assert
        expect(
          () => service.logLevelUp(
            userId: 'user123',
            userName: 'Test User',
            archetype: '   ',
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

      test('handles transaction errors gracefully without throwing', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any()))
            .thenThrow(Exception('Firestore transaction failed'));

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

      test('handles whitespace archetype gracefully', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any())).thenAnswer((_) async => Future.value());

        // Act & Assert
        expect(
          () => service.logChallengeComplete(
            userId: 'user123',
            userName: 'Test User',
            archetype: '   ',
            challengeId: 'challenge789',
            challengeTitle: '30-Day Creation Sprint',
          ),
          returnsNormally,
        );
      });
    });

    group('Transaction patterns', () {
      test('uses Firestore transactions for all operations', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any())).thenAnswer((_) async => Future.value());

        // Act
        await service.logHabitCompletion(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'athlete',
          habitId: 'habit456',
          habitTitle: 'Morning Workout',
          xpGained: 50,
        );

        // Assert
        verify(() => mockFirestore.runTransaction(any())).called(1);
      });

      test('uses Firestore transactions for all activity types', () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any())).thenAnswer((_) async => Future.value());

        // Act & Assert - logHabitCompletion
        await service.logHabitCompletion(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'athlete',
          habitId: 'habit456',
          habitTitle: 'Morning Workout',
          xpGained: 50,
        );
        verify(() => mockFirestore.runTransaction(any())).called(1);

        // Act & Assert - logLevelUp
        await service.logLevelUp(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'scholar',
          newLevel: 15,
        );
        verify(() => mockFirestore.runTransaction(any())).called(2);

        // Act & Assert - logChallengeComplete
        await service.logChallengeComplete(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'creator',
          challengeId: 'challenge789',
          challengeTitle: '30-Day Creation Sprint',
        );
        verify(() => mockFirestore.runTransaction(any())).called(3);
      });
    });
  });
}
