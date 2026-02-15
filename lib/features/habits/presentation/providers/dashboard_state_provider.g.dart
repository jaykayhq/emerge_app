// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$todaysHabitsHash() => r'80700c6896d2bdbd7ac191e70c714e21a240ad52';

/// Provider for today's habits only (derived from dashboard state)
///
/// Copied from [todaysHabits].
@ProviderFor(todaysHabits)
final todaysHabitsProvider = AutoDisposeProvider<List<Habit>>.internal(
  todaysHabits,
  name: r'todaysHabitsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todaysHabitsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TodaysHabitsRef = AutoDisposeProviderRef<List<Habit>>;
String _$todayCompletionRateHash() =>
    r'61eeee6ae732489303830704608452785a91ab39';

/// Provider for today's completion rate
///
/// Copied from [todayCompletionRate].
@ProviderFor(todayCompletionRate)
final todayCompletionRateProvider = AutoDisposeProvider<double>.internal(
  todayCompletionRate,
  name: r'todayCompletionRateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todayCompletionRateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TodayCompletionRateRef = AutoDisposeProviderRef<double>;
String _$isDashboardLoadingHash() =>
    r'e270eee14c54b4333413cf34ab4ae8ce26495756';

/// Provider to check if dashboard is loading
///
/// Copied from [isDashboardLoading].
@ProviderFor(isDashboardLoading)
final isDashboardLoadingProvider = AutoDisposeProvider<bool>.internal(
  isDashboardLoading,
  name: r'isDashboardLoadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isDashboardLoadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsDashboardLoadingRef = AutoDisposeProviderRef<bool>;
String _$dashboardErrorHash() => r'd65107ed07d8c6b0ecfa7fd869896bac75002686';

/// Provider for dashboard error
///
/// Copied from [dashboardError].
@ProviderFor(dashboardError)
final dashboardErrorProvider = AutoDisposeProvider<String?>.internal(
  dashboardError,
  name: r'dashboardErrorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dashboardErrorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DashboardErrorRef = AutoDisposeProviderRef<String?>;
String _$dashboardStateNotifierHash() =>
    r'c736a8d9538c10c79dfb4ff0bb053382bbc8fcdd';

/// Central Dashboard State Notifier
/// Orchestrates all state that affects the dashboard view
///
/// Copied from [DashboardStateNotifier].
@ProviderFor(DashboardStateNotifier)
final dashboardStateNotifierProvider =
    NotifierProvider<DashboardStateNotifier, DashboardState>.internal(
      DashboardStateNotifier.new,
      name: r'dashboardStateNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dashboardStateNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DashboardStateNotifier = Notifier<DashboardState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
