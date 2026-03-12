import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';

// ignore_for_file: subtype_of_sealed_class

// Mock classes
class MockFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {
  @override
  String get id => 'mock_id';
}

class MockTransaction extends Mock implements Transaction {
  @override
  Transaction set<T>(
    DocumentReference<T> documentRef,
    T data, [
    SetOptions? options,
  ]) {
    return this;
  }

  @override
  Future<DocumentSnapshot<T>> get<T>(DocumentReference<T> docRef) async {
    return MockDocumentSnapshot<T>();
  }
}

class MockDocumentSnapshot<T> extends Mock implements DocumentSnapshot<T> {
  @override
  bool get exists => true;

  @override
  T? data() => {} as T?;
}

void main() {
  late SocialActivityService service;
  late MockFirestore mockFirestore;

  setUpAll(() {
    registerFallbackValue(MockTransaction());
    registerFallbackValue(
      const Duration(seconds: 1),
    ); // Register Duration fallback
  });

  setUp(() {
    mockFirestore = MockFirestore();
    service = SocialActivityService(firestore: mockFirestore);
  });

  group('SocialActivityService', () {
    final mockCollection = MockCollectionReference();
    final mockDoc = MockDocumentReference();

    setUp(() {
      when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
      when(() => mockCollection.doc(any())).thenReturn(mockDoc);
      when(() => mockDoc.collection(any())).thenReturn(mockCollection);

      when(
        () => mockFirestore.runTransaction<Null>(
          any(),
          timeout: any(named: 'timeout'),
          maxAttempts: any(named: 'maxAttempts'),
        ),
      ).thenAnswer((invocation) async {
        final handler =
            invocation.positionalArguments[0]
                as Future<dynamic> Function(Transaction);
        await handler(MockTransaction());
      });
    });

    group('logHabitCompletion', () {
      test('completes without throwing when transaction succeeds', () async {
        await expectLater(
          service.logHabitCompletion(
            userId: 'user123',
            userName: 'Test User',
            archetype: 'athlete',
            habitId: 'habit456',
            habitTitle: 'Morning Workout',
            streakDay: 5,
            attribute: 'vitality',
            xpGained: 50,
            currentLevel: 5,
          ),
          completes,
        );
      });
    });

    group('logLevelUp', () {
      test('logs level up correctly', () async {
        await service.logLevelUp(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'scholar',
          newLevel: 10,
          totalXp: 5000,
        );

        verify(() => mockFirestore.runTransaction<Null>(any())).called(1);
      });
    });

    group('logChallengeComplete', () {
      test('logs challenge completion correctly', () async {
        await service.logChallengeComplete(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'creator',
          challengeId: 'challenge789',
          challengeTitle: 'Design Sprint',
          xpReward: 100,
        );

        verify(() => mockFirestore.runTransaction<Null>(any())).called(1);
      });
    });
  });
}
