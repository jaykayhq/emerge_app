// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Central Dashboard State Notifier
/// Orchestrates all state that affects the dashboard view

@ProviderFor(DashboardStateNotifier)
final dashboardStateProvider = DashboardStateNotifierProvider._();

/// Central Dashboard State Notifier
/// Orchestrates all state that affects the dashboard view
final class DashboardStateNotifierProvider
    extends $NotifierProvider<DashboardStateNotifier, DashboardState> {
  /// Central Dashboard State Notifier
  /// Orchestrates all state that affects the dashboard view
  DashboardStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardStateNotifierHash();

  @$internal
  @override
  DashboardStateNotifier create() => DashboardStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DashboardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DashboardState>(value),
    );
  }
}

String _$dashboardStateNotifierHash() =>
    r'1b9e97ce688b57f4ec1f562c47c9c42dc045bbbb';

/// Central Dashboard State Notifier
/// Orchestrates all state that affects the dashboard view

abstract class _$DashboardStateNotifier extends $Notifier<DashboardState> {
  DashboardState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DashboardState, DashboardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DashboardState, DashboardState>,
              DashboardState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for today's habits only (derived from dashboard state)

@ProviderFor(todaysHabits)
final todaysHabitsProvider = TodaysHabitsProvider._();

/// Provider for today's habits only (derived from dashboard state)

final class TodaysHabitsProvider
    extends $FunctionalProvider<List<Habit>, List<Habit>, List<Habit>>
    with $Provider<List<Habit>> {
  /// Provider for today's habits only (derived from dashboard state)
  TodaysHabitsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todaysHabitsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todaysHabitsHash();

  @$internal
  @override
  $ProviderElement<List<Habit>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Habit> create(Ref ref) {
    return todaysHabits(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Habit> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Habit>>(value),
    );
  }
}

String _$todaysHabitsHash() => r'80700c6896d2bdbd7ac191e70c714e21a240ad52';

/// Provider for today's completion rate

@ProviderFor(todayCompletionRate)
final todayCompletionRateProvider = TodayCompletionRateProvider._();

/// Provider for today's completion rate

final class TodayCompletionRateProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// Provider for today's completion rate
  TodayCompletionRateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayCompletionRateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayCompletionRateHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return todayCompletionRate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$todayCompletionRateHash() =>
    r'61eeee6ae732489303830704608452785a91ab39';

/// Provider to check if dashboard is loading

@ProviderFor(isDashboardLoading)
final isDashboardLoadingProvider = IsDashboardLoadingProvider._();

/// Provider to check if dashboard is loading

final class IsDashboardLoadingProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider to check if dashboard is loading
  IsDashboardLoadingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isDashboardLoadingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isDashboardLoadingHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isDashboardLoading(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isDashboardLoadingHash() =>
    r'e270eee14c54b4333413cf34ab4ae8ce26495756';

/// Provider for dashboard error

@ProviderFor(dashboardError)
final dashboardErrorProvider = DashboardErrorProvider._();

/// Provider for dashboard error

final class DashboardErrorProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Provider for dashboard error
  DashboardErrorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardErrorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardErrorHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return dashboardError(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$dashboardErrorHash() => r'd65107ed07d8c6b0ecfa7fd869896bac75002686';
