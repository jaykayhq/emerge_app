// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attribute_progress_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider that calculates attribute progress from actual avatarStats
///
/// This provider reads the real XP values from the user's avatarStats
/// and calculates how much each attribute contributes to the overall level.

@ProviderFor(attributeProgressFromHabits)
final attributeProgressFromHabitsProvider =
    AttributeProgressFromHabitsProvider._();

/// Provider that calculates attribute progress from actual avatarStats
///
/// This provider reads the real XP values from the user's avatarStats
/// and calculates how much each attribute contributes to the overall level.

final class AttributeProgressFromHabitsProvider
    extends
        $FunctionalProvider<
          Map<String, AttributeProgress>,
          Map<String, AttributeProgress>,
          Map<String, AttributeProgress>
        >
    with $Provider<Map<String, AttributeProgress>> {
  /// Provider that calculates attribute progress from actual avatarStats
  ///
  /// This provider reads the real XP values from the user's avatarStats
  /// and calculates how much each attribute contributes to the overall level.
  AttributeProgressFromHabitsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attributeProgressFromHabitsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attributeProgressFromHabitsHash();

  @$internal
  @override
  $ProviderElement<Map<String, AttributeProgress>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, AttributeProgress> create(Ref ref) {
    return attributeProgressFromHabits(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, AttributeProgress> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, AttributeProgress>>(
        value,
      ),
    );
  }
}

String _$attributeProgressFromHabitsHash() =>
    r'b174224e856299b1aeace7ae97cfb333b55a904a';

/// Provider for a specific attribute's progress

@ProviderFor(attributeProgress)
final attributeProgressProvider = AttributeProgressFamily._();

/// Provider for a specific attribute's progress

final class AttributeProgressProvider
    extends
        $FunctionalProvider<
          AttributeProgress?,
          AttributeProgress?,
          AttributeProgress?
        >
    with $Provider<AttributeProgress?> {
  /// Provider for a specific attribute's progress
  AttributeProgressProvider._({
    required AttributeProgressFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'attributeProgressProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$attributeProgressHash();

  @override
  String toString() {
    return r'attributeProgressProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AttributeProgress?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AttributeProgress? create(Ref ref) {
    final argument = this.argument as String;
    return attributeProgress(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttributeProgress? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AttributeProgress?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AttributeProgressProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$attributeProgressHash() => r'bdf1d8a1bd0933a72ba696ac2e5f276639dd9ed9';

/// Provider for a specific attribute's progress

final class AttributeProgressFamily extends $Family
    with $FunctionalFamilyOverride<AttributeProgress?, String> {
  AttributeProgressFamily._()
    : super(
        retry: null,
        name: r'attributeProgressProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for a specific attribute's progress

  AttributeProgressProvider call(String attribute) =>
      AttributeProgressProvider._(argument: attribute, from: this);

  @override
  String toString() => r'attributeProgressProvider';
}
