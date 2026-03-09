// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_activity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(globalActivityService)
final globalActivityServiceProvider = GlobalActivityServiceProvider._();

final class GlobalActivityServiceProvider
    extends
        $FunctionalProvider<
          GlobalActivityService,
          GlobalActivityService,
          GlobalActivityService
        >
    with $Provider<GlobalActivityService> {
  GlobalActivityServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalActivityServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalActivityServiceHash();

  @$internal
  @override
  $ProviderElement<GlobalActivityService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GlobalActivityService create(Ref ref) {
    return globalActivityService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalActivityService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalActivityService>(value),
    );
  }
}

String _$globalActivityServiceHash() =>
    r'e0423141c5c35ec8ce7aa7cbed47e2525481381c';

@ProviderFor(GlobalActivity)
final globalActivityProvider = GlobalActivityFamily._();

final class GlobalActivityProvider
    extends $StreamNotifierProvider<GlobalActivity, List<Activity>> {
  GlobalActivityProvider._({
    required GlobalActivityFamily super.from,
    required (String?, {int limit}) super.argument,
  }) : super(
         retry: null,
         name: r'globalActivityProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$globalActivityHash();

  @override
  String toString() {
    return r'globalActivityProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  GlobalActivity create() => GlobalActivity();

  @override
  bool operator ==(Object other) {
    return other is GlobalActivityProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$globalActivityHash() => r'6b34224300aa87fad64017009c9616fa3d83be22';

final class GlobalActivityFamily extends $Family
    with
        $ClassFamilyOverride<
          GlobalActivity,
          AsyncValue<List<Activity>>,
          List<Activity>,
          Stream<List<Activity>>,
          (String?, {int limit})
        > {
  GlobalActivityFamily._()
    : super(
        retry: null,
        name: r'globalActivityProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GlobalActivityProvider call(String? clubId, {int limit = 50}) =>
      GlobalActivityProvider._(argument: (clubId, limit: limit), from: this);

  @override
  String toString() => r'globalActivityProvider';
}

abstract class _$GlobalActivity extends $StreamNotifier<List<Activity>> {
  late final _$args = ref.$arg as (String?, {int limit});
  String? get clubId => _$args.$1;
  int get limit => _$args.limit;

  Stream<List<Activity>> build(String? clubId, {int limit = 50});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Activity>>, List<Activity>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Activity>>, List<Activity>>,
              AsyncValue<List<Activity>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, limit: _$args.limit));
  }
}
