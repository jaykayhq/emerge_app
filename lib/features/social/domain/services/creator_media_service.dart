// lib/features/social/domain/services/creator_media_service.dart
import 'dart:typed_data';

/// What kind of creator-owned image is being uploaded. The type selects the
/// Storage sub-folder, so the same user's avatar, hero, and blueprint covers
/// never collide and rules stay scoped per kind.
enum CreatorMediaType { avatar, hero, blueprint }

/// Result of picking an image from the device gallery / web file picker.
/// [filename] may be null on platforms that don't expose a real name (web
/// blobs) — the path builder falls back to a stable default.
class PickedCreatorImage {
  final Uint8List bytes;
  final String? filename;

  const PickedCreatorImage({required this.bytes, this.filename});
}

/// Pure builder for the Storage object path of a creator-owned image.
///
/// Kept free of Firebase so it is unit-testable and so the Storage rules
/// (`storage.rules`: `creator_media/{userId}/{allPaths=**}`) stay the single
/// source of truth for the folder shape. A null [filename] yields the
/// `image.jpg` default.
String creatorMediaStoragePath(
  String userId,
  CreatorMediaType type,
  String? filename, {
  String? blueprintId,
}) {
  final safeName = (filename == null || filename.trim().isEmpty)
      ? 'image.jpg'
      : filename.trim();
  final base = 'creator_media/$userId';
  switch (type) {
    case CreatorMediaType.avatar:
      return '$base/avatar/$safeName';
    case CreatorMediaType.hero:
      return '$base/hero/$safeName';
    case CreatorMediaType.blueprint:
      return '$base/blueprints/$blueprintId/$safeName';
  }
}

/// Uploads creator-owned media (profile avatar, hero banner, blueprint
/// covers) to Firebase Storage and returns the public download URL ready to
/// store on the matching Firestore doc (`creator_profiles.avatarUrl`,
/// `creator_profiles.heroImageUrl`, `blueprints.imageUrl`).
abstract class CreatorMediaService {
  Future<String> uploadCreatorImage({
    required String userId,
    required CreatorMediaType type,
    required Uint8List bytes,
    String? filename,
    String? blueprintId,
  });
}
