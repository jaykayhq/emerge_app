import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/monetization/data/services/web_premium_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emits false while the doc is missing, true after the webhook write',
      () async {
    final fdb = FakeFirebaseFirestore();
    final values = <bool>[];
    final sub = streamWebPremium(fdb, 'uid-1').listen(values.add);

    await fdb
        .collection('users')
        .doc('uid-1')
        .set({'isPremium': true, 'premium_since': Timestamp.now()});
    await pumpEventQueue();

    expect(values, [false, true]);
    await sub.cancel();
  });

  test('emits false again when the doc flips back to non-premium', () async {
    final fdb = FakeFirebaseFirestore();
    await fdb.collection('users').doc('uid-1').set({'isPremium': true});
    final values = <bool>[];
    final sub = streamWebPremium(fdb, 'uid-1').listen(values.add);

    await fdb.collection('users').doc('uid-1').update({'isPremium': false});
    await pumpEventQueue();

    expect(values.first, isTrue);
    expect(values.last, isFalse);
    await sub.cancel();
  });

  test('non-boolean isPremium values are treated as not premium', () async {
    final fdb = FakeFirebaseFirestore();
    await fdb.collection('users').doc('uid-1').set({'isPremium': 'yes'});
    final values = <bool>[];
    final sub = streamWebPremium(fdb, 'uid-1').listen(values.add);
    await pumpEventQueue();

    expect(values.last, isFalse);
    await sub.cancel();
  });
}
