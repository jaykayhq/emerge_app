import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/monetization/data/repositories/revenue_cat_repository.dart';
import 'package:emerge_app/features/monetization/data/services/web_premium_service.dart';
import 'package:emerge_app/features/monetization/domain/repositories/monetization_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  @override
  Future<bool> build() async {
    final repo = ref.watch(monetizationRepositoryProvider);
    final authState = ref.watch(authStateChangesProvider);

    final user = authState.value;
    if (user == null) return false;

    // Web: RevenueCat is never configured (revenue_cat_repository.dart:29-34).
    // Premium is read from the Paystack-written `users/{uid}.isPremium` flag
    // instead (functions/src/payments/paystack.ts:129-136).
    if (kIsWeb) {
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
    final sub = streamWebPremium(firestore, uid).listen((isPremium) {
      state = AsyncValue.data(isPremium);
    });
    ref.onDispose(sub.cancel);
    try {
      final snap = await firestore.collection('users').doc(uid).get();
      _schedulePauseEndTimer(firestore, uid, snap.data());
      return recordToPremium(snap.data());
    } catch (e) {
      AppLogger.w('Web premium Firestore check failed', error: e);
      final cached = await _readCachedPremiumStatus();
      return cached ?? false;
    }
  }

  /// Web Firestore streams only re-emit on doc CHANGES — time passage alone
  /// never triggers one, so a paused user would otherwise stay premium for
  /// the whole session after `premiumEndsAt` passes. Schedule one timer for
  /// the pause end (+1s): on fire, re-read the doc, push the fresh status,
  /// and re-schedule while the doc is still paused with a future end date
  /// (covers repeated pauses; each pause writes now+30d, so a single timer
  /// stays under Dart's ~24.7-day Timer cap). No timer when there is no end
  /// date (indefinite pause) or it is not in the future.
  void _schedulePauseEndTimer(
    FirebaseFirestore firestore,
    String uid,
    Map<String, dynamic>? data,
  ) {
    final endsAt = _parsePauseEndsAt(data);
    if (endsAt == null || !endsAt.isAfter(DateTime.now())) return;
    final timer = Timer(
      endsAt.difference(DateTime.now()) + const Duration(seconds: 1),
      () => _checkPauseEnd(firestore, uid),
    );
    ref.onDispose(timer.cancel);
  }

  Future<void> _checkPauseEnd(FirebaseFirestore firestore, String uid) async {
    try {
      final snap = await firestore.collection('users').doc(uid).get();
      state = AsyncValue.data(recordToPremium(snap.data()));
      final data = snap.data();
      if (data?['subscriptionStatus'] == 'paused' &&
          _parsePauseEndsAt(data) != null) {
        // The future-end-date guard lives in `_schedulePauseEndTimer`.
        _schedulePauseEndTimer(firestore, uid, data);
      }
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

      if (cachedStatus &&
          cacheAge < const Duration(days: 7).inMilliseconds) {
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
