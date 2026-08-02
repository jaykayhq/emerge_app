import 'package:cloud_firestore/cloud_firestore.dart';

/// Streams web premium status from the `users/{uid}` Firestore document.
///
/// The Paystack webhook (`functions/src/payments/paystack.ts:129-136`)
/// writes `users/{uid}.isPremium = true` (+ `premium_since`,
/// `identity_type`) on charge.success. Existing rules
/// (`firestore.rules:283-290`, owner-read of `users/{userId}`) already
/// permit this read — no rules change needed. Emits `false` while the
/// document is missing or `isPremium` is not exactly `true`.
Stream<bool> streamWebPremium(FirebaseFirestore firestore, String uid) {
  return firestore
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => snap.data()?['isPremium'] == true);
}
