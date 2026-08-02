import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/monetization/domain/models/premium_state.dart';

/// Streams web premium status from the `users/{uid}` Firestore document.
///
/// The Paystack webhook (`functions/src/payments/paystack.ts:129-136`)
/// writes `users/{uid}.isPremium = true` (+ `premium_since`,
/// `identity_type`) on charge.success; the `managePremium` callable writes
/// `subscriptionStatus: "paused"` + `premiumEndsAt` (pause) or
/// `isPremium: false` (cancel). Existing rules
/// (`firestore.rules:283-290`, owner-read of `users/{userId}`) already
/// permit this read — no rules change needed. Emits `false` while the
/// document is missing, free, or a pause window has expired.
Stream<bool> streamWebPremium(FirebaseFirestore firestore, String uid) {
  return firestore
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => recordToPremium(snap.data()));
}

/// Firestore-layer mapping: Timestamp -> DateTime, then the pure decision.
/// Public so `IsPremium._buildFromFirestore` reuses it for the initial read.
bool recordToPremium(Map<String, dynamic>? data) {
  final endsAtRaw = data?['premiumEndsAt'];
  final parsed = <String, dynamic>{
    ...?data,
    if (endsAtRaw != null)
      'premiumEndsAt': endsAtRaw is Timestamp
          ? endsAtRaw.toDate()
          : endsAtRaw is DateTime
              ? endsAtRaw
              : DateTime.tryParse(endsAtRaw.toString()),
  };
  return computePremiumState(record: parsed, now: DateTime.now()).isPremium;
}
