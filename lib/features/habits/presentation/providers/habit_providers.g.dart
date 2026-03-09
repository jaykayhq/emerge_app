// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(habitRepository)
final habitRepositoryProvider = HabitRepositoryProvider._();

final class HabitRepositoryProvider
    extends
        $FunctionalProvider<HabitRepository, HabitRepository, HabitRepository>
    with $Provider<HabitRepository> {
  HabitRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitRepositoryHash();

  @$internal
  @override
  $ProviderElement<HabitRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HabitRepository create(Ref ref) {
    return habitRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HabitRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HabitRepository>(value),
    );
  }
}

String _$habitRepositoryHash() => r'fea1b92e8a45053d693b3f0381be6f76fb207b90';

@ProviderFor(habits)
final habitsProvider = HabitsProvider._();

final class HabitsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Habit>>,
          List<Habit>,
          Stream<List<Habit>>
        >
    with $FutureModifier<List<Habit>>, $StreamProvider<List<Habit>> {
  HabitsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitsHash();

  @$internal
  @override
  $StreamProviderElement<List<Habit>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Habit>> create(Ref ref) {
    return habits(ref);
  }
}

String _$habitsHash() => r'aacd2426f67145a362ccdcfa5c0dad89eea21a6b';

@ProviderFor(createHabit)
final createHabitProvider = CreateHabitFamily._();

final class CreateHabitProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  CreateHabitProvider._({
    required CreateHabitFamily super.from,
    required Habit super.argument,
  }) : super(
         retry: null,
         name: r'createHabitProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$createHabitHash();

  @override
  String toString() {
    return r'createHabitProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as Habit;
    return createHabit(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CreateHabitProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$createHabitHash() => r'a980185897c45e6a7013d5228da62618c03ffd0e';

final class CreateHabitFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, Habit> {
  CreateHabitFamily._()
    : super(
        retry: null,
        name: r'createHabitProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CreateHabitProvider call(Habit habit) =>
      CreateHabitProvider._(argument: habit, from: this);

  @override
  String toString() => r'createHabitProvider';
}

@ProviderFor(completeHabit)
final completeHabitProvider = CompleteHabitFamily._();

final class CompleteHabitProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  CompleteHabitProvider._({
    required CompleteHabitFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'completeHabitProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$completeHabitHash();

  @override
  String toString() {
    return r'completeHabitProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return completeHabit(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CompleteHabitProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$completeHabitHash() => r'f36d3bba810f7442928d60e7eec0a9b9d16e2e1d';

final class CompleteHabitFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  CompleteHabitFamily._()
    : super(
        retry: null,
        name: r'completeHabitProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CompleteHabitProvider call(String habitId) =>
      CompleteHabitProvider._(argument: habitId, from: this);

  @override
  String toString() => r'completeHabitProvider';
}

@ProviderFor(habitActivity)
final habitActivityProvider = HabitActivityFamily._();

final class HabitActivityProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HabitActivity>>,
          List<HabitActivity>,
          FutureOr<List<HabitActivity>>
        >
    with
        $FutureModifier<List<HabitActivity>>,
        $FutureProvider<List<HabitActivity>> {
  HabitActivityProvider._({
    required HabitActivityFamily super.from,
    required ({DateTime start, DateTime end}) super.argument,
  }) : super(
         retry: null,
         name: r'habitActivityProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$habitActivityHash();

  @override
  String toString() {
    return r'habitActivityProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<HabitActivity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HabitActivity>> create(Ref ref) {
    final argument = this.argument as ({DateTime start, DateTime end});
    return habitActivity(ref, start: argument.start, end: argument.end);
  }

  @override
  bool operator ==(Object other) {
    return other is HabitActivityProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$habitActivityHash() => r'a3a0cb90b290befbf5d6cb2bf715b7d1b98c1beb';

final class HabitActivityFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<HabitActivity>>,
          ({DateTime start, DateTime end})
        > {
  HabitActivityFamily._()
    : super(
        retry: null,
        name: r'habitActivityProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HabitActivityProvider call({
    required DateTime start,
    required DateTime end,
  }) => HabitActivityProvider._(argument: (start: start, end: end), from: this);

  @override
  String toString() => r'habitActivityProvider';
}
