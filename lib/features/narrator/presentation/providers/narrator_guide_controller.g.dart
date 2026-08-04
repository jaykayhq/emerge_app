// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'narrator_guide_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stateless controller for the narrator-guide tutorial system.
///
/// Screens ask [shouldShow] on first frame and call [markSeen] when the
/// guide is dismissed. Reads the existing `tutorialsEnabled` toggle so the
/// Settings switch governs all guides app-wide.

@ProviderFor(narratorGuideController)
final narratorGuideControllerProvider = NarratorGuideControllerProvider._();

/// Stateless controller for the narrator-guide tutorial system.
///
/// Screens ask [shouldShow] on first frame and call [markSeen] when the
/// guide is dismissed. Reads the existing `tutorialsEnabled` toggle so the
/// Settings switch governs all guides app-wide.

final class NarratorGuideControllerProvider
    extends
        $FunctionalProvider<
          NarratorGuideController,
          NarratorGuideController,
          NarratorGuideController
        >
    with $Provider<NarratorGuideController> {
  /// Stateless controller for the narrator-guide tutorial system.
  ///
  /// Screens ask [shouldShow] on first frame and call [markSeen] when the
  /// guide is dismissed. Reads the existing `tutorialsEnabled` toggle so the
  /// Settings switch governs all guides app-wide.
  NarratorGuideControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'narratorGuideControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$narratorGuideControllerHash();

  @$internal
  @override
  $ProviderElement<NarratorGuideController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NarratorGuideController create(Ref ref) {
    return narratorGuideController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NarratorGuideController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NarratorGuideController>(value),
    );
  }
}

String _$narratorGuideControllerHash() =>
    r'270442ccc8f038e28d75fa19cb10e809cea24e4a';
