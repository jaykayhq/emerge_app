import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/domain/repositories/partner_activity_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestorePartnerActivityRepository repo;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    repo = FirestorePartnerActivityRepository(firestore);

    // Seed two events for user 'me'.
    await firestore
        .collection('users')
        .doc('me')
        .collection('partner_activity')
        .doc('e1')
        .set({
      'type': 'habit_complete',
      'userId': 'partner1',
      'userName': 'Alex',
      'data': {'habitTitle': 'Cold Plunge'},
      'timestamp': '2026-06-20T10:00:00.000Z',
    });
    await firestore
        .collection('users')
        .doc('me')
        .collection('partner_activity')
        .doc('e2')
        .set({
      'type': 'streak_milestone',
      'userId': 'partner2',
      'userName': 'Sam',
      'data': {'streakDays': 7},
      'timestamp': '2026-06-21T08:00:00.000Z',
    });
  });

  test('watchPartnerActivity emits events ordered by timestamp desc',
      () async {
    final events = await repo.watchPartnerActivity('me').first;
    expect(events.length, 2);
    // Newer timestamp first (e2 < e1 chronologically later means e2 first)
    expect(events.first['userName'], 'Sam');
    expect(events.last['userName'], 'Alex');
    // doc id injected into map
    expect(events.first.containsKey('id'), true);
  });

  test('watchPartnerActivity returns empty for unknown user', () async {
    final events = await repo.watchPartnerActivity('nobody').first;
    expect(events, isEmpty);
  });
}
