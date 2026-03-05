import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/monetization/domain/entities/habit_contract.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final habitContractRepositoryProvider = Provider<HabitContractRepository>((
  ref,
) {
  return HabitContractRepository(FirebaseFirestore.instance);
});

class HabitContractRepository {
  final FirebaseFirestore _firestore;

  HabitContractRepository(this._firestore);

  /// Create a new social contract between user and partner.
  Future<void> createContract(HabitContract contract) async {
    await _firestore
        .collection('contracts')
        .doc(contract.id)
        .set(contract.toMap());
  }

  /// Watch all contracts where the user is the owner.
  Stream<List<HabitContract>> watchUserContracts(String userId) {
    return _firestore
        .collection('contracts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HabitContract.fromMap(doc.data()))
              .toList();
        });
  }

  /// Watch contracts where user is either owner or partner.
  Stream<List<HabitContract>> watchAllPartnerContracts(String userId) {
    // Firestore doesn't support OR queries on different fields in one query,
    // so we merge two streams.
    final ownedStream = _firestore
        .collection('contracts')
        .where('userId', isEqualTo: userId)
        .snapshots();

    final partnerStream = _firestore
        .collection('contracts')
        .where('partnerId', isEqualTo: userId)
        .snapshots();

    return ownedStream.asyncExpand((ownedSnapshot) {
      return partnerStream.map((partnerSnapshot) {
        final owned = ownedSnapshot.docs
            .map((doc) => HabitContract.fromMap(doc.data()))
            .toList();
        final partnered = partnerSnapshot.docs
            .map((doc) => HabitContract.fromMap(doc.data()))
            .toList();

        // Dedupe by id
        final all = <String, HabitContract>{};
        for (final c in owned) {
          all[c.id] = c;
        }
        for (final c in partnered) {
          all[c.id] = c;
        }
        return all.values.toList();
      });
    });
  }

  /// Get active contracts for a specific partner pair.
  Future<List<HabitContract>> getActiveContractsWith(
    String userId,
    String partnerId,
  ) async {
    final snapshot = await _firestore
        .collection('contracts')
        .where('userId', isEqualTo: userId)
        .where('partnerId', isEqualTo: partnerId)
        .where('status', isEqualTo: 'active')
        .get();

    return snapshot.docs
        .map((doc) => HabitContract.fromMap(doc.data()))
        .toList();
  }

  /// Update contract status (e.g., complete, broken).
  Future<void> updateContractStatus(
    String contractId, {
    required String status,
    int? missedDays,
  }) async {
    final data = <String, dynamic>{'status': status};
    if (missedDays != null) {
      data['missedDays'] = missedDays;
    }
    await _firestore.collection('contracts').doc(contractId).update(data);
  }

  /// Record a missed day on a contract.
  Future<void> recordMissedDay(String contractId) async {
    await _firestore.collection('contracts').doc(contractId).update({
      'missedDays': FieldValue.increment(1),
    });
  }
}
