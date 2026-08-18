// test/features/social/presentation/providers/creator_analytics_provider_test.dart
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/drift/database.dart' hide isNotNull;
import 'package:emerge_app/features/social/data/services/creator_analytics_service.dart';
import 'package:emerge_app/features/social/data/services/tribe_analytics_snapshot_service.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_analytics_provider.dart';

void main() {
  test('provider emits analytics for a creator', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('tribes').doc('t1').set({
      'name': 'The Forge',
      'memberCount': 1,
      'createdBy': 'creator1',
      'type': 'creator',
    });
    final inMemoryDb = AppDatabase.withExecutor(NativeDatabase.memory());
    addTearDown(inMemoryDb.close);
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(inMemoryDb),
      creatorAnalyticsServiceProvider.overrideWithValue(
        CreatorAnalyticsService(firestore: firestore),
      ),
      tribeAnalyticsSnapshotServiceProvider.overrideWithValue(
        TribeAnalyticsSnapshotService(firestore: firestore),
      ),
    ]);
    addTearDown(container.dispose);

    final async = await container
        .read(creatorAnalyticsProvider(uid: 'creator1', tribeId: 't1').future);
    expect(async.tribeName, 'The Forge');
    expect(async.memberCount, 1);

    // The just-opened analytics must be warm in the local cache for a
    // later offline open.
    final cached = await inMemoryDb.tribeAnalyticsDao.getLatest(
      userId: 'creator1',
      tribeId: 't1',
    );
    expect(cached, isNotNull);
    expect(cached!.memberCount, 1);
  });
}