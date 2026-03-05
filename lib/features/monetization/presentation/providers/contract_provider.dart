import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/monetization/data/repositories/habit_contract_repository.dart';
import 'package:emerge_app/features/monetization/domain/entities/habit_contract.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream of all contracts where user is either owner or partner.
final activeContractsProvider = StreamProvider<List<HabitContract>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);

  final repo = ref.watch(habitContractRepositoryProvider);
  return repo.watchAllPartnerContracts(user.id);
});

/// Active contracts only (filtered from stream).
final activeOnlyContractsProvider = Provider<AsyncValue<List<HabitContract>>>((
  ref,
) {
  return ref
      .watch(activeContractsProvider)
      .whenData(
        (contracts) => contracts.where((c) => c.status == 'active').toList(),
      );
});
