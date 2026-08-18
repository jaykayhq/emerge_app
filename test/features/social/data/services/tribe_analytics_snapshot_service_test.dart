// test/features/social/data/services/tribe_analytics_snapshot_service_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/data/services/tribe_analytics_snapshot_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late TribeAnalyticsSnapshotService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = TribeAnalyticsSnapshotService(firestore: firestore);
  });

  Future<void> seedTribe() async {
    await firestore.collection('tribes').doc('t1').set({
      'name': 'The Forge',
      'memberCount': 3,
      'createdBy': 'creator1',
      'type': 'creator',
    });
    final contributors = firestore
        .collection('tribes')
        .doc('t1')
        .collection('contributors');
    await contributors.doc('u1').set({
      'userName': 'Ada',
      'totalXpContributed': 3000,
      'totalHabitsCompleted': 40,
      'totalChallengesCompleted': 2,
      'joinedAt': DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String(),
      'lastActivity': DateTime.now().toIso8601String(),
    });
    await contributors.doc('u2').set({
      'userName': 'Bob',
      'totalXpContributed': 2000,
      'totalHabitsCompleted': 20,
      'totalChallengesCompleted': 1,
      'joinedAt': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
      'lastActivity': DateTime.now().toIso8601String(),
    });
  }

  test('writes a snapshot when none exists', () async {
    await seedTribe();
    final result = await service.ensureTodaySnapshot(
      uid: 'creator1',
      tribeId: 't1',
    );
    expect(result.isRight(), isTrue);

    final today = _dateKey(DateTime.now());
    final snap = await firestore
        .collection('tribe_analytics')
        .doc('t1')
        .collection('daily')
        .doc(today)
        .get();
    expect(snap.exists, isTrue);
    final data = snap.data()!;
    expect(data['memberCount'], 3);
    expect(data['totalXp'], 5000);
    expect(data['totalHabitsCompleted'], 60);
    expect(data['totalChallengesCompleted'], 3);
  });

  test('does not rewrite a fresh snapshot (idempotent per day)', () async {
    await seedTribe();
    await service.ensureTodaySnapshot(uid: 'creator1', tribeId: 't1');
    // Mutate the tribe so a rewrite would change numbers.
    await firestore.collection('tribes').doc('t1').update({'memberCount': 99});
    await service.ensureTodaySnapshot(uid: 'creator1', tribeId: 't1');

    final today = _dateKey(DateTime.now());
    final snap = await firestore
        .collection('tribe_analytics')
        .doc('t1')
        .collection('daily')
        .doc(today)
        .get();
    expect(snap.data()!['memberCount'], 3); // unchanged
  });

  test('reads last 30 days of trends sorted ascending', () async {
    await seedTribe();
    await service.ensureTodaySnapshot(uid: 'creator1', tribeId: 't1');
    final trends = await service.getTrends(tribeId: 't1', days: 30);
    expect(trends.isRight(), isTrue);
    final list = trends.getRight().toNullable()!;
    expect(list, isNotEmpty);
    expect(list.length, 1);
    expect(list.first.memberCount, 3);
  });

  test('returns Left on invalid tribe', () async {
    final result = await service.ensureTodaySnapshot(
      uid: 'creator1',
      tribeId: '',
    );
    expect(result.isLeft(), isTrue);
  });

  test('future-dated snapshot does not suppress today\'s write', () async {
    // A forward-skewed clock (or malicious row) wrote 2026-09-19. The
    // client backstop must still write today — otherwise every device
    // suppresses its own snapshot until that date passes.
    final now = DateTime.utc(2026, 8, 18, 12, 0);
    service = TribeAnalyticsSnapshotService(
      firestore: firestore,
      now: () => now,
    );
    await seedTribe();
    await firestore
        .collection('tribe_analytics')
        .doc('t1')
        .collection('daily')
        .doc('2026-09-19')
        .set({'date': '2026-09-19'});

    final result = await service.ensureTodaySnapshot(
      uid: 'creator1',
      tribeId: 't1',
    );
    expect(result.isRight(), isTrue);

    final today = _dateKey(now);
    final snap = await firestore
        .collection('tribe_analytics')
        .doc('t1')
        .collection('daily')
        .doc(today)
        .get();
    expect(snap.exists, isTrue);
  });

  test('dateKey is UTC-based to match the Node snapshot job', () {
    // These exact strings are mirrored by the Node dateKey test
    // (scripts/tribe-analytics-snapshot/test/snapshot.test.mjs). On a
    // non-UTC device the old local-components implementation produced
    // different keys than the server at the same instant.
    expect(
      TribeAnalyticsSnapshotService.dateKey(DateTime.utc(2026, 8, 18, 0, 30)),
      '2026-08-18',
    );
    // A local-flagged instant must key by its UTC calendar in every
    // timezone — on an east-of-UTC host the old code produced 08-19 here.
    expect(
      TribeAnalyticsSnapshotService.dateKey(
        DateTime.utc(2026, 8, 17, 23, 30).toLocal(),
      ),
      '2026-08-17',
    );
    // Parity invariant: any instant keyed through its UTC calendar is stable
    // regardless of the host timezone.
    final local = DateTime.now();
    expect(
      TribeAnalyticsSnapshotService.dateKey(local),
      TribeAnalyticsSnapshotService.dateKey(local.toUtc()),
    );
  });
}

String _dateKey(DateTime dt) => TribeAnalyticsSnapshotService.dateKey(dt);
