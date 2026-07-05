// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reflection_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reflectionLocalDatasource)
final reflectionLocalDatasourceProvider = ReflectionLocalDatasourceProvider._();

final class ReflectionLocalDatasourceProvider
    extends
        $FunctionalProvider<
          ReflectionLocalDatasource,
          ReflectionLocalDatasource,
          ReflectionLocalDatasource
        >
    with $Provider<ReflectionLocalDatasource> {
  ReflectionLocalDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reflectionLocalDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reflectionLocalDatasourceHash();

  @$internal
  @override
  $ProviderElement<ReflectionLocalDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReflectionLocalDatasource create(Ref ref) {
    return reflectionLocalDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReflectionLocalDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReflectionLocalDatasource>(value),
    );
  }
}

String _$reflectionLocalDatasourceHash() =>
    r'c0e8c52bcc432298e037cbba12efc78a4ab9f307';

@ProviderFor(reflectionRemoteDatasource)
final reflectionRemoteDatasourceProvider =
    ReflectionRemoteDatasourceProvider._();

final class ReflectionRemoteDatasourceProvider
    extends
        $FunctionalProvider<
          ReflectionRemoteDatasource,
          ReflectionRemoteDatasource,
          ReflectionRemoteDatasource
        >
    with $Provider<ReflectionRemoteDatasource> {
  ReflectionRemoteDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reflectionRemoteDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reflectionRemoteDatasourceHash();

  @$internal
  @override
  $ProviderElement<ReflectionRemoteDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReflectionRemoteDatasource create(Ref ref) {
    return reflectionRemoteDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReflectionRemoteDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReflectionRemoteDatasource>(value),
    );
  }
}

String _$reflectionRemoteDatasourceHash() =>
    r'a7118e4cca148f2a09da32bcdbf9bfa67318c32c';

@ProviderFor(reflectionRepository)
final reflectionRepositoryProvider = ReflectionRepositoryProvider._();

final class ReflectionRepositoryProvider
    extends
        $FunctionalProvider<
          ReflectionRepository,
          ReflectionRepository,
          ReflectionRepository
        >
    with $Provider<ReflectionRepository> {
  ReflectionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reflectionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reflectionRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReflectionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReflectionRepository create(Ref ref) {
    return reflectionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReflectionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReflectionRepository>(value),
    );
  }
}

String _$reflectionRepositoryHash() =>
    r'a8dddd4d2041f6b9d12cf19768b3173c74b1c5de';

/// Loads the reflection for [date] (default = today). Returns null if none.

@ProviderFor(dailyReflection)
final dailyReflectionProvider = DailyReflectionFamily._();

/// Loads the reflection for [date] (default = today). Returns null if none.

final class DailyReflectionProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyReflection?>,
          DailyReflection?,
          FutureOr<DailyReflection?>
        >
    with $FutureModifier<DailyReflection?>, $FutureProvider<DailyReflection?> {
  /// Loads the reflection for [date] (default = today). Returns null if none.
  DailyReflectionProvider._({
    required DailyReflectionFamily super.from,
    required ({String userId, DateTime date}) super.argument,
  }) : super(
         retry: null,
         name: r'dailyReflectionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dailyReflectionHash();

  @override
  String toString() {
    return r'dailyReflectionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<DailyReflection?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DailyReflection?> create(Ref ref) {
    final argument = this.argument as ({String userId, DateTime date});
    return dailyReflection(ref, userId: argument.userId, date: argument.date);
  }

  @override
  bool operator ==(Object other) {
    return other is DailyReflectionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dailyReflectionHash() => r'3aa6c6e8f3ec7687a220caf8bbc8e1d942c2e52d';

/// Loads the reflection for [date] (default = today). Returns null if none.

final class DailyReflectionFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<DailyReflection?>,
          ({String userId, DateTime date})
        > {
  DailyReflectionFamily._()
    : super(
        retry: null,
        name: r'dailyReflectionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads the reflection for [date] (default = today). Returns null if none.

  DailyReflectionProvider call({
    required String userId,
    required DateTime date,
  }) => DailyReflectionProvider._(
    argument: (userId: userId, date: date),
    from: this,
  );

  @override
  String toString() => r'dailyReflectionProvider';
}
