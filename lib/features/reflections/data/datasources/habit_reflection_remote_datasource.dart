import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstraction for the remote per-habit reflection mirror (Firestore).
abstract class HabitReflectionRemoteDatasource {
  Future<void> write(Map<String, Object?> data);
}

/// Firestore-backed implementation.
/// Writes a per-habit reflection doc to
/// users/{uid}/habit_reflections/{dateKey}.
class FirestoreHabitReflectionRemoteDatasource
    implements HabitReflectionRemoteDatasource {
  FirestoreHabitReflectionRemoteDatasource({required this.firestore});
  final FirebaseFirestore firestore;

  @override
  Future<void> write(Map<String, Object?> data) async {
    final uid = data['userId'] as String;
    final localDate = data['localDate'] as DateTime;
    final dayKey =
        '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
    await firestore
        .collection('users')
        .doc(uid)
        .collection('habit_reflections')
        .doc(dayKey)
        .set(data, SetOptions(merge: true));
  }
}
