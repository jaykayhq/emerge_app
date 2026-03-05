import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/data/repositories/friend_repository.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FirestoreFriendRepository(FirebaseFirestore.instance);
});

/// All accountability partners for the current user
final partnersListProvider = FutureProvider<List<Friend>>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  return ref.read(friendRepositoryProvider).getFriends(user.id);
});

/// Pending partner requests awaiting the user's response
final pendingPartnerRequestsProvider = FutureProvider<List<PartnerRequest>>((
  ref,
) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  return ref.read(friendRepositoryProvider).getPendingRequests(user.id);
});

/// Online / recently active partners
final onlinePartnersProvider = FutureProvider<List<Friend>>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  return ref.read(friendRepositoryProvider).getOnlinePartners(user.id);
});

// Legacy alias
final friendsListProvider = partnersListProvider;
