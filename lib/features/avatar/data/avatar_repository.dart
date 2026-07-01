import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_data.dart';

/// Reads and writes [AvatarData] to Firestore under `users/{uid}/avatar`.
class AvatarRepository {
  final FirebaseFirestore firestore;

  AvatarRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  static const _collection = 'users';
  static const _field = 'avatar';

  Future<void> saveAvatar(String uid, AvatarData avatar) async {
    await firestore.collection(_collection).doc(uid).set({
      _field: {
        'archetype': avatar.archetype,
        'level': avatar.level,
        'colors': {
          'skin': avatar.colors.skin.toARGB32().toRadixString(16).padLeft(8, '0'),
          'outline':
              avatar.colors.outline.toARGB32().toRadixString(16).padLeft(8, '0'),
          'accent':
              avatar.colors.accent.toARGB32().toRadixString(16).padLeft(8, '0'),
          'glow': avatar.colors.glow.toARGB32().toRadixString(16).padLeft(8, '0'),
        },
        'equipment': avatar.equippedItems.map((e) => e.id).toList(),
      },
    }, SetOptions(merge: true));
  }

  Future<AvatarData?> getAvatar(String uid) async {
    final doc = await firestore.collection(_collection).doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    final avatarJson = data[_field] as Map<String, dynamic>?;
    if (avatarJson == null) return null;

    return AvatarData.defaultAvatar().copyWith(
      archetype: avatarJson['archetype'] as String? ?? 'hero',
      level: (avatarJson['level'] as num?)?.toInt() ?? 1,
    );
  }
}
