import 'package:cloud_firestore/cloud_firestore.dart';

/// A device contact normalized for resolution.
class ResolvedContact {
  final String name;
  final String? phone;
  final String? email;

  const ResolvedContact({required this.name, this.phone, this.email});
}

/// Result of resolving a contact against existing emerge users.
class ContactMatch {
  final ResolvedContact contact;
  final String? matchedUserId;
  final String? matchedDisplayName;

  const ContactMatch({
    required this.contact,
    this.matchedUserId,
    this.matchedDisplayName,
  });

  bool get isMatched => matchedUserId != null;
}

/// Matches device contacts to existing emerge users by phone or email.
/// Privacy: contacts are read on-device; only the phone/email needed for
/// the lookup are sent to Firestore, and resolution is a read, not a store.
abstract class ContactResolver {
  Future<List<ContactMatch>> resolve(List<ResolvedContact> contacts);
}

class FirestoreContactResolver implements ContactResolver {
  final FirebaseFirestore _firestore;
  FirestoreContactResolver(this._firestore);

  @override
  Future<List<ContactMatch>> resolve(List<ResolvedContact> contacts) async {
    final results = <ContactMatch>[];
    for (final c in contacts) {
      String? userId;
      String? displayName;

      if (c.phone != null) {
        final byPhone = await _firestore
            .collection('users')
            .where('phone', isEqualTo: c.phone)
            .limit(1)
            .get();
        if (byPhone.docs.isNotEmpty) {
          userId = byPhone.docs.first.id;
          displayName = byPhone.docs.first.data()['displayName'] as String?;
        }
      }

      if (userId == null && c.email != null) {
        final byEmail = await _firestore
            .collection('users')
            .where('email', isEqualTo: c.email)
            .limit(1)
            .get();
        if (byEmail.docs.isNotEmpty) {
          userId = byEmail.docs.first.id;
          displayName = byEmail.docs.first.data()['displayName'] as String?;
        }
      }

      results.add(ContactMatch(
        contact: c,
        matchedUserId: userId,
        matchedDisplayName: displayName,
      ));
    }
    return results;
  }
}
