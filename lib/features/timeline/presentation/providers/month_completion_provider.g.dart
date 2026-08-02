// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'month_completion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-day completion for the current month, derived from the habits stream
/// and the per-user Drift completion history. Empty map when signed out.

@ProviderFor(monthCompletion)
final monthCompletionProvider = MonthCompletionProvider._();

/// Per-day completion for the current month, derived from the habits stream
/// and the per-user Drift completion history. Empty map when signed out.

final class MonthCompletionProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, DayCompletion>>,
          Map<String, DayCompletion>,
          Stream<Map<String, DayCompletion>>
        >
    with
        $FutureModifier<Map<String, DayCompletion>>,
        $StreamProvider<Map<String, DayCompletion>> {
  /// Per-day completion for the current month, derived from the habits stream
  /// and the per-user Drift completion history. Empty map when signed out.
  MonthCompletionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthCompletionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthCompletionHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, DayCompletion>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, DayCompletion>> create(Ref ref) {
    return monthCompletion(ref);
  }
}

String _$monthCompletionHash() => r'c002ead6adec346db6f9a4298ca017e4f0fb42fa';
