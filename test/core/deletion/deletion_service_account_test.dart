import 'package:drift/native.dart';
import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/deletion/deletion_service.dart';
import 'package:emerge_app/core/deletion/delete_account_backend.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/drift/database.dart' hide isNull, isNotNull;
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class FakeBackend extends Fake implements DeleteAccountBackend {
  bool shouldSucceed;
  String? lastId;
  FakeBackend(this.shouldSucceed);
  @override
  Future<Either<Failure, Unit>> delete(
      {required String deletionRequestId}) async {
    lastId = deletionRequestId;
    return shouldSucceed ? const Right(unit) : const Left(ServerFailure('boom'));
  }
}

class FakeIdStore extends Fake implements SecureIdStore {
  String? stored;
  @override
  Future<String> loadOrCreateId(String key) async => stored ??= 'id-$key';
  @override
  Future<void> clear(String key) async => stored = null;
}

class MockAuth extends Mock implements FirebaseAuth {}

void main() {
  late AppDatabase db;
  late DeletionService service;
  late FakeBackend backend;
  late FakeIdStore idStore;
  late MockAuth auth;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    backend = FakeBackend(true);
    idStore = FakeIdStore();
    auth = MockAuth();
    when(() => auth.signOut()).thenAnswer((_) async {});
    service = DeletionService(
      db: db,
      syncEngine: EnhancedSyncEngine(
        db.mutationQueueDao,
        FakeFirebaseFirestore(),
        metrics: SyncMetrics(),
      ),
      audit: DeletionAudit(metrics: SyncMetrics()),
    );
  });
  tearDown(() => db.close());

  test('success: clears local db + signs out + returns Right', () async {
    await db.habitsDao.insertFromData(
      id: 'h1',
      userId: 'u1',
      title: 'Read',
      createdAt: DateTime(2026).toIso8601String(),
      updatedAt: DateTime(2026).toIso8601String(),
    );
    final res = await service.deleteAccount(
      userId: 'u1',
      backend: backend,
      idStore: idStore,
      auth: auth,
    );
    expect(res, const Right<Failure, Unit>(unit));
    verify(() => auth.signOut()).called(1);
    expect(backend.lastId, startsWith('id-'));
    expect(await db.habitsDao.getHabit('h1'), isNull); // local cleared
    expect(idStore.stored, isNull); // id cleared after success
  });

  test('failure: local data is NOT cleared, returns Left, id retained',
      () async {
    backend = FakeBackend(false);
    await db.habitsDao.insertFromData(
      id: 'h1',
      userId: 'u1',
      title: 'Read',
      createdAt: DateTime(2026).toIso8601String(),
      updatedAt: DateTime(2026).toIso8601String(),
    );
    final res = await service.deleteAccount(
      userId: 'u1',
      backend: backend,
      idStore: idStore,
      auth: auth,
    );
    expect(res.isLeft(), isTrue);
    verifyNever(() => auth.signOut());
    expect(await db.habitsDao.getHabit('h1'), isNotNull); // survives
    expect(idStore.stored, isNotNull); // deletionRequestId retained for retry
  });
}
