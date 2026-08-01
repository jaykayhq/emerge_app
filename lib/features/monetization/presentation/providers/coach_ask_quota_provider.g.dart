// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_ask_quota_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Daily coach-ask quota controller.
///
/// Persists the free-tier counter in shared_prefs under
/// `coach_asks_<yyyy-MM-dd>`; the pure [CoachAskQuota] handles rollover and
/// the premium bypass. Storage failure defaults to 0 used — never hard-block
/// a user because storage hiccuped.

@ProviderFor(CoachAskQuotaController)
final coachAskQuotaControllerProvider = CoachAskQuotaControllerProvider._();

/// Daily coach-ask quota controller.
///
/// Persists the free-tier counter in shared_prefs under
/// `coach_asks_<yyyy-MM-dd>`; the pure [CoachAskQuota] handles rollover and
/// the premium bypass. Storage failure defaults to 0 used — never hard-block
/// a user because storage hiccuped.
final class CoachAskQuotaControllerProvider
    extends $AsyncNotifierProvider<CoachAskQuotaController, CoachAskQuota> {
  /// Daily coach-ask quota controller.
  ///
  /// Persists the free-tier counter in shared_prefs under
  /// `coach_asks_<yyyy-MM-dd>`; the pure [CoachAskQuota] handles rollover and
  /// the premium bypass. Storage failure defaults to 0 used — never hard-block
  /// a user because storage hiccuped.
  CoachAskQuotaControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachAskQuotaControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachAskQuotaControllerHash();

  @$internal
  @override
  CoachAskQuotaController create() => CoachAskQuotaController();
}

String _$coachAskQuotaControllerHash() =>
    r'6fb73acf68236fb2686ac74e45b4a4caf4bd3eaa';

/// Daily coach-ask quota controller.
///
/// Persists the free-tier counter in shared_prefs under
/// `coach_asks_<yyyy-MM-dd>`; the pure [CoachAskQuota] handles rollover and
/// the premium bypass. Storage failure defaults to 0 used — never hard-block
/// a user because storage hiccuped.

abstract class _$CoachAskQuotaController extends $AsyncNotifier<CoachAskQuota> {
  FutureOr<CoachAskQuota> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CoachAskQuota>, CoachAskQuota>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CoachAskQuota>, CoachAskQuota>,
              AsyncValue<CoachAskQuota>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
