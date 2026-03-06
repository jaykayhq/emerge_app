// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reflection_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TodayReflectionState)
final todayReflectionStateProvider = TodayReflectionStateProvider._();

final class TodayReflectionStateProvider
    extends $NotifierProvider<TodayReflectionState, bool> {
  TodayReflectionStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayReflectionStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayReflectionStateHash();

  @$internal
  @override
  TodayReflectionState create() => TodayReflectionState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$todayReflectionStateHash() =>
    r'777b0f8a2a31c3beaaae8c67eb3ceaa40bc6ddcc';

abstract class _$TodayReflectionState extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
