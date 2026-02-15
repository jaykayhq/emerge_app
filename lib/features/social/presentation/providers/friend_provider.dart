import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/data/repositories/friend_repository.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FirestoreFriendRepository(FirebaseFirestore.instance);
});

final friendsListProvider = FutureProvider<List<Friend>>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];

  final repository = ref.watch(friendRepositoryProvider);
  return repository.getFriends(user.id);
});
