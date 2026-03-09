import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream of pending partner requests for the current user
/// Returns empty stream if user is not logged in
final pendingPartnerRequestsStreamProvider =
    StreamProvider.autoDispose<List<PartnerRequest>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.empty();

  final repository = ref.watch(friendRepositoryProvider);
  return repository.watchPendingRequests(user.id);
});

/// Stream of online partners for the current user
/// Returns empty stream if user is not logged in
final onlinePartnersStreamProvider =
    StreamProvider.autoDispose<List<Friend>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.empty();

  final repository = ref.watch(friendRepositoryProvider);
  return repository.watchOnlinePartners(user.id);
});

/// Stream of all accountability partners for the current user
/// Returns empty stream if user is not logged in
final partnersListStreamProvider =
    StreamProvider.autoDispose<List<Friend>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);

  final repository = ref.watch(friendRepositoryProvider);
  return repository.watchFriends(user.id);
});
