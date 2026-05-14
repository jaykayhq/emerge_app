import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/firestore_repositories/firestore_habit_repository.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockWriteBatch extends Mock implements WriteBatch {}

class FakeDocumentReference extends Fake
    implements DocumentReference<Object?> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late FirestoreHabitRepository repository;
  late Habit testHabit;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(SetOptions(merge: true));
    registerFallbackValue(FakeDocumentReference());
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    repository = FirestoreHabitRepository(firestore: mockFirestore);
    testHabit = Habit(
      id: const Uuid().v4(),
      userId: 'user123',
      title: 'Test Habit',
      cue: 'Morning alarm',
      routine: 'Do 10 pushups',
      reward: 'Coffee',
      frequency: HabitFrequency.daily,
      difficulty: HabitDifficulty.medium,
      createdAt: DateTime(2025, 6, 1),
      impact: HabitImpact.positive,
      attribute: HabitAttribute.vitality,
    );
  });

  group('createHabit', () {
    test('should set document with habit data', () async {
      final mockCollection = MockCollectionReference();
      final mockDocument = MockDocumentReference();

      when(() => mockFirestore.collection('habits')).thenReturn(mockCollection);
      when(() => mockCollection.doc(testHabit.id)).thenReturn(mockDocument);
      when(() => mockDocument.set(any())).thenAnswer((_) async {});

      final result = await repository.createHabit(testHabit);

      expect(result.isRight(), true);
      verify(() => mockFirestore.collection('habits')).called(1);
      verify(() => mockCollection.doc(testHabit.id)).called(1);
      verify(() => mockDocument.set(any())).called(1);
    });

    test('should return ServerFailure on exception', () async {
      final mockCollection = MockCollectionReference();
      final mockDocument = MockDocumentReference();

      when(() => mockFirestore.collection('habits')).thenReturn(mockCollection);
      when(() => mockCollection.doc(testHabit.id)).thenReturn(mockDocument);
      when(() => mockDocument.set(any())).thenThrow(Exception('Network error'));

      final result = await repository.createHabit(testHabit);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected failure'),
      );
    });
  });

  group('updateHabit', () {
    test('should set document with merge option', () async {
      final mockCollection = MockCollectionReference();
      final mockDocument = MockDocumentReference();

      when(() => mockFirestore.collection('habits')).thenReturn(mockCollection);
      when(() => mockCollection.doc(testHabit.id)).thenReturn(mockDocument);
      when(() => mockDocument.set(any(), any())).thenAnswer((_) async {});

      final result = await repository.updateHabit(testHabit);

      expect(result.isRight(), true);
      verify(() => mockCollection.doc(testHabit.id)).called(1);
      verify(() => mockDocument.set(any(), any())).called(1);
    });

    test('should return ServerFailure on exception', () async {
      final mockCollection = MockCollectionReference();
      final mockDocument = MockDocumentReference();

      when(() => mockFirestore.collection('habits')).thenReturn(mockCollection);
      when(() => mockCollection.doc(testHabit.id)).thenReturn(mockDocument);
      when(() => mockDocument.set(any(), any()))
          .thenThrow(Exception('Update failed'));

      final result = await repository.updateHabit(testHabit);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected failure'),
      );
    });
  });

  group('deleteHabit', () {
    test('should update isArchived to true', () async {
      final mockCollection = MockCollectionReference();
      final mockDocument = MockDocumentReference();

      when(() => mockFirestore.collection('habits')).thenReturn(mockCollection);
      when(() => mockCollection.doc(testHabit.id)).thenReturn(mockDocument);
      when(() => mockDocument.update(captureAny())).thenAnswer((_) async {});

      final result = await repository.deleteHabit(testHabit.id);

      expect(result.isRight(), true);
      verify(() => mockCollection.doc(testHabit.id)).called(1);
      verify(() => mockDocument.update(any())).called(1);
    });

    test('should return ServerFailure on exception', () async {
      final mockCollection = MockCollectionReference();
      final mockDocument = MockDocumentReference();

      when(() => mockFirestore.collection('habits')).thenReturn(mockCollection);
      when(() => mockCollection.doc(testHabit.id)).thenReturn(mockDocument);
      when(() => mockDocument.update(any()))
          .thenThrow(Exception('Delete failed'));

      final result = await repository.deleteHabit(testHabit.id);

      expect(result.isLeft(), true);
    });
  });

  group('completeHabit', () {
    test('should add document to habit_completions collection', () async {
      final mockCollection = MockCollectionReference();
      final mockCompletionDoc = MockDocumentReference();

      when(() => mockFirestore.collection('habit_completions'))
          .thenReturn(mockCollection);
      when(() => mockCollection.add(any()))
          .thenAnswer((_) async => mockCompletionDoc);

      final date = DateTime(2025, 6, 15);
      final result = await repository.completeHabit(testHabit.id, date);

      expect(result.isRight(), true);
      result.fold(
        (_) {},
        (completed) => expect(completed, true),
      );
      verify(() => mockFirestore.collection('habit_completions')).called(1);
      verify(() => mockCollection.add(any())).called(1);
    });

    test('should return ServerFailure on exception', () async {
      final mockCollection = MockCollectionReference();

      when(() => mockFirestore.collection('habit_completions'))
          .thenReturn(mockCollection);
      when(() => mockCollection.add(any()))
          .thenThrow(Exception('Completion failed'));

      final result =
          await repository.completeHabit(testHabit.id, DateTime.now());

      expect(result.isLeft(), true);
    });
  });

  group('getHabit', () {
    test('should return Habit from document', () async {
      final mockCollection = MockCollectionReference();
      final mockDocument = MockDocumentReference();
      final mockDocSnapshot = MockDocumentSnapshot();

      when(() => mockFirestore.collection('habits')).thenReturn(mockCollection);
      when(() => mockCollection.doc(testHabit.id)).thenReturn(mockDocument);
      when(() => mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockDocSnapshot.data()).thenReturn(testHabit.toMap());
      when(() => mockDocSnapshot.exists).thenReturn(true);

      final result = await repository.getHabit(testHabit.id);

      expect(result, isNotNull);
      expect(result?.id, testHabit.id);
      expect(result?.title, testHabit.title);
    });

    test('should return null when document does not exist', () async {
      final mockCollection = MockCollectionReference();
      final mockDocument = MockDocumentReference();
      final mockDocSnapshot = MockDocumentSnapshot();

      when(() => mockFirestore.collection('habits')).thenReturn(mockCollection);
      when(() => mockCollection.doc(testHabit.id)).thenReturn(mockDocument);
      when(() => mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockDocSnapshot.exists).thenReturn(false);

      final result = await repository.getHabit(testHabit.id);

      expect(result, isNull);
    });
  });

  group('getHabitsByAnchor', () {
    test('should return habits filtered by anchorHabitId', () async {
      final mockCollection = MockCollectionReference();
      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockQueryDocumentSnapshot();

      when(() => mockFirestore.collection('habits')).thenReturn(mockCollection);
      when(
        () => mockCollection.where(
          'anchorHabitId',
          isEqualTo: 'anchor123',
        ),
      ).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockDocSnapshot.data()).thenReturn(testHabit.toMap());

      final result = await repository.getHabitsByAnchor('anchor123');

      expect(result.length, 1);
      expect(result.first.id, testHabit.id);
    });
  });

  group('watchHabits', () {
    test('should stream non-archived habits for user', () async {
      final mockCollection = MockCollectionReference();
      final mockQuery1 = MockQuery();
      final mockQuery2 = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockQueryDocumentSnapshot();
      final streamController =
          StreamController<QuerySnapshot<Map<String, dynamic>>>();

      when(() => mockFirestore.collection('habits')).thenReturn(mockCollection);
      when(
        () => mockCollection.where('userId', isEqualTo: testHabit.userId),
      ).thenReturn(mockQuery1);
      when(
        () => mockQuery1.where('isArchived', isEqualTo: false),
      ).thenReturn(mockQuery2);
      when(() => mockQuery2.snapshots())
          .thenAnswer((_) => streamController.stream);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockDocSnapshot.data()).thenReturn(testHabit.toMap());

      final stream = repository.watchHabits(testHabit.userId);
      streamController.add(mockQuerySnapshot);

      await expectLater(
        stream,
        emits(contains(testHabit)),
      );

      await streamController.close();
    });
  });

  group('getActivity', () {
    test('should return habit activities within date range', () async {
      final mockQuery = MockQuery();
      final mockQuery1 = MockQuery();
      final mockQuery2 = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockQueryDocumentSnapshot();
      final start = DateTime(2025, 6, 1);
      final end = DateTime(2025, 6, 30);
      final testData = {
        'habitId': testHabit.id,
        'userId': testHabit.userId,
        'date': Timestamp.fromDate(DateTime(2025, 6, 15)),
        'type': 'habit_completion',
      };

      when(
        () => mockFirestore.collectionGroup('habit_completions'),
      ).thenReturn(mockQuery);
      when(
        () => mockQuery.where('userId', isEqualTo: testHabit.userId),
      ).thenReturn(mockQuery1);
      when(
        () => mockQuery1.where('date', isGreaterThanOrEqualTo: start),
      ).thenReturn(mockQuery2);
      when(
        () => mockQuery2.where('date', isLessThanOrEqualTo: end),
      ).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockDocSnapshot.data()).thenReturn(testData);
      when(() => mockDocSnapshot.id).thenReturn('completion1');

      final result = await repository.getActivity(
        testHabit.userId,
        start,
        end,
      );

      expect(result.length, 1);
      expect(result.first.habitId, testHabit.id);
      expect(result.first.type, 'habit_completion');
    });
  });

  group('createHabitsFromBlueprint', () {
    test('should create habits using batch writes', () async {
      final mockWriteBatch = MockWriteBatch();
      final mockCollection = MockCollectionReference();
      final mockDocument = MockDocumentReference();
      final blueprint = Blueprint(
        id: 'bp1',
        creatorUserId: 'creator1',
        creatorName: 'Test Creator',
        creatorArchetype: 'Scholar',
        title: 'Test Blueprint',
        description: 'A test blueprint',
        habits: [
          BlueprintHabit(title: 'Morning Meditation'),
          BlueprintHabit(title: 'Evening Reading'),
        ],
        createdAt: DateTime.now(),
        category: 'Health',
      );

      when(() => mockFirestore.collection('habits')).thenReturn(mockCollection);
      when(() => mockFirestore.batch()).thenReturn(mockWriteBatch);
      when(() => mockCollection.doc(any())).thenReturn(mockDocument);
      when(() => mockWriteBatch.set(any(), any(), any())).thenReturn(mockWriteBatch);
      when(() => mockWriteBatch.commit()).thenAnswer((_) async {});

      final result = await repository.createHabitsFromBlueprint(
        userId: 'user123',
        blueprint: blueprint,
      );

      expect(result.isRight(), true);
      verify(() => mockFirestore.batch()).called(1);
      // Verify commit was called, confirming batch was used
      verify(() => mockWriteBatch.commit()).called(1);
    });

    test('should return ServerFailure on exception', () async {
      final blueprint = Blueprint(
        id: 'bp1',
        creatorUserId: 'creator1',
        creatorName: 'Test Creator',
        creatorArchetype: 'Scholar',
        title: 'Test Blueprint',
        description: 'A test blueprint',
        habits: [BlueprintHabit(title: 'Morning Meditation')],
        createdAt: DateTime.now(),
        category: 'Health',
      );

      when(() => mockFirestore.collection('habits')).thenThrow(Exception('Batch failed'));

      final result = await repository.createHabitsFromBlueprint(
        userId: 'user123',
        blueprint: blueprint,
      );

      expect(result.isLeft(), true);
    });
  });
}
