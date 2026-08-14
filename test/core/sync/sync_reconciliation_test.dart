// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';

class MockMutationQueueDao extends Mock implements MutationQueueDao {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockMutationQueueDao mockMutationQueue;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockRef;

  setUp(() {
    mockMutationQueue = MockMutationQueueDao();
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockRef = MockDocumentReference();
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(SetOptions(merge: true));
    when(() => mockFirestore.collection('user_activity'))
        .thenReturn(mockCollection);
    when(() => mockCollection.doc('act_1')).thenReturn(mockRef);
  });

  group('SyncEngine at-least-once reconciliation', () {
    MutationQueueTableData pendingSet() => MutationQueueTableData(
          id: 1,
          userId: 'u1',
          collectionPath: 'user_activity',
          documentId: 'act_1',
          operation: 'set',
          dataJson:
              '{"userId":"u1","type":"habit_completion","date":"2026-08-13"}',
          createdAt: '2026-08-13T00:00:00.000',
          retryCount: 0,
          idempotencyKey: null,
          lastError: null,
          nextRetryAt: null,
          status: 'pending',
        );

    test('drops a set mutation denied on an EXISTING doc (already applied)',
        () async {
      final existing = MockDocumentSnapshot();
      when(() => existing.exists).thenReturn(true);
      when(() => mockRef.set(any(), any())).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Missing or insufficient permissions.',
        ),
      );
      when(() => mockRef.get()).thenAnswer((_) async => existing);

      final engine = EnhancedSyncEngine(mockMutationQueue, mockFirestore);
      final ok = await engine.applyMutation(pendingSet());

      // The row is treated as applied — the create-only collection already
      // has the doc, so retrying can only dead-letter.
      expect(ok, isTrue);
    });

    test('keeps retrying a set mutation denied when the doc does NOT exist',
        () async {
      final missing = MockDocumentSnapshot();
      when(() => missing.exists).thenReturn(false);
      when(() => mockRef.set(any(), any())).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Missing or insufficient permissions.',
        ),
      );
      when(() => mockRef.get()).thenAnswer((_) async => missing);

      final engine = EnhancedSyncEngine(mockMutationQueue, mockFirestore);
      final ok = await engine.applyMutation(pendingSet());

      expect(ok, isFalse);
    });
  });
}
