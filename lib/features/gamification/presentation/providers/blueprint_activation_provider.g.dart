// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blueprint_activation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Blueprint Activation Notifier
/// Handles the flow of selecting and activating blueprints
/// which creates habits and syncs to dashboard

@ProviderFor(BlueprintActivationNotifier)
final blueprintActivationProvider = BlueprintActivationNotifierProvider._();

/// Blueprint Activation Notifier
/// Handles the flow of selecting and activating blueprints
/// which creates habits and syncs to dashboard
final class BlueprintActivationNotifierProvider
    extends
        $NotifierProvider<
          BlueprintActivationNotifier,
          BlueprintActivationState
        > {
  /// Blueprint Activation Notifier
  /// Handles the flow of selecting and activating blueprints
  /// which creates habits and syncs to dashboard
  BlueprintActivationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blueprintActivationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blueprintActivationNotifierHash();

  @$internal
  @override
  BlueprintActivationNotifier create() => BlueprintActivationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BlueprintActivationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BlueprintActivationState>(value),
    );
  }
}

String _$blueprintActivationNotifierHash() =>
    r'483e6bd5bb130be085d5957ac9dfa13d21ea8a3e';

/// Blueprint Activation Notifier
/// Handles the flow of selecting and activating blueprints
/// which creates habits and syncs to dashboard

abstract class _$BlueprintActivationNotifier
    extends $Notifier<BlueprintActivationState> {
  BlueprintActivationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<BlueprintActivationState, BlueprintActivationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BlueprintActivationState, BlueprintActivationState>,
              BlueprintActivationState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for blueprint categories

@ProviderFor(blueprintCategories)
final blueprintCategoriesProvider = BlueprintCategoriesProvider._();

/// Provider for blueprint categories

final class BlueprintCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// Provider for blueprint categories
  BlueprintCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blueprintCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blueprintCategoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return blueprintCategories(ref);
  }
}

String _$blueprintCategoriesHash() =>
    r'0f10979fdcef504f0d1860a6d979f9104ba78513';

/// Provider for blueprints by category with caching

@ProviderFor(blueprintsByCategory)
final blueprintsByCategoryProvider = BlueprintsByCategoryFamily._();

/// Provider for blueprints by category with caching

final class BlueprintsByCategoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Blueprint>>,
          List<Blueprint>,
          FutureOr<List<Blueprint>>
        >
    with $FutureModifier<List<Blueprint>>, $FutureProvider<List<Blueprint>> {
  /// Provider for blueprints by category with caching
  BlueprintsByCategoryProvider._({
    required BlueprintsByCategoryFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'blueprintsByCategoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$blueprintsByCategoryHash();

  @override
  String toString() {
    return r'blueprintsByCategoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Blueprint>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Blueprint>> create(Ref ref) {
    final argument = this.argument as String?;
    return blueprintsByCategory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BlueprintsByCategoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$blueprintsByCategoryHash() =>
    r'4529334b622c4215dcfe62debf0da1fead8385d0';

/// Provider for blueprints by category with caching

final class BlueprintsByCategoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Blueprint>>, String?> {
  BlueprintsByCategoryFamily._()
    : super(
        retry: null,
        name: r'blueprintsByCategoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for blueprints by category with caching

  BlueprintsByCategoryProvider call(String? category) =>
      BlueprintsByCategoryProvider._(argument: category, from: this);

  @override
  String toString() => r'blueprintsByCategoryProvider';
}

/// Provider for featured blueprints (first 3 from each category)

@ProviderFor(featuredBlueprints)
final featuredBlueprintsProvider = FeaturedBlueprintsProvider._();

/// Provider for featured blueprints (first 3 from each category)

final class FeaturedBlueprintsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Blueprint>>,
          List<Blueprint>,
          FutureOr<List<Blueprint>>
        >
    with $FutureModifier<List<Blueprint>>, $FutureProvider<List<Blueprint>> {
  /// Provider for featured blueprints (first 3 from each category)
  FeaturedBlueprintsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featuredBlueprintsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featuredBlueprintsHash();

  @$internal
  @override
  $FutureProviderElement<List<Blueprint>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Blueprint>> create(Ref ref) {
    return featuredBlueprints(ref);
  }
}

String _$featuredBlueprintsHash() =>
    r'c8d887ab2d14e43ecdd97f0171ca5f7a0b393d0c';

/// Provider to check if a blueprint is already activated

@ProviderFor(isBlueprintActivated)
final isBlueprintActivatedProvider = IsBlueprintActivatedFamily._();

/// Provider to check if a blueprint is already activated

final class IsBlueprintActivatedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider to check if a blueprint is already activated
  IsBlueprintActivatedProvider._({
    required IsBlueprintActivatedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isBlueprintActivatedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isBlueprintActivatedHash();

  @override
  String toString() {
    return r'isBlueprintActivatedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isBlueprintActivated(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsBlueprintActivatedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isBlueprintActivatedHash() =>
    r'618db4ffb5a8ab8f3453b08b5f687ab2fe6e9ac4';

/// Provider to check if a blueprint is already activated

final class IsBlueprintActivatedFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsBlueprintActivatedFamily._()
    : super(
        retry: null,
        name: r'isBlueprintActivatedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to check if a blueprint is already activated

  IsBlueprintActivatedProvider call(String blueprintId) =>
      IsBlueprintActivatedProvider._(argument: blueprintId, from: this);

  @override
  String toString() => r'isBlueprintActivatedProvider';
}

/// Provider for activation loading state

@ProviderFor(isBlueprintActivating)
final isBlueprintActivatingProvider = IsBlueprintActivatingProvider._();

/// Provider for activation loading state

final class IsBlueprintActivatingProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider for activation loading state
  IsBlueprintActivatingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isBlueprintActivatingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isBlueprintActivatingHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isBlueprintActivating(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isBlueprintActivatingHash() =>
    r'ee047d9c080abd6b4e6eeb7e5fb364c07796ac26';
