// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recap_hub_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RecapRefreshCounter)
final recapRefreshCounterProvider = RecapRefreshCounterProvider._();

final class RecapRefreshCounterProvider
    extends $NotifierProvider<RecapRefreshCounter, int> {
  RecapRefreshCounterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recapRefreshCounterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recapRefreshCounterHash();

  @$internal
  @override
  RecapRefreshCounter create() => RecapRefreshCounter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$recapRefreshCounterHash() =>
    r'8811a343a89805d3f24ba48d4179747682a8f2c6';

abstract class _$RecapRefreshCounter extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(historicalRecaps)
final historicalRecapsProvider = HistoricalRecapsProvider._();

final class HistoricalRecapsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserWeeklyRecap>>,
          List<UserWeeklyRecap>,
          FutureOr<List<UserWeeklyRecap>>
        >
    with
        $FutureModifier<List<UserWeeklyRecap>>,
        $FutureProvider<List<UserWeeklyRecap>> {
  HistoricalRecapsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historicalRecapsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historicalRecapsHash();

  @$internal
  @override
  $FutureProviderElement<List<UserWeeklyRecap>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserWeeklyRecap>> create(Ref ref) {
    return historicalRecaps(ref);
  }
}

String _$historicalRecapsHash() => r'0d2b905e0a7bec3ccbe92dbbbd713075322a7331';
