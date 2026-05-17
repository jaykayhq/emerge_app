// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncEngine extends Mock implements EnhancedSyncEngine {}

class MockGameLoopEngine extends Mock implements LocalGameLoopEngine {}

class MockSocialActivityService extends Mock implements SocialActivityService {}

/// A fake FirebaseFirestore that returns empty results and does nothing on writes.
/// Used for unit tests that don't need actual Firebase interaction.
class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return FakeCollectionReference();
  }
}

class FakeCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return FakeDocumentReference();
  }

  @override
  Query<Map<String, dynamic>> orderBy(dynamic field, {bool descending = false}) {
    return FakeQuery();
  }

  @override
  Query<Map<String, dynamic>> where(dynamic field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return FakeQuery();
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource? source,
  }) {
    return Stream.value(FakeQuerySnapshot());
  }
}

class FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  @override
  Query<Map<String, dynamic>> orderBy(dynamic field, {bool descending = false}) {
    return this;
  }

  @override
  Query<Map<String, dynamic>> limit(int limit) {
    return this;
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource? source,
  }) {
    return Stream.value(FakeQuerySnapshot());
  }
}

class FakeDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  @override
  String get id => 'fake_doc_id';

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return FakeCollectionReference();
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {}

  @override
  Future<void> update(Map<Object, Object?> data) async {}

  @override
  Future<void> delete() async {}

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource? source,
  }) {
    return Stream.value(FakeDocumentSnapshot());
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return FakeDocumentSnapshot();
  }
}

class FakeDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  String get id => 'fake_doc_id';

  @override
  Map<String, dynamic>? data([SnapshotOptions? options]) => null;

  @override
  bool get exists => false;
}

class FakeQuerySnapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => [];

  @override
  List<DocumentChange<Map<String, dynamic>>> get docChanges => [];

  @override
  int get size => 0;
}

/// A real [LocalGameLoopEngine] instance for tests that need actual game logic.
/// Using the real engine avoids mocking complexity for deterministic calculations.
LocalGameLoopEngine createRealGameLoopEngine() {
  return LocalGameLoopEngine();
}
