import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/monetization/data/repositories/revenue_cat_repository.dart';
import 'package:emerge_app/features/monetization/domain/repositories/monetization_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'subscription_provider.g.dart';

@Riverpod(keepAlive: true)
MonetizationRepository monetizationRepository(Ref ref) {
  try {
    final cacheService = ref.watch(localCacheServiceProvider);
    return RevenueCatRepository(cacheService: cacheService);
  } catch (_) {
    // Cache not ready yet — initialize without cache (no offline premium status)
    return RevenueCatRepository();
  }
}

@Riverpod(keepAlive: true)
class IsPremium extends _$IsPremium {
  @override
  Future<bool> build() async {
    final repo = ref.watch(monetizationRepositoryProvider);
    final authState = ref.watch(authStateChangesProvider);

    // Wait for user to be authenticated before initializing
    final user = authState.value;
    if (user == null) {
      // User not authenticated yet, return false (not premium)
      return false;
    }

    // Initialize SDK with user ID on first build
    if (user.id.isNotEmpty) {
      await repo.initialize(uid: user.id);
    }

    // Initial check from RevenueCat SDK (Source of Truth)
    final sdkResult = await repo.isPremium;
    bool isPremium = sdkResult.fold(
      (error) {
        AppLogger.e('Initial premium check failed', error);
        return false;
      },
      (val) => val,
    );

    // Listen to real-time subscription changes for immediate UI updates
    final sub = repo.premiumStatusStream.listen((isPremiumUpdate) {
      state = AsyncValue.data(isPremiumUpdate);
    });
    ref.onDispose(() => sub.cancel());

    // If SDK says premium, we are done
    if (isPremium) return true;

    // Optional: Secondary check with Firebase Custom Claims
    // This handles cases where the extension synced but SDK cache is stale
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // Force refresh token to get latest claims
        final idTokenResult = await firebaseUser.getIdTokenResult(true);
        final activeEntitlements = idTokenResult.claims?['activeEntitlements'] as List<dynamic>?;
        if (activeEntitlements?.contains('premium') ?? false) {
          return true;
        }
      }
    } catch (e) {
      AppLogger.w('Custom claims verification skipped or failed', error: e);
    }

    return isPremium;
  }
}
