// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_recommendations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live recommendations for the create screen's title field. Re-evaluates as
/// the user types (auto-dispose family keyed by the current term).

@ProviderFor(habitRecommendations)
final habitRecommendationsProvider = HabitRecommendationsFamily._();

/// Live recommendations for the create screen's title field. Re-evaluates as
/// the user types (auto-dispose family keyed by the current term).

final class HabitRecommendationsProvider
    extends
        $FunctionalProvider<
          List<HabitRecommendation>,
          List<HabitRecommendation>,
          List<HabitRecommendation>
        >
    with $Provider<List<HabitRecommendation>> {
  /// Live recommendations for the create screen's title field. Re-evaluates as
  /// the user types (auto-dispose family keyed by the current term).
  HabitRecommendationsProvider._({
    required HabitRecommendationsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'habitRecommendationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$habitRecommendationsHash();

  @override
  String toString() {
    return r'habitRecommendationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<HabitRecommendation>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<HabitRecommendation> create(Ref ref) {
    final argument = this.argument as String;
    return habitRecommendations(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<HabitRecommendation> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<HabitRecommendation>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HabitRecommendationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$habitRecommendationsHash() =>
    r'd86d149ac62f0d95748cb0908a514687f867c9aa';

/// Live recommendations for the create screen's title field. Re-evaluates as
/// the user types (auto-dispose family keyed by the current term).

final class HabitRecommendationsFamily extends $Family
    with $FunctionalFamilyOverride<List<HabitRecommendation>, String> {
  HabitRecommendationsFamily._()
    : super(
        retry: null,
        name: r'habitRecommendationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live recommendations for the create screen's title field. Re-evaluates as
  /// the user types (auto-dispose family keyed by the current term).

  HabitRecommendationsProvider call(String term) =>
      HabitRecommendationsProvider._(argument: term, from: this);

  @override
  String toString() => r'habitRecommendationsProvider';
}
