// lib/features/social/data/services/creator_image_picker.dart
import 'package:emerge_app/features/social/domain/services/creator_media_service.dart';

/// Abstraction over the platform image picker so widget tests can inject a
/// fake and screens never touch the plugin directly.
abstract class CreatorImagePicker {
  /// Opens the gallery / file picker. Returns null when the user cancels —
  /// callers must treat null as a no-op, never an error.
  Future<PickedCreatorImage?> pickImage();
}
