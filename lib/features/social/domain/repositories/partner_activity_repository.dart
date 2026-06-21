import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads partner-activity events written by [SocialActivityService]'s
/// fan-out-on-write. Events live at
/// `users/{partnerId}/partner_activity/{eventId}` and are denormalized
/// (actor name/type/payload snapshotted at write time) so reads never
/// fan out to user profiles.
abstract class PartnerActivityRepository {
  /// Stream of partner-activity events for [userId], newest first.
  Stream<List<Map<String, dynamic>>> watchPartnerActivity(String userId);
}

class FirestorePartnerActivityRepository
    implements PartnerActivityRepository {
  final FirebaseFirestore _firestore;

  FirestorePartnerActivityRepository(this._firestore);

  @override
  Stream<List<Map<String, dynamic>>> watchPartnerActivity(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('partner_activity')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }
}
