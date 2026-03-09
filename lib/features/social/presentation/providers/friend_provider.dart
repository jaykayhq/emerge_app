import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/data/repositories/friend_repository.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Legacy stream provider
export 'friend_stream_provider.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FirestoreFriendRepository(FirebaseFirestore.instance);
});

/// All accountability partners for the current user
final partnersListProvider = StreamProvider.autoDispose<List<Friend>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);

  final repository = ref.watch(friendRepositoryProvider);
  return repository.watchFriends(user.id);
});

/// Pending partner requests awaiting the user's response
final pendingPartnerRequestsProvider = StreamProvider.autoDispose<List<PartnerRequest>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);

  final repository = ref.watch(friendRepositoryProvider);
  return repository.watchPendingRequests(user.id);
});

/// Online / recently active partners
final onlinePartnersProvider = StreamProvider.autoDispose<List<Friend>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);

  final repository = ref.watch(friendRepositoryProvider);
  return repository.watchOnlinePartners(user.id);
});

// Legacy alias
final friendsListProvider = partnersListProvider;
