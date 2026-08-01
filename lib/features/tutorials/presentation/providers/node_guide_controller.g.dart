// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_guide_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stateless controller for the node-guide tutorial system.
///
/// Screens ask [shouldShow] on first frame and call [markSeen] when the
/// guide is dismissed. Reads the existing `tutorialsEnabled` toggle so the
/// Settings switch governs all guides app-wide.

@ProviderFor(nodeGuideController)
final nodeGuideControllerProvider = NodeGuideControllerProvider._();

/// Stateless controller for the node-guide tutorial system.
///
/// Screens ask [shouldShow] on first frame and call [markSeen] when the
/// guide is dismissed. Reads the existing `tutorialsEnabled` toggle so the
/// Settings switch governs all guides app-wide.

final class NodeGuideControllerProvider
    extends
        $FunctionalProvider<
          NodeGuideController,
          NodeGuideController,
          NodeGuideController
        >
    with $Provider<NodeGuideController> {
  /// Stateless controller for the node-guide tutorial system.
  ///
  /// Screens ask [shouldShow] on first frame and call [markSeen] when the
  /// guide is dismissed. Reads the existing `tutorialsEnabled` toggle so the
  /// Settings switch governs all guides app-wide.
  NodeGuideControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nodeGuideControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nodeGuideControllerHash();

  @$internal
  @override
  $ProviderElement<NodeGuideController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NodeGuideController create(Ref ref) {
    return nodeGuideController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NodeGuideController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NodeGuideController>(value),
    );
  }
}

String _$nodeGuideControllerHash() =>
    r'224e51a360b82f373b774cd2320c0c872694a458';
