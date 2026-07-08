import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_data.dart';
import 'package:emerge_app/features/avatar/data/avatar_repository.dart';

part 'avatar_providers.g.dart';

/// Stream of avatar data for a given user from Firestore.
@riverpod
Stream<AvatarData> avatarData(Ref ref, String userId) {
  final repo = AvatarRepository();
  return repo.firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return AvatarData.defaultAvatar();
        final data = doc.data()!;
        final avatarJson = data['avatar'] as Map<String, dynamic>?;
        if (avatarJson == null) return AvatarData.defaultAvatar();
        return AvatarData.defaultAvatar().copyWith(
          archetype: avatarJson['archetype'] as String? ?? 'hero',
          level: (avatarJson['level'] as num?)?.toInt() ?? 1,
        );
      });
}

/// Local state for unsaved customization changes (edit in customizer
/// before saving to Firestore).
@Riverpod(keepAlive: true)
class AvatarCustomizationNotifier extends _$AvatarCustomizationNotifier {
  @override
  AvatarData build() => AvatarData.defaultAvatar();

  void updateLevel(int level) => state = state.copyWith(level: level);
  void updateArchetype(String archetype) =>
      state = state.copyWith(archetype: archetype);
  void saveChanges(String userId) {
    final repo = AvatarRepository();
    repo.saveAvatar(userId, state);
  }
}
