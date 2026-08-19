// lib/features/social/data/services/firebase_creator_media_service.dart
import 'dart:typed_data';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/social/domain/services/creator_media_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Storage-backed [CreatorMediaService]. Uploads land under
/// `creator_media/{userId}/...` — exactly the shape the storage rules
/// whitelist for owner writes and public reads.
class FirebaseCreatorMediaService implements CreatorMediaService {
  final FirebaseStorage _storage;

  FirebaseCreatorMediaService(this._storage);

  @override
  Future<String> uploadCreatorImage({
    required String userId,
    required CreatorMediaType type,
    required Uint8List bytes,
    String? filename,
    String? blueprintId,
  }) async {
    final path = creatorMediaStoragePath(
      userId,
      type,
      filename,
      blueprintId: blueprintId,
    );
    final ref = _storage.ref(path);
    try {
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      AppLogger.i('CreatorMediaService: uploaded $path');
      return url;
    } catch (e, s) {
      AppLogger.e('CreatorMediaService: upload failed for $path', e, s);
      rethrow;
    }
  }
}
