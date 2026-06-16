import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emerge_app/features/social/data/repositories/creator_repository.dart';

final isVerifiedCreatorProvider = FutureProvider<bool>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final repo = ref.watch(creatorRepositoryProvider);
  final profile = await repo.getCreatorProfile(user.uid);
  return profile?.isVerifiedCreator ?? false;
});
