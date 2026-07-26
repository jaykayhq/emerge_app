// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_suggestions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Habit title suggestions, sorted by relevance:
/// 1. Habits the user has already created (anchoring/endowment)
/// 2. Archetype-matched suggestions
/// 3. Curated fallback
///
/// Auto-disposes when no longer watched.

@ProviderFor(habitSuggestions)
final habitSuggestionsProvider = HabitSuggestionsProvider._();

/// Habit title suggestions, sorted by relevance:
/// 1. Habits the user has already created (anchoring/endowment)
/// 2. Archetype-matched suggestions
/// 3. Curated fallback
///
/// Auto-disposes when no longer watched.

final class HabitSuggestionsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// Habit title suggestions, sorted by relevance:
  /// 1. Habits the user has already created (anchoring/endowment)
  /// 2. Archetype-matched suggestions
  /// 3. Curated fallback
  ///
  /// Auto-disposes when no longer watched.
  HabitSuggestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitSuggestionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitSuggestionsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return habitSuggestions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$habitSuggestionsHash() => r'3393d60bb6c603563c11d93df15c1e70371f5d56';
