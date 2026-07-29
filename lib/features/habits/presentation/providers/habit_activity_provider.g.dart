// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_activity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads activity data for a single habit: heatmap, stats, and reflections.

@ProviderFor(habitActivityData)
final habitActivityDataProvider = HabitActivityDataFamily._();

/// Loads activity data for a single habit: heatmap, stats, and reflections.

final class HabitActivityDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<HabitActivityData>,
          HabitActivityData,
          FutureOr<HabitActivityData>
        >
    with
        $FutureModifier<HabitActivityData>,
        $FutureProvider<HabitActivityData> {
  /// Loads activity data for a single habit: heatmap, stats, and reflections.
  HabitActivityDataProvider._({
    required HabitActivityDataFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'habitActivityDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$habitActivityDataHash();

  @override
  String toString() {
    return r'habitActivityDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<HabitActivityData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HabitActivityData> create(Ref ref) {
    final argument = this.argument as String;
    return habitActivityData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HabitActivityDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$habitActivityDataHash() => r'ee9ec80c900b99a74c2b8881404ffbc442192fb0';

/// Loads activity data for a single habit: heatmap, stats, and reflections.

final class HabitActivityDataFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<HabitActivityData>, String> {
  HabitActivityDataFamily._()
    : super(
        retry: null,
        name: r'habitActivityDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads activity data for a single habit: heatmap, stats, and reflections.

  HabitActivityDataProvider call(String habitId) =>
      HabitActivityDataProvider._(argument: habitId, from: this);

  @override
  String toString() => r'habitActivityDataProvider';
}
