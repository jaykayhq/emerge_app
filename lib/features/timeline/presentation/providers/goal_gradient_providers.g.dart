// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_gradient_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 0.0–1.0 fraction of today's habits already completed.
/// Drives the FAB completion ring and the recap arc.

@ProviderFor(completionFraction)
final completionFractionProvider = CompletionFractionProvider._();

/// 0.0–1.0 fraction of today's habits already completed.
/// Drives the FAB completion ring and the recap arc.

final class CompletionFractionProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// 0.0–1.0 fraction of today's habits already completed.
  /// Drives the FAB completion ring and the recap arc.
  CompletionFractionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'completionFractionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$completionFractionHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return completionFraction(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$completionFractionHash() =>
    r'092b21f24d679c65b5e4e1d196891eaffbf9a4f6';

/// Count of today's habits not yet completed.
/// Drives the Timeline-tab badge.

@ProviderFor(incompleteCount)
final incompleteCountProvider = IncompleteCountProvider._();

/// Count of today's habits not yet completed.
/// Drives the Timeline-tab badge.

final class IncompleteCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Count of today's habits not yet completed.
  /// Drives the Timeline-tab badge.
  IncompleteCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'incompleteCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$incompleteCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return incompleteCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$incompleteCountHash() => r'b2dcd47d0067fdc61866c04bfe071c3389befe57';
