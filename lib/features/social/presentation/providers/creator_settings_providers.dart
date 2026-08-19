// lib/features/social/presentation/providers/creator_settings_providers.dart
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/social/data/services/creator_image_picker.dart';
import 'package:emerge_app/features/social/data/services/firebase_creator_media_service.dart';
import 'package:emerge_app/features/social/data/services/image_picker_adapter.dart';
import 'package:emerge_app/features/social/domain/services/creator_media_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current signed-in creator uid ('' while signed out). Sourced from the auth
/// stream — never FirebaseAuth.instance directly — so widget tests can
/// override the stream and the shell can react to sign-out.
final currentCreatorUidProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null || user.isEmpty) return null;
  return user.id;
});

/// Uploads creator media (avatar / hero / blueprint cover) to Firebase
/// Storage under `creator_media/{uid}/...`.
final creatorMediaServiceProvider = Provider<CreatorMediaService>((ref) {
  return FirebaseCreatorMediaService(FirebaseStorage.instance);
});

/// Platform gallery picker, abstracted for tests.
final creatorImagePickerProvider = Provider<CreatorImagePicker>((ref) {
  return ImagePickerAdapter();
});

/// The creator's own blueprints for the cover-art section. Streams the full
/// catalog and filters client-side to the current uid — avoids a composite
/// index, same approach as the Blueprint Studio tab.
final creatorOwnBlueprintsProvider = StreamProvider.autoDispose<List<Blueprint>>((
  ref,
) {
  final uid = ref.watch(currentCreatorUidProvider);
  if (uid == null) return Stream.value(const []);
  final repo = ref.watch(blueprintRepositoryProvider);
  return repo
      .getBlueprints()
      .map((list) => list.where((b) => b.creatorUserId == uid).toList());
});
