import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/monetization/data/repositories/revenue_cat_repository.dart';
import 'package:emerge_app/features/monetization/data/services/web_premium_service.dart';
import 'package:emerge_app/features/monetization/domain/models/premium_state.dart';
import 'package:emerge_app/features/monetization/domain/repositories/monetization_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'subscription_provider.g.dart';

@Riverpod(keepAlive: true)
MonetizationRepository monetizationRepository(Ref ref) {
  return RevenueCatRepository();
}

@Riverpod(keepAlive: true)
class IsPremium extends _$IsPremium {
  static const _cacheKey = 'cached_premium_status';
  static const _cacheTimestampKey = 'cached_premium_timestamp';

  /// Injectable clock for the pause-end machinery (test seam). Production
  /// defaults to [DateTime.now]; tests advance a mutable fake instead of
  /// sleeping, so the end-date drop is verifiable without waiting.
  DateTime Function() now = DateTime.now;

  /// Injectable `users/{uid}` doc-data stream (test seam). Production
  /// default follows the live snapshot data; tests drive emissions and
  /// stream errors without Firebase.
  Stream<Map<String, dynamic>?> Function(
    FirebaseFirestore firestore,
    String uid,
  )
  docDataStream = (firestore, uid) => firestore
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => snap.data());

  Timer? _pauseEndTimer;
  PremiumState? _latestPremiumState;

  /// Whether the web (Firestore doc) premium path applies. `kIsWeb` is a
  /// compile-time constant (always false under `flutter test`), so tests
  /// subclass [IsPremium] and force this true to exercise the web path.
  bool get isWeb => kIsWeb;

  @override
  Future<bool> build() async {
    final repo = ref.watch(monetizationRepositoryProvider);
    final authState = ref.watch(authStateChangesProvider);

    final user = authState.value;
    if (user == null) return false;

    // Web: RevenueCat is never configured (revenue_cat_repository.dart:29-34).
    // Premium is read from the Paystack-written `users/{uid}.isPremium` flag
    // instead (functions/src/payments/paystack.ts:129-136).
    if (isWeb) {
      return _buildFromFirestore(user.id);
    }

    if (user.id.isNotEmpty) {
      await repo.initialize(uid: user.id);
    }

    // Retry RevenueCat check up to 3 times
    bool isPremium = false;
    bool checkSucceeded = false;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final sdkResult = await repo.isPremium;
        isPremium = sdkResult.fold((error) {
          if (attempt < 2) Future.delayed(Duration(seconds: 1 << attempt));
          return false;
        }, (val) => val);
        if (sdkResult.isRight()) {
          checkSucceeded = true;
          break;
        }
      } catch (e) {
        if (attempt < 2) await Future.delayed(Duration(seconds: 1 << attempt));
      }
    }

    // Real-time listener for subscription changes
    final sub = repo.premiumStatusStream.listen((isPremiumUpdate) {
      state = AsyncValue.data(isPremiumUpdate);
      // Cache real-time updates too
      _cachePremiumStatus(isPremiumUpdate);
    });
    ref.onDispose(() => sub.cancel());

    if (checkSucceeded || isPremium) {
      // Cache successful result
      await _cachePremiumStatus(isPremium);
      return isPremium;
    }

    // Retry Firebase Custom Claims check
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final idTokenResult = await firebaseUser.getIdTokenResult(true);
        final activeEntitlements =
            idTokenResult.claims?['activeEntitlements'] as List<dynamic>?;
        if (activeEntitlements?.contains('premium') ?? false) {
          await _cachePremiumStatus(true);
          return true;
        }
      }
    } catch (e) {
      AppLogger.w('Custom claims verification failed', error: e);
    }

    // All checks failed — fall back to local cache (offline support)
    final cached = await _readCachedPremiumStatus();
    if (cached != null) return cached;

    return isPremium;
  }

  /// Web premium status from the `users/{uid}` Firestore doc.
  ///
  /// Keeps a live snapshot subscription (the keepAlive provider holds it for
  /// the app session) so the Paystack webhook update lands without a rebuild,
  /// and returns the current doc value as the initial result. On read
  /// failure, falls back to the existing 7-day prefs cache (which is only
  /// ever written on native) and otherwise reports false — never block.
  Future<bool> _buildFromFirestore(String uid) async {
    final firestore = ref.watch(firestoreProvider);
    final sub = docDataStream(firestore, uid).listen(
      (data) {
        _applyWebState(data);
        // The stream only re-emits on doc CHANGES — time passage alone never
        // triggers one. A pause written mid-session (Manage Premium → Pause)
        // re-emits and lands here: keep the pause-end timer in sync with the
        // doc on EVERY emission so a paused user drops at `premiumEndsAt`
        // without relaunching, and no stale timer outlives a resume/cancel.
        _schedulePauseEndTimer(firestore, uid, data);
      },
      onError: (Object error, StackTrace stackTrace) {
        // Keep the last known state — a transient Firestore stream error
        // must never flip a paying user to free mid-session.
        AppLogger.w(
          'Web premium stream error — keeping last known state',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    ref.onDispose(sub.cancel);
    ref.onDispose(_cancelPauseEndTimer);
    try {
      final snap = await firestore.collection('users').doc(uid).get();
      _applyWebState(snap.data());
      _schedulePauseEndTimer(firestore, uid, snap.data());
      return premiumStateFromRecord(snap.data(), now: now).isPremium;
    } catch (e) {
      AppLogger.w('Web premium Firestore check failed', error: e);
      final cached = await _readCachedPremiumStatus();
      return cached ?? false;
    }
  }

  /// Applies a web doc state: remembers the richer [PremiumState] (re-exposed
  /// through [premiumStateProvider] for paused UI) and pushes the bool into
  /// this provider.
  void _applyWebState(Map<String, dynamic>? data) {
    final premium = premiumStateFromRecord(data, now: now);
    _latestPremiumState = premium;
    // Bump the revision BEFORE the bool so [premiumStateProvider] rebuilds
    // even when the bool is unchanged (e.g. a mid-session pause keeps
    // isPremium true but flips isPaused) — Riverpod suppresses notifies on
    // value-equal AsyncData.
    ref.read(premiumStateRevisionProvider.notifier).bump();
    state = AsyncValue.data(premium.isPremium);
  }

  /// Web Firestore streams only re-emit on doc CHANGES — time passage alone
  /// never triggers one, so a paused user would otherwise stay premium for
  /// the whole session after `premiumEndsAt` passes. Schedule one timer for
  /// the pause end (+1s): on fire, re-read the doc, push the fresh status,
  /// and re-schedule while the doc is still paused with a future end date
  /// (covers repeated pauses; each pause writes now+30d, so a single timer
  /// stays under Dart's ~24.7-day Timer cap). Always cancels any previous
  /// timer first — emissions re-schedule, they never stack. No timer when
  /// there is no end date (indefinite pause) or it is not in the future.
  void _schedulePauseEndTimer(
    FirebaseFirestore firestore,
    String uid,
    Map<String, dynamic>? data,
  ) {
    _cancelPauseEndTimer();
    final endsAt = _parsePauseEndsAt(data);
    final nowValue = now();
    if (endsAt == null || !endsAt.isAfter(nowValue)) return;
    _pauseEndTimer = Timer(
      endsAt.difference(nowValue) + const Duration(seconds: 1),
      () => _checkPauseEnd(firestore, uid),
    );
  }

  void _cancelPauseEndTimer() {
    _pauseEndTimer?.cancel();
    _pauseEndTimer = null;
  }

  Future<void> _checkPauseEnd(FirebaseFirestore firestore, String uid) async {
    try {
      final snap = await firestore.collection('users').doc(uid).get();
      _applyWebState(snap.data());
      // Re-schedule while still paused with a future end date; the future-
      // end-date guard and the cancel-first behavior live in
      // `_schedulePauseEndTimer`.
      _schedulePauseEndTimer(firestore, uid, snap.data());
    } catch (e) {
      AppLogger.w('Web premium pause-end re-check failed', error: e);
    }
  }

  /// `premiumEndsAt` as a DateTime when present and parseable — never throws
  /// on unexpected shapes.
  DateTime? _parsePauseEndsAt(Map<String, dynamic>? data) {
    final raw = data?['premiumEndsAt'];
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  /// Latest richer [PremiumState] observed on the web path. The doc stream
  /// lives in this provider, so the rich state is re-exposed rather than
  /// re-subscribed. Null on native (RevenueCat owns the state there) and
  /// before the first web doc read.
  PremiumState? get latestPremiumState => _latestPremiumState;

  /// Persist premium status for offline fallback.
  Future<void> _cachePremiumStatus(bool isPremium) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cacheKey, isPremium);
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      AppLogger.w('Failed to cache premium status', error: e);
    }
  }

  /// Read cached premium status. Returns null if cache is missing or expired.
  /// Trusts cache for up to 7 days.
  Future<bool?> _readCachedPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStatus = prefs.getBool(_cacheKey) ?? false;
      final cachedTime = prefs.getInt(_cacheTimestampKey) ?? 0;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTime;

      if (cachedStatus && cacheAge < const Duration(days: 7).inMilliseconds) {
        AppLogger.i('Using cached premium status (age: ${cacheAge ~/ 1000}s)');
        return cachedStatus;
      }
    } catch (e) {
      AppLogger.w('Failed to read cached premium status', error: e);
    }
    return null;
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = AsyncValue.data(await build());
  }
}

/// Whether a daily login bonus is available to claim for a premium user.
///
/// Returns false for free users and for premium users who already claimed
/// today. Claiming persists the claim date to [SharedPreferences] so the
/// bonus is one-per-calendar-day.
@riverpod
class DailyLoginBonus extends _$DailyLoginBonus {
  static const _prefsKey = 'last_daily_bonus_claim';

  @override
  Future<bool> build() async {
    final isPremium = await ref.watch(isPremiumProvider.future);
    if (!isPremium) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastClaim = prefs.getString(_prefsKey);
    if (lastClaim == _todayKey()) {
      return false; // Already claimed today.
    }
    return true; // Bonus available.
  }

  /// Records today's claim so the bonus cannot be claimed again until
  /// tomorrow. Callers are responsible for awarding the actual reward (e.g.
  /// +XP) in response to this returning normally.
  Future<void> claimBonus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _todayKey());
    state = const AsyncValue.data(false);
  }

  /// yyyy-MM-dd for the current local date.
  String _todayKey() => DateTime.now().toIso8601String().substring(0, 10);
}

/// Bumped on every web doc emission so [premiumStateProvider] rebuilds even
/// when the premium BOOL is unchanged (Riverpod suppresses notifies on
/// value-equal AsyncData; a mid-session pause keeps isPremium true while
/// isPaused flips).
class PremiumStateRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final premiumStateRevisionProvider =
    NotifierProvider<PremiumStateRevision, int>(PremiumStateRevision.new);

/// Web premium state for UI that needs more than the bool — the paused
/// status and resume date (Manage Premium). Tracks [isPremiumProvider] so it
/// updates with every doc emission; null on native (where RevenueCat owns
/// the state) and before the first web doc read.
final premiumStateProvider = Provider<PremiumState?>((ref) {
  ref.watch(isPremiumProvider);
  ref.watch(premiumStateRevisionProvider);
  return ref.read(isPremiumProvider.notifier).latestPremiumState;
});
