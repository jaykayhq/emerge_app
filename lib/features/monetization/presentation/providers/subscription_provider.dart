import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/monetization/data/repositories/revenue_cat_repository.dart';
import 'package:emerge_app/features/monetization/domain/repositories/monetization_repository.dart';
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
    // Initialize SDK on first build
    await repo.initialize();

    // Listen to real-time subscription changes
    final sub = repo.premiumStatusStream.listen((isPremium) {
      state = AsyncValue.data(isPremium);
    });
    ref.onDispose(() => sub.cancel());

    final result = await repo.isPremium;
    return result.fold((error) {
      AppLogger.e('Failed to check premium status', error);
      throw error;
    }, (isPremium) => isPremium);
  }
}
