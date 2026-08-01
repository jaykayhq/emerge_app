import 'package:emerge_app/features/monetization/domain/services/coach_ask_quota.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'coach_ask_quota_provider.g.dart';

/// Daily coach-ask quota controller.
///
/// Persists the free-tier counter in shared_prefs under
/// `coach_asks_<yyyy-MM-dd>`; the pure [CoachAskQuota] handles rollover and
/// the premium bypass. Storage failure defaults to 0 used — never hard-block
/// a user because storage hiccuped.
@Riverpod(keepAlive: true)
class CoachAskQuotaController extends _$CoachAskQuotaController {
  @override
  Future<CoachAskQuota> build() async {
    final isPremium = await ref.watch(isPremiumProvider.future);
    final today = CoachAskQuota.dateKeyFor(DateTime.now());
    int used = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      used = prefs.getInt('coach_asks_$today') ?? 0;
    } catch (_) {
      used = 0;
    }
    return CoachAskQuota(
      dateKey: today,
      usedToday: used,
      isPremium: isPremium,
    );
  }

  /// Records one ask. Free users persist the incremented counter;
  /// premium counters never change.
  Future<CoachAskQuota> consume() async {
    final current = state.value ??
        CoachAskQuota(
          dateKey: CoachAskQuota.dateKeyFor(DateTime.now()),
          usedToday: 0,
          isPremium: false,
        );
    final next = current.consume();
    if (!current.isPremium) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('coach_asks_${next.dateKey}', next.usedToday);
      } catch (_) {
        // Permit by default on storage failure.
      }
    }
    state = AsyncValue.data(next);
    return next;
  }
}
