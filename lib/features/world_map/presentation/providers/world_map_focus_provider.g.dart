// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world_map_focus_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for transient focus events on the world map.
/// Set this to an attribute name (e.g. 'strength') to trigger an animation
/// on the WorldMapScreen. The screen will consume the event and then clear it.

@ProviderFor(MapFocusEvent)
final mapFocusEventProvider = MapFocusEventProvider._();

/// Provider for transient focus events on the world map.
/// Set this to an attribute name (e.g. 'strength') to trigger an animation
/// on the WorldMapScreen. The screen will consume the event and then clear it.
final class MapFocusEventProvider
    extends $NotifierProvider<MapFocusEvent, String?> {
  /// Provider for transient focus events on the world map.
  /// Set this to an attribute name (e.g. 'strength') to trigger an animation
  /// on the WorldMapScreen. The screen will consume the event and then clear it.
  MapFocusEventProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapFocusEventProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapFocusEventHash();

  @$internal
  @override
  MapFocusEvent create() => MapFocusEvent();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$mapFocusEventHash() => r'a65d29bc290d65350fb4dcf4bf67733bcc405e68';

/// Provider for transient focus events on the world map.
/// Set this to an attribute name (e.g. 'strength') to trigger an animation
/// on the WorldMapScreen. The screen will consume the event and then clear it.

abstract class _$MapFocusEvent extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
