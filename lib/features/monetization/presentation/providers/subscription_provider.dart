import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/monetization/data/repositories/revenue_cat_repository.dart';
import 'package:emerge_app/features/monetization/domain/repositories/monetization_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_provider.g.dart';

@Riverpod(keepAlive: true)
MonetizationRepository monetizationRepository(Ref ref) {
  return RevenueCatRepository();
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
    await repo.initialize(uid: user.id);

    // Listen to real-time subscription changes from RevenueCat SDK
    // This is still needed for immediate UI updates during purchases
    final sub = repo.premiumStatusStream.listen((isPremium) {
      state = AsyncValue.data(isPremium);
    });
    ref.onDispose(() => sub.cancel());

    // Check premium status using Firebase Auth custom claims
    // The RevenueCat Firebase extension automatically sets these claims
    try {
      // Get the actual Firebase Auth user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        // Fallback to RevenueCat SDK if Firebase user is not available
        final result = await repo.isPremium;
        return result.fold((error) {
          AppLogger.e('Failed to check premium status from RevenueCat', error);
          throw error;
        }, (isPremium) => isPremium);
      }

      // Check custom claims for premium entitlement
      final idTokenResult = await firebaseUser.getIdTokenResult();
      final activeEntitlements = idTokenResult.claims?['activeEntitlements'] as List<dynamic>?;
      final isPremium = activeEntitlements?.contains('premium') ?? false;
      
      return isPremium;
    } catch (e) {
      AppLogger.e('Failed to check premium status from custom claims', e);
      // Fallback to RevenueCat SDK if custom claims fail
      final result = await repo.isPremium;
      return result.fold((error) {
        AppLogger.e('Failed to check premium status from RevenueCat', error);
        throw error;
      }, (isPremium) => isPremium);
    }
  }
}
