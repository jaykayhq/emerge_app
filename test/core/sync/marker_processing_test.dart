// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/core/drift/daos/mutation_queue_dao.dart';

class MockMutationQueueDao extends Mock implements MutationQueueDao {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late MockMutationQueueDao mockMutationQueue;
  late MockFirebaseFirestore mockFirestore;

  setUp(() {
    mockMutationQueue = MockMutationQueueDao();
    mockFirestore = MockFirebaseFirestore();

    registerFallbackValue(<String, dynamic>{});
  });

  group('EnhancedSyncEngine Marker Processing', () {
    test('can construct engine with mocks', () {
      final engine = EnhancedSyncEngine(mockMutationQueue, mockFirestore);
      expect(engine, isNotNull);
    });
  });
}
