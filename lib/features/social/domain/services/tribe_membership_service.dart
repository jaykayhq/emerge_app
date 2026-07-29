import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';

class TribeMembershipService {
  final Ref _ref;

  TribeMembershipService(this._ref);

  Future<void> joinTribe(String tribeId) async {
    final userId = _ref.read(authStateChangesProvider).value?.id;
    if (userId == null) throw Exception('User not authenticated');

    final repository = _ref.read(tribeRepositoryProvider);
    await repository.joinClub(userId, tribeId);

    // Joining from the tribes list also switches contribution target.
    _ref.read(activeTribeIdProvider.notifier).select(tribeId);

    // Invalidate caches to show updated stats immediately
    _ref.read(tribeStatsCacheProvider).invalidate(tribeId);
    _ref.invalidate(cachedTribeStatsProvider(tribeId));
    _ref.invalidate(allArchetypeClubsProvider);
  }

  Future<void> leaveTribe(String tribeId) async {
    final userId = _ref.read(authStateChangesProvider).value?.id;
    if (userId == null) throw Exception('User not authenticated');

    final repository = _ref.read(tribeRepositoryProvider);
    await repository.leaveClub(userId, tribeId);

    // If the left tribe was the active one, fall back to archetype auto-detect.
    if (_ref.read(activeTribeIdProvider) == tribeId) {
      _ref.read(activeTribeIdProvider.notifier).select(null);
    }

    // Invalidate caches
    _ref.read(tribeStatsCacheProvider).invalidate(tribeId);
    _ref.invalidate(cachedTribeStatsProvider(tribeId));
    _ref.invalidate(allArchetypeClubsProvider);
  }

  bool isMember(String userId, List<String> members) {
    return members.contains(userId);
  }
}

final tribeMembershipServiceProvider = Provider<TribeMembershipService>((ref) {
  return TribeMembershipService(ref);
});
