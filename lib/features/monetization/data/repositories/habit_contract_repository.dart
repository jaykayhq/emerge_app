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

  Future<void> createContract(HabitContract contract) async {
    await _firestore
        .collection('contracts')
        .doc(contract.id)
        .set(contract.toMap());
  }

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
}
