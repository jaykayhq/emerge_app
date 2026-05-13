import 'dart:async';
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

    final user = authState.value;
    if (user == null) return false;

    if (user.id.isNotEmpty) {
      await repo.initialize(uid: user.id);
    }

    // Retry RevenueCat check up to 3 times
    bool isPremium = false;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final sdkResult = await repo.isPremium;
        isPremium = sdkResult.fold(
          (error) {
            if (attempt < 2) Future.delayed(Duration(seconds: 1 << attempt));
            return false;
          },
          (val) => val,
        );
        if (sdkResult.isRight()) break;
      } catch (e) {
        if (attempt < 2) await Future.delayed(Duration(seconds: 1 << attempt));
      }
    }

    // Real-time listener for subscription changes
    final sub = repo.premiumStatusStream.listen((isPremiumUpdate) {
      state = AsyncValue.data(isPremiumUpdate);
    });
    ref.onDispose(() => sub.cancel());

    if (isPremium) return true;

    // Retry Firebase Custom Claims check
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final idTokenResult = await firebaseUser.getIdTokenResult(true);
        final activeEntitlements = idTokenResult.claims?['activeEntitlements'] as List<dynamic>?;
        if (activeEntitlements?.contains('premium') ?? false) {
          return true;
        }
      }
    } catch (e) {
      AppLogger.w('Custom claims verification failed', error: e);
    }

    return isPremium;
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = AsyncValue.data(await build());
  }
}
