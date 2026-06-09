// ignore_for_file: subtype_of_sealed_class

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/core/drift/database.dart';

import '../drift/test_database.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockMutationQueueDao extends Mock implements MutationQueueDao {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  group('MutationQueueDao', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> enqueue({
      required String collectionPath,
      required String documentId,
      required String operation,
      String? dataJson,
    }) {
      return db
          .into(db.mutationQueueTable)
          .insert(
            MutationQueueTableCompanion.insert(
              collectionPath: collectionPath,
              documentId: documentId,
              operation: operation,
              dataJson: dataJson != null
                  ? Value(dataJson)
                  : const Value.absent(),
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
    }

    Future<List<dynamic>> getAllPending() {
      return (db.select(db.mutationQueueTable)..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
          .get();
    }

    Future<void> deleteProcessed(int id) async {
      await (db.delete(
        db.mutationQueueTable,
      )..where((t) => t.id.equals(id))).go();
    }

    Future<void> incrementRetry(int id) async {
      await db.customStatement(
        'UPDATE mutation_queue_table SET retry_count = retry_count + 1 WHERE id = ?',
        [id],
      );
    }

    test('enqueue() inserts mutation with correct data', () async {
      await enqueue(
        collectionPath: 'users/test/habits',
        documentId: 'habit_123',
        operation: 'set',
        dataJson: '{"name":"Exercise"}',
      );

      final pending = await getAllPending();
      expect(pending, hasLength(1));
      expect(pending.first.collectionPath, 'users/test/habits');
      expect(pending.first.documentId, 'habit_123');
      expect(pending.first.operation, 'set');
      expect(pending.first.dataJson, '{"name":"Exercise"}');
      expect(pending.first.retryCount, 0);
      expect(pending.first.createdAt, isA<String>());
    });

    test('enqueue() defaults retryCount to 0', () async {
      await enqueue(
        collectionPath: 'test',
        documentId: 'doc1',
        operation: 'update',
      );

      final pending = await getAllPending();
      expect(pending.first.retryCount, 0);
    });

    test('enqueue() with null dataJson stores null', () async {
      await enqueue(
        collectionPath: 'test',
        documentId: 'doc1',
        operation: 'delete',
      );

      final pending = await getAllPending();
      expect(pending.first.dataJson, equals(null));
    });

    test(
      'getAllPending() returns mutations ordered by createdAt ascending',
      () async {
        await enqueue(
          collectionPath: 'test',
          documentId: 'first',
          operation: 'set',
          dataJson: '{"order":1}',
        );

        await Future.delayed(const Duration(milliseconds: 10));

        await enqueue(
          collectionPath: 'test',
          documentId: 'second',
          operation: 'set',
          dataJson: '{"order":2}',
        );

        await Future.delayed(const Duration(milliseconds: 10));

        await enqueue(
          collectionPath: 'test',
          documentId: 'third',
          operation: 'set',
          dataJson: '{"order":3}',
        );

        final pending = await getAllPending();
        expect(pending, hasLength(3));
        expect(pending[0].documentId, 'first');
        expect(pending[1].documentId, 'second');
        expect(pending[2].documentId, 'third');
      },
    );

    test('getAllPending() returns empty list when no mutations', () async {
      final pending = await getAllPending();
      expect(pending, isEmpty);
    });

    test('deleteProcessed() removes mutation by id', () async {
      await enqueue(
        collectionPath: 'test',
        documentId: 'toDelete',
        operation: 'set',
      );

      final pending = await getAllPending();
      final id = pending.first.id;

      await deleteProcessed(id);

      final afterDelete = await getAllPending();
      expect(afterDelete, isEmpty);
    });

    test('deleteProcessed() does not affect other mutations', () async {
      await enqueue(
        collectionPath: 'test',
        documentId: 'keep1',
        operation: 'set',
      );
      await enqueue(
        collectionPath: 'test',
        documentId: 'toDelete',
        operation: 'set',
      );
      await enqueue(
        collectionPath: 'test',
        documentId: 'keep2',
        operation: 'set',
      );

      final pending = await getAllPending();
      final idToDelete = pending[1].id;

      await deleteProcessed(idToDelete);

      final remaining = await getAllPending();
      expect(remaining, hasLength(2));
      expect(remaining.map((m) => m.documentId), ['keep1', 'keep2']);
    });

    test('incrementRetry() increments retry count by 1', () async {
      await enqueue(
        collectionPath: 'test',
        documentId: 'doc1',
        operation: 'set',
      );

      final pending = await getAllPending();
      final id = pending.first.id;
      expect(pending.first.retryCount, 0);

      await incrementRetry(id);

      final after = await getAllPending();
      expect(after.first.retryCount, 1);
    });

    test(
      'incrementRetry() can increment multiple times (1, 2, 3...)',
      () async {
        await enqueue(
          collectionPath: 'test',
          documentId: 'doc1',
          operation: 'set',
        );

        final pending = await getAllPending();
        final id = pending.first.id;

        await incrementRetry(id);
        expect((await getAllPending()).first.retryCount, 1);

        await incrementRetry(id);
        expect((await getAllPending()).first.retryCount, 2);

        await incrementRetry(id);
        expect((await getAllPending()).first.retryCount, 3);

        await incrementRetry(id);
        expect((await getAllPending()).first.retryCount, 4);
      },
    );

    test('incrementRetry() only affects the specified mutation', () async {
      await enqueue(
        collectionPath: 'test',
        documentId: 'doc1',
        operation: 'set',
      );
      await enqueue(
        collectionPath: 'test',
        documentId: 'doc2',
        operation: 'set',
      );

      final pending = await getAllPending();
      final id1 = pending[0].id;

      await incrementRetry(id1);

      final after = await getAllPending();
      expect(after[0].retryCount, 1);
      expect(after[1].retryCount, 0);
    });
  });

  group('Sync Engine - Marker Processing', () {
    late MockFirebaseFirestore mockFirestore;
    late MockMutationQueueDao mockDao;
    late EnhancedSyncEngine engine;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockDao = MockMutationQueueDao();
      engine = EnhancedSyncEngine(mockDao, mockFirestore);
      registerFallbackValue(<String, dynamic>{});
      registerFallbackValue(SetOptions(merge: true));
    });

    test('increment marker is processed in set operation', () async {
      final dataJson = jsonEncode({
        'score': <String, dynamic>{'__type__': 'increment', 'value': 5},
      });
      final mutation = MutationQueueTableData(
        id: 1,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'set',
        dataJson: dataJson,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});

      final mockDocRef = MockDocumentReference();
      final mockCollectionRef = MockCollectionReference();
      when(
        () => mockFirestore.collection(any<String>()),
      ).thenReturn(mockCollectionRef);
      when(() => mockCollectionRef.doc(any<String>())).thenReturn(mockDocRef);
      when(() => mockDocRef.set(any(), any())).thenAnswer((_) async => {});

      await engine.processMutationQueue();

      verify(() => mockDocRef.set(any(), any())).called(1);
      verify(() => mockDao.deleteProcessed(1)).called(1);
    });

    test('serverTimestamp marker is processed in update operation', () async {
      final dataJson = jsonEncode({
        'updatedAt': <String, dynamic>{'__type__': 'serverTimestamp'},
      });
      final mutation = MutationQueueTableData(
        id: 2,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'update',
        dataJson: dataJson,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});

      final mockDocRef = MockDocumentReference();
      final mockCollectionRef = MockCollectionReference();
      when(
        () => mockFirestore.collection(any<String>()),
      ).thenReturn(mockCollectionRef);
      when(() => mockCollectionRef.doc(any<String>())).thenReturn(mockDocRef);
      when(() => mockDocRef.update(any())).thenAnswer((_) async => {});

      await engine.processMutationQueue();

      verify(() => mockDocRef.update(any())).called(1);
    });

    test('arrayUnion marker is processed in set operation', () async {
      final dataJson = jsonEncode({
        'tags': <String, dynamic>{
          '__type__': 'arrayUnion',
          'values': ['new', 'tags'],
        },
      });
      final mutation = MutationQueueTableData(
        id: 3,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'set',
        dataJson: dataJson,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});

      final mockDocRef = MockDocumentReference();
      final mockCollectionRef = MockCollectionReference();
      when(
        () => mockFirestore.collection(any<String>()),
      ).thenReturn(mockCollectionRef);
      when(() => mockCollectionRef.doc(any<String>())).thenReturn(mockDocRef);
      when(() => mockDocRef.set(any(), any())).thenAnswer((_) async => {});

      await engine.processMutationQueue();

      verify(() => mockDocRef.set(any(), any())).called(1);
    });

    test('arrayRemove marker is processed in update operation', () async {
      final dataJson = jsonEncode({
        'tags': <String, dynamic>{
          '__type__': 'arrayRemove',
          'values': ['old'],
        },
      });
      final mutation = MutationQueueTableData(
        id: 4,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'update',
        dataJson: dataJson,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});

      final mockDocRef = MockDocumentReference();
      final mockCollectionRef = MockCollectionReference();
      when(
        () => mockFirestore.collection(any<String>()),
      ).thenReturn(mockCollectionRef);
      when(() => mockCollectionRef.doc(any<String>())).thenReturn(mockDocRef);
      when(() => mockDocRef.update(any())).thenAnswer((_) async => {});

      await engine.processMutationQueue();

      verify(() => mockDocRef.update(any())).called(1);
    });

    test('nested map markers are processed recursively', () async {
      final dataJson = jsonEncode({
        'stats': <String, dynamic>{
          'nested': <String, dynamic>{'__type__': 'increment', 'value': 10},
        },
      });
      final mutation = MutationQueueTableData(
        id: 5,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'set',
        dataJson: dataJson,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});

      final mockDocRef = MockDocumentReference();
      final mockCollectionRef = MockCollectionReference();
      when(
        () => mockFirestore.collection(any<String>()),
      ).thenReturn(mockCollectionRef);
      when(() => mockCollectionRef.doc(any<String>())).thenReturn(mockDocRef);
      when(() => mockDocRef.set(any(), any())).thenAnswer((_) async => {});

      await engine.processMutationQueue();

      verify(() => mockDocRef.set(any(), any())).called(1);
    });

    test('list items with markers are processed', () async {
      final dataJson = jsonEncode({
        'items': [
          <String, dynamic>{'__type__': 'increment', 'value': 1},
          <String, dynamic>{'__type__': 'serverTimestamp'},
        ],
      });
      final mutation = MutationQueueTableData(
        id: 6,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'set',
        dataJson: dataJson,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});

      final mockDocRef = MockDocumentReference();
      final mockCollectionRef = MockCollectionReference();
      when(
        () => mockFirestore.collection(any<String>()),
      ).thenReturn(mockCollectionRef);
      when(() => mockCollectionRef.doc(any<String>())).thenReturn(mockDocRef);
      when(() => mockDocRef.set(any(), any())).thenAnswer((_) async => {});

      await engine.processMutationQueue();

      verify(() => mockDocRef.set(any(), any())).called(1);
    });

    test('non-marker maps are left unchanged', () async {
      final dataJson = jsonEncode({
        'profile': <String, dynamic>{'name': 'John', 'age': 30},
      });
      final mutation = MutationQueueTableData(
        id: 7,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'set',
        dataJson: dataJson,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});

      final mockDocRef = MockDocumentReference();
      final mockCollectionRef = MockCollectionReference();
      when(
        () => mockFirestore.collection(any<String>()),
      ).thenReturn(mockCollectionRef);
      when(() => mockCollectionRef.doc(any<String>())).thenReturn(mockDocRef);
      when(() => mockDocRef.set(any(), any())).thenAnswer((_) async => {});

      await engine.processMutationQueue();

      verify(() => mockDocRef.set(any(), any())).called(1);
    });
  });

  group('Sync Engine - Timestamp Conversion', () {
    late MockFirebaseFirestore mockFirestore;
    late MockMutationQueueDao mockDao;
    late EnhancedSyncEngine engine;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockDao = MockMutationQueueDao();
      engine = EnhancedSyncEngine(mockDao, mockFirestore);
      registerFallbackValue(<String, dynamic>{});
      registerFallbackValue(SetOptions(merge: true));
    });

    test('ISO string at top level is converted to Timestamp', () async {
      final dataJson = jsonEncode({'createdAt': '2024-01-15T10:30:00Z'});
      final mutation = MutationQueueTableData(
        id: 1,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'set',
        dataJson: dataJson,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});

      final mockDocRef = MockDocumentReference();
      final mockCollectionRef = MockCollectionReference();
      when(
        () => mockFirestore.collection(any<String>()),
      ).thenReturn(mockCollectionRef);
      when(() => mockCollectionRef.doc(any<String>())).thenReturn(mockDocRef);
      when(() => mockDocRef.set(any(), any())).thenAnswer((_) async => {});

      await engine.processMutationQueue();

      verify(() => mockDocRef.set(any(), any())).called(1);
    });

    test('ISO string in nested map is converted', () async {
      final dataJson = jsonEncode({
        'metadata': <String, dynamic>{'updatedAt': '2024-06-20T14:00:00Z'},
      });
      final mutation = MutationQueueTableData(
        id: 2,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'set',
        dataJson: dataJson,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});

      final mockDocRef = MockDocumentReference();
      final mockCollectionRef = MockCollectionReference();
      when(
        () => mockFirestore.collection(any<String>()),
      ).thenReturn(mockCollectionRef);
      when(() => mockCollectionRef.doc(any<String>())).thenReturn(mockDocRef);
      when(() => mockDocRef.set(any(), any())).thenAnswer((_) async => {});

      await engine.processMutationQueue();

      verify(() => mockDocRef.set(any(), any())).called(1);
    });

    test('non-ISO strings left unchanged', () async {
      final dataJson = jsonEncode({
        'name': 'John Doe',
        'email': 'john@example.com',
        'status': 'active',
      });
      final mutation = MutationQueueTableData(
        id: 3,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'set',
        dataJson: dataJson,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});

      final mockDocRef = MockDocumentReference();
      final mockCollectionRef = MockCollectionReference();
      when(
        () => mockFirestore.collection(any<String>()),
      ).thenReturn(mockCollectionRef);
      when(() => mockCollectionRef.doc(any<String>())).thenReturn(mockDocRef);
      when(() => mockDocRef.set(any(), any())).thenAnswer((_) async => {});

      await engine.processMutationQueue();

      verify(() => mockDocRef.set(any(), any())).called(1);
    });

    test('numbers left unchanged', () async {
      final dataJson = jsonEncode({'count': 42, 'score': 3.14});
      final mutation = MutationQueueTableData(
        id: 4,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'set',
        dataJson: dataJson,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});

      final mockDocRef = MockDocumentReference();
      final mockCollectionRef = MockCollectionReference();
      when(
        () => mockFirestore.collection(any<String>()),
      ).thenReturn(mockCollectionRef);
      when(() => mockCollectionRef.doc(any<String>())).thenReturn(mockDocRef);
      when(() => mockDocRef.set(any(), any())).thenAnswer((_) async => {});

      await engine.processMutationQueue();

      verify(() => mockDocRef.set(any(), any())).called(1);
    });

    test('boolean values left unchanged', () async {
      final dataJson = jsonEncode({'isActive': true, 'isDeleted': false});
      final mutation = MutationQueueTableData(
        id: 5,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'set',
        dataJson: dataJson,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});

      final mockDocRef = MockDocumentReference();
      final mockCollectionRef = MockCollectionReference();
      when(
        () => mockFirestore.collection(any<String>()),
      ).thenReturn(mockCollectionRef);
      when(() => mockCollectionRef.doc(any<String>())).thenReturn(mockDocRef);
      when(() => mockDocRef.set(any(), any())).thenAnswer((_) async => {});

      await engine.processMutationQueue();

      verify(() => mockDocRef.set(any(), any())).called(1);
    });
  });

  group('Sync Engine - Mutation Application', () {
    late MockFirebaseFirestore mockFirestore;
    late MockMutationQueueDao mockDao;
    late MockDocumentReference mockDocRef;
    late MockCollectionReference mockCollectionRef;
    late EnhancedSyncEngine engine;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockDao = MockMutationQueueDao();
      mockDocRef = MockDocumentReference();
      mockCollectionRef = MockCollectionReference();
      engine = EnhancedSyncEngine(mockDao, mockFirestore);

      registerFallbackValue(<String, dynamic>{});
      registerFallbackValue(SetOptions(merge: true));

      when(
        () => mockFirestore.collection(any<String>()),
      ).thenReturn(mockCollectionRef);
      when(() => mockCollectionRef.doc(any<String>())).thenReturn(mockDocRef);
    });

    test(
      'set operation calls ref.set(data, SetOptions(merge: true))',
      () async {
        final dataJson = jsonEncode({'name': 'Habit', 'count': 5});
        final mutation = MutationQueueTableData(
          id: 1,
          collectionPath: 'users/user1/habits',
          documentId: 'habit_1',
          operation: 'set',
          dataJson: dataJson,
          createdAt: DateTime.now().toIso8601String(),
          retryCount: 0,
        );

        when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
        when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});
        when(() => mockDocRef.set(any(), any())).thenAnswer((_) async => {});

        await engine.processMutationQueue();

        verify(() => mockDocRef.set(any(), any())).called(1);
        verify(() => mockDao.deleteProcessed(1)).called(1);
      },
    );

    test('update operation calls ref.update(data)', () async {
      final dataJson = jsonEncode({'count': 10});
      final mutation = MutationQueueTableData(
        id: 2,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'update',
        dataJson: dataJson,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});
      when(() => mockDocRef.update(any())).thenAnswer((_) async => {});

      await engine.processMutationQueue();

      verify(() => mockDocRef.update(any())).called(1);
      verify(() => mockDao.deleteProcessed(2)).called(1);
    });

    test('delete operation calls ref.delete()', () async {
      final mutation = MutationQueueTableData(
        id: 3,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'delete',
        dataJson: null,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});
      when(() => mockDocRef.delete()).thenAnswer((_) async => {});

      await engine.processMutationQueue();

      verify(() => mockDocRef.delete()).called(1);
      verify(() => mockDao.deleteProcessed(3)).called(1);
    });

    test(
      'invalid operation increments retry and does not call firestore',
      () async {
        final mutation = MutationQueueTableData(
          id: 4,
          collectionPath: 'users/user1/habits',
          documentId: 'habit_1',
          operation: 'invalid_op',
          dataJson: null,
          createdAt: DateTime.now().toIso8601String(),
          retryCount: 0,
        );

        when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
        when(() => mockDao.incrementRetry(any())).thenAnswer((_) async {});

        await engine.processMutationQueue();

        verifyNever(() => mockDocRef.set(any(), any()));
        verifyNever(() => mockDocRef.update(any()));
        verifyNever(() => mockDocRef.delete());
        verify(() => mockDao.incrementRetry(4)).called(1);
      },
    );

    test('error during set mutation increments retry', () async {
      final dataJson = jsonEncode({'name': 'Habit'});
      final mutation = MutationQueueTableData(
        id: 5,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'set',
        dataJson: dataJson,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.incrementRetry(any())).thenAnswer((_) async {});
      when(
        () => mockDocRef.set(any(), any()),
      ).thenThrow(FirebaseException(plugin: 'firestore'));

      await engine.processMutationQueue();

      verify(() => mockDao.incrementRetry(5)).called(1);
    });

    test('error during update mutation increments retry', () async {
      final dataJson = jsonEncode({'count': 5});
      final mutation = MutationQueueTableData(
        id: 6,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'update',
        dataJson: dataJson,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.incrementRetry(any())).thenAnswer((_) async {});
      when(
        () => mockDocRef.update(any()),
      ).thenThrow(FirebaseException(plugin: 'firestore'));

      await engine.processMutationQueue();

      verify(() => mockDao.incrementRetry(6)).called(1);
    });

    test('error during delete mutation increments retry', () async {
      final mutation = MutationQueueTableData(
        id: 7,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'delete',
        dataJson: null,
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 0,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.incrementRetry(any())).thenAnswer((_) async {});
      when(
        () => mockDocRef.delete(),
      ).thenThrow(FirebaseException(plugin: 'firestore'));

      await engine.processMutationQueue();

      verify(() => mockDao.incrementRetry(7)).called(1);
    });

    test('mutation dropped after 3 retries', () async {
      final mutation = MutationQueueTableData(
        id: 8,
        collectionPath: 'users/user1/habits',
        documentId: 'habit_1',
        operation: 'set',
        dataJson: jsonEncode({'name': 'Habit'}),
        createdAt: DateTime.now().toIso8601String(),
        retryCount: 3,
      );

      when(() => mockDao.getAllPending()).thenAnswer((_) async => [mutation]);
      when(() => mockDao.incrementRetry(any())).thenAnswer((_) async {});
      when(() => mockDao.deleteProcessed(any())).thenAnswer((_) async {});
      when(
        () => mockDocRef.set(any(), any()),
      ).thenThrow(FirebaseException(plugin: 'firestore'));

      await engine.processMutationQueue();

      verify(() => mockDao.deleteProcessed(8)).called(1);
    });

    test('prevents concurrent execution of processMutationQueue', () async {
      when(() => mockDao.getAllPending()).thenAnswer((_) async => []);

      final future1 = engine.processMutationQueue();
      final future2 = engine.processMutationQueue();
      await Future.wait([future1, future2]);

      verify(() => mockDao.getAllPending()).called(1);
    });
  });
}
