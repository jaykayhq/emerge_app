import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_remote_datasource.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreHabitReflectionRemoteDatasource ds;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    ds = FirestoreHabitReflectionRemoteDatasource(firestore: firestore);
  });

  test('write creates doc under users/{uid}/habit_reflections/{dateKey}', () async {
    await ds.write({
      'userId': 'u1',
      'habitId': 'h1',
      'localDate': DateTime(2026, 7, 10),
      'mood': 4,
      'note': 'felt strong',
      'updatedAt': DateTime(2026, 7, 10, 12),
    });
    final snap = await firestore
        .collection('users')
        .doc('u1')
        .collection('habit_reflections')
        .doc('2026-07-10')
        .get();
    expect(snap.exists, isTrue);
    expect(snap.data()!['mood'], 4);
    expect(snap.data()!['note'], 'felt strong');
    expect(snap.data()!['habitId'], 'h1');
  });

  test('write with merge=true does not overwrite unrelated fields', () async {
    final col = firestore
        .collection('users')
        .doc('u1')
        .collection('habit_reflections');
    await col.doc('2026-07-10').set({'extra': 'keep-me'});
    await ds.write({
      'userId': 'u1',
      'habitId': 'h1',
      'localDate': DateTime(2026, 7, 10),
      'mood': 4,
      'note': 'felt strong',
      'updatedAt': DateTime(2026, 7, 10, 12),
    });
    final snap = await col.doc('2026-07-10').get();
    expect(snap.data()!['extra'], 'keep-me');
    expect(snap.data()!['mood'], 4);
  });
}
