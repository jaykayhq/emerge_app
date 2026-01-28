// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blueprint_activation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$blueprintCategoriesHash() =>
    r'0f10979fdcef504f0d1860a6d979f9104ba78513';

/// Provider for blueprint categories
///
/// Copied from [blueprintCategories].
@ProviderFor(blueprintCategories)
final blueprintCategoriesProvider =
    AutoDisposeFutureProvider<List<String>>.internal(
      blueprintCategories,
      name: r'blueprintCategoriesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$blueprintCategoriesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BlueprintCategoriesRef = AutoDisposeFutureProviderRef<List<String>>;
String _$blueprintsByCategoryHash() =>
    r'4529334b622c4215dcfe62debf0da1fead8385d0';

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

/// Provider for blueprints by category with caching
///
/// Copied from [blueprintsByCategory].
@ProviderFor(blueprintsByCategory)
const blueprintsByCategoryProvider = BlueprintsByCategoryFamily();

/// Provider for blueprints by category with caching
///
/// Copied from [blueprintsByCategory].
class BlueprintsByCategoryFamily extends Family<AsyncValue<List<Blueprint>>> {
  /// Provider for blueprints by category with caching
  ///
  /// Copied from [blueprintsByCategory].
  const BlueprintsByCategoryFamily();

  /// Provider for blueprints by category with caching
  ///
  /// Copied from [blueprintsByCategory].
  BlueprintsByCategoryProvider call(String? category) {
    return BlueprintsByCategoryProvider(category);
  }

  @override
  BlueprintsByCategoryProvider getProviderOverride(
    covariant BlueprintsByCategoryProvider provider,
  ) {
    return call(provider.category);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'blueprintsByCategoryProvider';
}

/// Provider for blueprints by category with caching
///
/// Copied from [blueprintsByCategory].
class BlueprintsByCategoryProvider
    extends AutoDisposeFutureProvider<List<Blueprint>> {
  /// Provider for blueprints by category with caching
  ///
  /// Copied from [blueprintsByCategory].
  BlueprintsByCategoryProvider(String? category)
    : this._internal(
        (ref) => blueprintsByCategory(ref as BlueprintsByCategoryRef, category),
        from: blueprintsByCategoryProvider,
        name: r'blueprintsByCategoryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$blueprintsByCategoryHash,
        dependencies: BlueprintsByCategoryFamily._dependencies,
        allTransitiveDependencies:
            BlueprintsByCategoryFamily._allTransitiveDependencies,
        category: category,
      );

  BlueprintsByCategoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.category,
  }) : super.internal();

  final String? category;

  @override
  Override overrideWith(
    FutureOr<List<Blueprint>> Function(BlueprintsByCategoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BlueprintsByCategoryProvider._internal(
        (ref) => create(ref as BlueprintsByCategoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        category: category,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Blueprint>> createElement() {
    return _BlueprintsByCategoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BlueprintsByCategoryProvider && other.category == category;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BlueprintsByCategoryRef on AutoDisposeFutureProviderRef<List<Blueprint>> {
  /// The parameter `category` of this provider.
  String? get category;
}

class _BlueprintsByCategoryProviderElement
    extends AutoDisposeFutureProviderElement<List<Blueprint>>
    with BlueprintsByCategoryRef {
  _BlueprintsByCategoryProviderElement(super.provider);

  @override
  String? get category => (origin as BlueprintsByCategoryProvider).category;
}

String _$featuredBlueprintsHash() =>
    r'c8d887ab2d14e43ecdd97f0171ca5f7a0b393d0c';

/// Provider for featured blueprints (first 3 from each category)
///
/// Copied from [featuredBlueprints].
@ProviderFor(featuredBlueprints)
final featuredBlueprintsProvider =
    AutoDisposeFutureProvider<List<Blueprint>>.internal(
      featuredBlueprints,
      name: r'featuredBlueprintsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$featuredBlueprintsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeaturedBlueprintsRef = AutoDisposeFutureProviderRef<List<Blueprint>>;
String _$isBlueprintActivatedHash() =>
    r'86a7fd75cca332a245b77e59180ce0891e9d7544';

/// Provider to check if a blueprint is already activated
///
/// Copied from [isBlueprintActivated].
@ProviderFor(isBlueprintActivated)
const isBlueprintActivatedProvider = IsBlueprintActivatedFamily();

/// Provider to check if a blueprint is already activated
///
/// Copied from [isBlueprintActivated].
class IsBlueprintActivatedFamily extends Family<bool> {
  /// Provider to check if a blueprint is already activated
  ///
  /// Copied from [isBlueprintActivated].
  const IsBlueprintActivatedFamily();

  /// Provider to check if a blueprint is already activated
  ///
  /// Copied from [isBlueprintActivated].
  IsBlueprintActivatedProvider call(String blueprintId) {
    return IsBlueprintActivatedProvider(blueprintId);
  }

  @override
  IsBlueprintActivatedProvider getProviderOverride(
    covariant IsBlueprintActivatedProvider provider,
  ) {
    return call(provider.blueprintId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isBlueprintActivatedProvider';
}

/// Provider to check if a blueprint is already activated
///
/// Copied from [isBlueprintActivated].
class IsBlueprintActivatedProvider extends AutoDisposeProvider<bool> {
  /// Provider to check if a blueprint is already activated
  ///
  /// Copied from [isBlueprintActivated].
  IsBlueprintActivatedProvider(String blueprintId)
    : this._internal(
        (ref) =>
            isBlueprintActivated(ref as IsBlueprintActivatedRef, blueprintId),
        from: isBlueprintActivatedProvider,
        name: r'isBlueprintActivatedProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$isBlueprintActivatedHash,
        dependencies: IsBlueprintActivatedFamily._dependencies,
        allTransitiveDependencies:
            IsBlueprintActivatedFamily._allTransitiveDependencies,
        blueprintId: blueprintId,
      );

  IsBlueprintActivatedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.blueprintId,
  }) : super.internal();

  final String blueprintId;

  @override
  Override overrideWith(
    bool Function(IsBlueprintActivatedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsBlueprintActivatedProvider._internal(
        (ref) => create(ref as IsBlueprintActivatedRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        blueprintId: blueprintId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsBlueprintActivatedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsBlueprintActivatedProvider &&
        other.blueprintId == blueprintId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, blueprintId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsBlueprintActivatedRef on AutoDisposeProviderRef<bool> {
  /// The parameter `blueprintId` of this provider.
  String get blueprintId;
}

class _IsBlueprintActivatedProviderElement
    extends AutoDisposeProviderElement<bool>
    with IsBlueprintActivatedRef {
  _IsBlueprintActivatedProviderElement(super.provider);

  @override
  String get blueprintId =>
      (origin as IsBlueprintActivatedProvider).blueprintId;
}

String _$isBlueprintActivatingHash() =>
    r'3fbde00e75deec24e2ecc3ac0e08b77755434144';

/// Provider for activation loading state
///
/// Copied from [isBlueprintActivating].
@ProviderFor(isBlueprintActivating)
final isBlueprintActivatingProvider = AutoDisposeProvider<bool>.internal(
  isBlueprintActivating,
  name: r'isBlueprintActivatingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isBlueprintActivatingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsBlueprintActivatingRef = AutoDisposeProviderRef<bool>;
String _$blueprintActivationNotifierHash() =>
    r'2cbd51e4f310cdb50833b10e4e6b3d1ab42079ab';

/// Blueprint Activation Notifier
/// Handles the flow of selecting and activating blueprints
/// which creates habits and syncs to dashboard
///
/// Copied from [BlueprintActivationNotifier].
@ProviderFor(BlueprintActivationNotifier)
final blueprintActivationNotifierProvider =
    NotifierProvider<
      BlueprintActivationNotifier,
      BlueprintActivationState
    >.internal(
      BlueprintActivationNotifier.new,
      name: r'blueprintActivationNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$blueprintActivationNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BlueprintActivationNotifier = Notifier<BlueprintActivationState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
