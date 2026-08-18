// lib/features/social/presentation/providers/creator_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/data/repositories/creator_repository.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

final creatorRepositoryProvider = Provider<CreatorRepository>((ref) {
  return CreatorRepository();
});

final creatorProfileProvider = StreamProvider.family<CreatorProfile?, String>((
  ref,
  userId,
) {
  final repository = ref.watch(creatorRepositoryProvider);
  return repository.watchCreatorProfile(userId);
});

final isVerifiedCreatorProvider = FutureProvider<bool>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final repo = ref.watch(creatorRepositoryProvider);
  final profile = await repo.getCreatorProfile(user.uid);
  return profile?.isVerifiedCreator ?? false;
});

/// Streams the list of all verified creators for the lobby strip and
/// browse-all screen. Returns an empty list while loading; consumers
/// should check [AsyncValue.isLoading]/[AsyncValue.hasError] to
/// differentiate loading from a real empty result.
final verifiedCreatorsStreamProvider =
    StreamProvider.autoDispose<List<CreatorProfile>>((ref) {
      final repo = ref.watch(creatorRepositoryProvider);
      return repo.watchVerifiedCreators();
    });

/// Verified creators scoped to the user's active tribe.
final tribeCreatorsProvider = StreamProvider<List<CreatorProfile>>((ref) {
  final membership = ref.watch(activeMembershipProvider).value;
  final repo = ref.watch(creatorRepositoryProvider);
  if (membership == null) return Stream.value([]);
  return repo.watchVerifiedCreators().map((creators) {
    return creators
        .where((c) => c.tribeId == null || c.tribeId == membership.tribeId)
        .toList();
  });
});
