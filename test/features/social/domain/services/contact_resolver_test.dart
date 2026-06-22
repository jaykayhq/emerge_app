import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/domain/services/contact_resolver.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ContactResolver resolver;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    resolver = FirestoreContactResolver(firestore);

    // Seed two users with phone numbers.
    await firestore.collection('users').doc('u1').set({
      'displayName': 'Sarah',
      'phone': '+15550142',
      'email': 'sarah@example.com',
    });
    await firestore.collection('users').doc('u2').set({
      'displayName': 'Mike',
      'phone': '+15550188',
      'email': 'mike@example.com',
    });
  });

  test('resolves a contact whose phone matches an existing user', () async {
    const contacts = [
      ResolvedContact(
        name: 'Sarah Chen',
        phone: '+15550142',
        email: 'sarah@example.com',
      ),
      ResolvedContact(
        name: 'Unknown Friend',
        phone: '+15559999',
        email: null,
      ),
    ];
    final results = await resolver.resolve(contacts);
    expect(results.length, 2);
    expect(results.first.contact.name, 'Sarah Chen');
    expect(results.first.matchedUserId, 'u1');
    expect(results.last.matchedUserId, isNull); // no match
  });

  test('matches by email when phone does not match', () async {
    const contacts = [
      ResolvedContact(
        name: 'Mike P',
        phone: '+15557777',
        email: 'mike@example.com',
      ),
    ];
    final results = await resolver.resolve(contacts);
    expect(results.first.matchedUserId, 'u2');
  });
}
