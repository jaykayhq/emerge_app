// lib/features/social/data/services/image_picker_adapter.dart
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/social/data/services/creator_image_picker.dart';
import 'package:emerge_app/features/social/domain/services/creator_media_service.dart';
import 'package:image_picker/image_picker.dart';

/// [ImagePicker]-backed [CreatorImagePicker].
///
/// Compression (`maxWidth`/`imageQuality`) is applied by the plugin on
/// Android/iOS; web ignores both and returns the raw file — acceptable since
/// the storage rules cap nothing and uploads stay small in practice.
class ImagePickerAdapter implements CreatorImagePicker {
  final ImagePicker _picker;

  ImagePickerAdapter([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  @override
  Future<PickedCreatorImage?> pickImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return null; // User cancelled — no-op, not an error.
      final bytes = await file.readAsBytes();
      return PickedCreatorImage(
        bytes: bytes,
        filename: file.name.isEmpty ? null : file.name,
      );
    } catch (e, s) {
      AppLogger.e('ImagePickerAdapter: pick failed', e, s);
      rethrow;
    }
  }
}
