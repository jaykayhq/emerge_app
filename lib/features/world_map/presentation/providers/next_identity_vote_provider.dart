import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/world_map/domain/models/next_identity_vote.dart';
import 'package:emerge_app/features/world_map/domain/services/next_identity_vote_service.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'next_identity_vote_provider.g.dart';

/// Provider for [NextIdentityVoteService]
@riverpod
NextIdentityVoteService nextIdentityVoteService(Ref ref) {
  return NextIdentityVoteService();
}

/// Computes the active [NextIdentityVote] by watching [habitsProvider]
/// and [worldEntropyStreamProvider].
@riverpod
NextIdentityVote nextIdentityVote(Ref ref) {
  final habitsAsync = ref.watch(habitsProvider);
  final entropyAsync = ref.watch(worldEntropyStreamProvider);
  final service = ref.watch(nextIdentityVoteServiceProvider);

  final habits = habitsAsync.value ?? [];
  final entropy = entropyAsync.value ?? 0.0;

  return service.calculateNextVote(
    habits: habits,
    entropy: entropy,
  );
}
