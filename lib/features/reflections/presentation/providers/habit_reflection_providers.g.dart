// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_reflection_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(habitReflectionLocalDatasource)
final habitReflectionLocalDatasourceProvider =
    HabitReflectionLocalDatasourceProvider._();

final class HabitReflectionLocalDatasourceProvider
    extends
        $FunctionalProvider<
          HabitReflectionLocalDatasource,
          HabitReflectionLocalDatasource,
          HabitReflectionLocalDatasource
        >
    with $Provider<HabitReflectionLocalDatasource> {
  HabitReflectionLocalDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitReflectionLocalDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitReflectionLocalDatasourceHash();

  @$internal
  @override
  $ProviderElement<HabitReflectionLocalDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HabitReflectionLocalDatasource create(Ref ref) {
    return habitReflectionLocalDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HabitReflectionLocalDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HabitReflectionLocalDatasource>(
        value,
      ),
    );
  }
}

String _$habitReflectionLocalDatasourceHash() =>
    r'82bbb066cb6f54c5be5ed52ada4cfa90cf158a66';

@ProviderFor(habitReflectionRemoteDatasource)
final habitReflectionRemoteDatasourceProvider =
    HabitReflectionRemoteDatasourceProvider._();

final class HabitReflectionRemoteDatasourceProvider
    extends
        $FunctionalProvider<
          HabitReflectionRemoteDatasource,
          HabitReflectionRemoteDatasource,
          HabitReflectionRemoteDatasource
        >
    with $Provider<HabitReflectionRemoteDatasource> {
  HabitReflectionRemoteDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitReflectionRemoteDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitReflectionRemoteDatasourceHash();

  @$internal
  @override
  $ProviderElement<HabitReflectionRemoteDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HabitReflectionRemoteDatasource create(Ref ref) {
    return habitReflectionRemoteDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HabitReflectionRemoteDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HabitReflectionRemoteDatasource>(
        value,
      ),
    );
  }
}

String _$habitReflectionRemoteDatasourceHash() =>
    r'f98502001edbe2e028eb00e2547e829666f2595f';

@ProviderFor(habitReflectionRepository)
final habitReflectionRepositoryProvider = HabitReflectionRepositoryProvider._();

final class HabitReflectionRepositoryProvider
    extends
        $FunctionalProvider<
          HabitReflectionRepository,
          HabitReflectionRepository,
          HabitReflectionRepository
        >
    with $Provider<HabitReflectionRepository> {
  HabitReflectionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitReflectionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitReflectionRepositoryHash();

  @$internal
  @override
  $ProviderElement<HabitReflectionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HabitReflectionRepository create(Ref ref) {
    return habitReflectionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HabitReflectionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HabitReflectionRepository>(value),
    );
  }
}

String _$habitReflectionRepositoryHash() =>
    r'4345689b61d9c30163e86a4c96d3e04dc8939560';

/// Loads the per-habit reflection for (userId, habitId, date). Returns null
/// if none exists.

@ProviderFor(habitReflection)
final habitReflectionProvider = HabitReflectionFamily._();

/// Loads the per-habit reflection for (userId, habitId, date). Returns null
/// if none exists.

final class HabitReflectionProvider
    extends
        $FunctionalProvider<
          AsyncValue<HabitReflection?>,
          HabitReflection?,
          FutureOr<HabitReflection?>
        >
    with $FutureModifier<HabitReflection?>, $FutureProvider<HabitReflection?> {
  /// Loads the per-habit reflection for (userId, habitId, date). Returns null
  /// if none exists.
  HabitReflectionProvider._({
    required HabitReflectionFamily super.from,
    required ({String userId, String habitId, DateTime date}) super.argument,
  }) : super(
         retry: null,
         name: r'habitReflectionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$habitReflectionHash();

  @override
  String toString() {
    return r'habitReflectionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<HabitReflection?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HabitReflection?> create(Ref ref) {
    final argument =
        this.argument as ({String userId, String habitId, DateTime date});
    return habitReflection(
      ref,
      userId: argument.userId,
      habitId: argument.habitId,
      date: argument.date,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HabitReflectionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$habitReflectionHash() => r'0f9d32e3f36949bfdc6534a464d0e87715457879';

/// Loads the per-habit reflection for (userId, habitId, date). Returns null
/// if none exists.

final class HabitReflectionFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<HabitReflection?>,
          ({String userId, String habitId, DateTime date})
        > {
  HabitReflectionFamily._()
    : super(
        retry: null,
        name: r'habitReflectionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads the per-habit reflection for (userId, habitId, date). Returns null
  /// if none exists.

  HabitReflectionProvider call({
    required String userId,
    required String habitId,
    required DateTime date,
  }) => HabitReflectionProvider._(
    argument: (userId: userId, habitId: habitId, date: date),
    from: this,
  );

  @override
  String toString() => r'habitReflectionProvider';
}

/// Saves a per-habit reflection and invalidates [habitReflection].

@ProviderFor(saveHabitReflection)
final saveHabitReflectionProvider = SaveHabitReflectionFamily._();

/// Saves a per-habit reflection and invalidates [habitReflection].

final class SaveHabitReflectionProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Saves a per-habit reflection and invalidates [habitReflection].
  SaveHabitReflectionProvider._({
    required SaveHabitReflectionFamily super.from,
    required ({
      String userId,
      String habitId,
      DateTime date,
      Mood mood,
      String note,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'saveHabitReflectionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$saveHabitReflectionHash();

  @override
  String toString() {
    return r'saveHabitReflectionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String userId,
              String habitId,
              DateTime date,
              Mood mood,
              String note,
            });
    return saveHabitReflection(
      ref,
      userId: argument.userId,
      habitId: argument.habitId,
      date: argument.date,
      mood: argument.mood,
      note: argument.note,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SaveHabitReflectionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$saveHabitReflectionHash() =>
    r'a46060bc7e859b65e6fa20d57a90e9965d4c9f44';

/// Saves a per-habit reflection and invalidates [habitReflection].

final class SaveHabitReflectionFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<void>,
          ({
            String userId,
            String habitId,
            DateTime date,
            Mood mood,
            String note,
          })
        > {
  SaveHabitReflectionFamily._()
    : super(
        retry: null,
        name: r'saveHabitReflectionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Saves a per-habit reflection and invalidates [habitReflection].

  SaveHabitReflectionProvider call({
    required String userId,
    required String habitId,
    required DateTime date,
    required Mood mood,
    required String note,
  }) => SaveHabitReflectionProvider._(
    argument: (
      userId: userId,
      habitId: habitId,
      date: date,
      mood: mood,
      note: note,
    ),
    from: this,
  );

  @override
  String toString() => r'saveHabitReflectionProvider';
}
