// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archetype_node_states_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [ArchetypeStatusService]

@ProviderFor(archetypeStatusService)
final archetypeStatusServiceProvider = ArchetypeStatusServiceProvider._();

/// Provider for [ArchetypeStatusService]

final class ArchetypeStatusServiceProvider
    extends
        $FunctionalProvider<
          ArchetypeStatusService,
          ArchetypeStatusService,
          ArchetypeStatusService
        >
    with $Provider<ArchetypeStatusService> {
  /// Provider for [ArchetypeStatusService]
  ArchetypeStatusServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archetypeStatusServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archetypeStatusServiceHash();

  @$internal
  @override
  $ProviderElement<ArchetypeStatusService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ArchetypeStatusService create(Ref ref) {
    return archetypeStatusService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArchetypeStatusService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArchetypeStatusService>(value),
    );
  }
}

String _$archetypeStatusServiceHash() =>
    r'7714067bccfe362f74d7f57c151c8d84353630a6';

/// Computes the per-archetype [ArchetypeNodeState] map by watching
/// [habitsProvider] and [worldEntropyStreamProvider].

@ProviderFor(archetypeNodeStates)
final archetypeNodeStatesProvider = ArchetypeNodeStatesProvider._();

/// Computes the per-archetype [ArchetypeNodeState] map by watching
/// [habitsProvider] and [worldEntropyStreamProvider].

final class ArchetypeNodeStatesProvider
    extends
        $FunctionalProvider<
          Map<HabitAttribute, ArchetypeNodeState>,
          Map<HabitAttribute, ArchetypeNodeState>,
          Map<HabitAttribute, ArchetypeNodeState>
        >
    with $Provider<Map<HabitAttribute, ArchetypeNodeState>> {
  /// Computes the per-archetype [ArchetypeNodeState] map by watching
  /// [habitsProvider] and [worldEntropyStreamProvider].
  ArchetypeNodeStatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archetypeNodeStatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archetypeNodeStatesHash();

  @$internal
  @override
  $ProviderElement<Map<HabitAttribute, ArchetypeNodeState>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<HabitAttribute, ArchetypeNodeState> create(Ref ref) {
    return archetypeNodeStates(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<HabitAttribute, ArchetypeNodeState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<HabitAttribute, ArchetypeNodeState>>(value),
    );
  }
}

String _$archetypeNodeStatesHash() =>
    r'8f6f2686e86152aec0a865a3dd0d4d5895f2d881';
