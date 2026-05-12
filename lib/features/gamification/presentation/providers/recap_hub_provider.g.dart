// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recap_hub_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(historicalRecaps)
final historicalRecapsProvider = HistoricalRecapsProvider._();

final class HistoricalRecapsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserWeeklyRecap>>,
          List<UserWeeklyRecap>,
          FutureOr<List<UserWeeklyRecap>>
        >
    with
        $FutureModifier<List<UserWeeklyRecap>>,
        $FutureProvider<List<UserWeeklyRecap>> {
  HistoricalRecapsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historicalRecapsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historicalRecapsHash();

  @$internal
  @override
  $FutureProviderElement<List<UserWeeklyRecap>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserWeeklyRecap>> create(Ref ref) {
    return historicalRecaps(ref);
  }
}

String _$historicalRecapsHash() => r'ee366c761c1e67a588c58bc4a240dd4b4b726e78';
