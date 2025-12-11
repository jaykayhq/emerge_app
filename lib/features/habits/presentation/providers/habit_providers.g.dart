// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$habitRepositoryHash() => r'70914bf444ad8f23284fc561655c72d5ac1bdb32';

/// See also [habitRepository].
@ProviderFor(habitRepository)
final habitRepositoryProvider = Provider<HabitRepository>.internal(
  habitRepository,
  name: r'habitRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$habitRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HabitRepositoryRef = ProviderRef<HabitRepository>;
String _$habitsHash() => r'd1e3b6e2eab235d109b1076c82083a1de23f8447';

/// See also [habits].
@ProviderFor(habits)
final habitsProvider = AutoDisposeStreamProvider<List<Habit>>.internal(
  habits,
  name: r'habitsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$habitsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HabitsRef = AutoDisposeStreamProviderRef<List<Habit>>;
String _$createHabitHash() => r'272e5a04c2991012a8995ac4f351f59d79e0960c';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [createHabit].
@ProviderFor(createHabit)
const createHabitProvider = CreateHabitFamily();

/// See also [createHabit].
class CreateHabitFamily extends Family<AsyncValue<void>> {
  /// See also [createHabit].
  const CreateHabitFamily();

  /// See also [createHabit].
  CreateHabitProvider call(Habit habit) {
    return CreateHabitProvider(habit);
  }

  @override
  CreateHabitProvider getProviderOverride(
    covariant CreateHabitProvider provider,
  ) {
    return call(provider.habit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'createHabitProvider';
}

/// See also [createHabit].
class CreateHabitProvider extends AutoDisposeFutureProvider<void> {
  /// See also [createHabit].
  CreateHabitProvider(Habit habit)
    : this._internal(
        (ref) => createHabit(ref as CreateHabitRef, habit),
        from: createHabitProvider,
        name: r'createHabitProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$createHabitHash,
        dependencies: CreateHabitFamily._dependencies,
        allTransitiveDependencies: CreateHabitFamily._allTransitiveDependencies,
        habit: habit,
      );

  CreateHabitProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.habit,
  }) : super.internal();

  final Habit habit;

  @override
  Override overrideWith(
    FutureOr<void> Function(CreateHabitRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CreateHabitProvider._internal(
        (ref) => create(ref as CreateHabitRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        habit: habit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _CreateHabitProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CreateHabitProvider && other.habit == habit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, habit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CreateHabitRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `habit` of this provider.
  Habit get habit;
}

class _CreateHabitProviderElement extends AutoDisposeFutureProviderElement<void>
    with CreateHabitRef {
  _CreateHabitProviderElement(super.provider);

  @override
  Habit get habit => (origin as CreateHabitProvider).habit;
}

String _$completeHabitHash() => r'430050be6e8025a6cba05e27a1c162391398e070';

/// See also [completeHabit].
@ProviderFor(completeHabit)
const completeHabitProvider = CompleteHabitFamily();

/// See also [completeHabit].
class CompleteHabitFamily extends Family<AsyncValue<void>> {
  /// See also [completeHabit].
  const CompleteHabitFamily();

  /// See also [completeHabit].
  CompleteHabitProvider call(String habitId) {
    return CompleteHabitProvider(habitId);
  }

  @override
  CompleteHabitProvider getProviderOverride(
    covariant CompleteHabitProvider provider,
  ) {
    return call(provider.habitId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'completeHabitProvider';
}

/// See also [completeHabit].
class CompleteHabitProvider extends AutoDisposeFutureProvider<void> {
  /// See also [completeHabit].
  CompleteHabitProvider(String habitId)
    : this._internal(
        (ref) => completeHabit(ref as CompleteHabitRef, habitId),
        from: completeHabitProvider,
        name: r'completeHabitProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$completeHabitHash,
        dependencies: CompleteHabitFamily._dependencies,
        allTransitiveDependencies:
            CompleteHabitFamily._allTransitiveDependencies,
        habitId: habitId,
      );

  CompleteHabitProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.habitId,
  }) : super.internal();

  final String habitId;

  @override
  Override overrideWith(
    FutureOr<void> Function(CompleteHabitRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CompleteHabitProvider._internal(
        (ref) => create(ref as CompleteHabitRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        habitId: habitId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _CompleteHabitProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CompleteHabitProvider && other.habitId == habitId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, habitId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CompleteHabitRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `habitId` of this provider.
  String get habitId;
}

class _CompleteHabitProviderElement
    extends AutoDisposeFutureProviderElement<void>
    with CompleteHabitRef {
  _CompleteHabitProviderElement(super.provider);

  @override
  String get habitId => (origin as CompleteHabitProvider).habitId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
