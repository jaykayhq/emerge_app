import 'package:emerge_app/features/monetization/data/repositories/revenue_cat_repository.dart';
import 'package:emerge_app/features/monetization/domain/repositories/monetization_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final result = await repo.isPremium;
    return result.fold(
      (error) => false, // Default to free if error
      (isPremium) => isPremium,
    );
  }

  Future<void> purchase() async {
    state = const AsyncValue.loading();
    final repo = ref.read(monetizationRepositoryProvider);
    final result = await repo.purchasePremium();

    result.fold(
      (error) => state = AsyncValue.error(error, StackTrace.current),
      (isPremium) => state = AsyncValue.data(isPremium),
    );
  }

  Future<void> restore() async {
    state = const AsyncValue.loading();
    final repo = ref.read(monetizationRepositoryProvider);
    final result = await repo.restorePurchases();

    result.fold(
      (error) => state = AsyncValue.error(error, StackTrace.current),
      (isPremium) => state = AsyncValue.data(isPremium),
    );
  }
}
