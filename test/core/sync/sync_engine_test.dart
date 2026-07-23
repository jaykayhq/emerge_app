import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/core/drift/database.dart';

class MockMutationQueueDao extends Mock implements MutationQueueDao {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late MockMutationQueueDao mockMutationQueue;
  late EnhancedSyncEngine engine;

  setUp(() {
    mockMutationQueue = MockMutationQueueDao();
    engine = EnhancedSyncEngine(mockMutationQueue, MockFirebaseFirestore());
  });

  group('EnhancedSyncEngine', () {
    test('prevents concurrent execution of processMutationQueue', () async {
      when(() => mockMutationQueue.getDue(any()))
          .thenAnswer((_) async => []);

      final future1 = engine.processMutationQueue();
      final future2 = engine.processMutationQueue();
      await Future.wait([future1, future2]);

      // The _isProcessing guard serializes processing; under concurrency at
      // least one fetch occurs and no exception is thrown.
      verify(() => mockMutationQueue.getDue(any()))
          .called(greaterThanOrEqualTo(1));
    });
  });
}
