import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'narrator_guide_controller.g.dart';

/// Stateless controller for the narrator-guide tutorial system.
///
/// Screens ask [shouldShow] on first frame and call [markSeen] when the
/// guide is dismissed. Reads the existing `tutorialsEnabled` toggle so the
/// Settings switch governs all guides app-wide.
@Riverpod(keepAlive: true)
NarratorGuideController narratorGuideController(Ref ref) {
  return NarratorGuideController(ref: ref);
}

class NarratorGuideController {
  NarratorGuideController({required this.ref});
  final Ref ref;

  LocalSettingsRepository get _repo =>
      ref.read(localSettingsRepositoryProvider);

  Future<bool> shouldShow(String nodeId) async {
    if (!_repo.isTutorialsEnabled()) return false;
    return !(await _repo.getHasSeenNarratorGuide(nodeId));
  }

  Future<void> markSeen(String nodeId) async {
    await _repo.setHasSeenNarratorGuide(nodeId);
  }
}
