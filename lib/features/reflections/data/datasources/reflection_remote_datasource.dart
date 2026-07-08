import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstraction for the remote reflection mirror (Firestore).
abstract class ReflectionRemoteDatasource {
  Future<void> write(Map<String, Object?> data);
}

/// Firestore-backed implementation.
/// Writes a daily reflection doc to users/{uid}/reflections/{dateKey}.
class FirestoreReflectionRemoteDatasource implements ReflectionRemoteDatasource {
  FirestoreReflectionRemoteDatasource({required this.firestore});
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
        .collection('reflections')
        .doc(dayKey)
        .set(data, SetOptions(merge: true));
  }
}
