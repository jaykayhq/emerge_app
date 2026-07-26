// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_habit_completed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Emits `true` on the frame where today's last habit is completed, then
/// resets to `false`. Timeline watches this to fire the all-done celebration.
///
/// Keeps its own memory of the previous completed count so the pure
/// [isLastHabitJustCompleted] can detect the (total-1 -> total) edge.

@ProviderFor(LastHabitCompleted)
final lastHabitCompletedProvider = LastHabitCompletedProvider._();

/// Emits `true` on the frame where today's last habit is completed, then
/// resets to `false`. Timeline watches this to fire the all-done celebration.
///
/// Keeps its own memory of the previous completed count so the pure
/// [isLastHabitJustCompleted] can detect the (total-1 -> total) edge.
final class LastHabitCompletedProvider
    extends $NotifierProvider<LastHabitCompleted, bool> {
  /// Emits `true` on the frame where today's last habit is completed, then
  /// resets to `false`. Timeline watches this to fire the all-done celebration.
  ///
  /// Keeps its own memory of the previous completed count so the pure
  /// [isLastHabitJustCompleted] can detect the (total-1 -> total) edge.
  LastHabitCompletedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastHabitCompletedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastHabitCompletedHash();

  @$internal
  @override
  LastHabitCompleted create() => LastHabitCompleted();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$lastHabitCompletedHash() =>
    r'6fc6dad847b47a7337b247047dfc497a12439c3a';

/// Emits `true` on the frame where today's last habit is completed, then
/// resets to `false`. Timeline watches this to fire the all-done celebration.
///
/// Keeps its own memory of the previous completed count so the pure
/// [isLastHabitJustCompleted] can detect the (total-1 -> total) edge.

abstract class _$LastHabitCompleted extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
