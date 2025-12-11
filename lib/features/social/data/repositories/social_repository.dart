import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/features/social/domain/models/social_post.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

class SocialRepository {
  // Mock data for now
  final List<SocialPost> _mockPosts = [
    SocialPost(
      id: '1',
      userId: 'u1',
      userName: 'Sarah Jenkins',
      userAvatarUrl: '',
      content: 'Just hit a 7-day streak on "Morning Run"! 🏃‍♀️🔥',
      type: PostType.habitCompletion,
      likes: 24,
      comments: 5,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isLikedByMe: false,
    ),
    SocialPost(
      id: '2',
      userId: 'u2',
      userName: 'Mike Ross',
      userAvatarUrl: '',
      content: 'Joined the "30 Days of Code" challenge. Who\'s with me?',
      type: PostType.challengeJoin,
      likes: 45,
      comments: 12,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isLikedByMe: true,
    ),
    SocialPost(
      id: '3',
      userId: 'u3',
      userName: 'Jessica Pearson',
      userAvatarUrl: '',
      content: 'Level Up! Reached Level 5: "Apprentice Scholar". 📚✨',
      type: PostType.levelUp,
      likes: 89,
      comments: 20,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isLikedByMe: false,
    ),
  ];

  Future<Either<Failure, List<Tribe>>> getTribes({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    return const Right([]);
  }

  Future<Either<Failure, List<Challenge>>> getActiveChallenges({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    return const Right([]);
  }

  Future<Either<Failure, Unit>> joinTribe(String tribeId, String userId) async {
    return const Right(unit);
  }

  Future<Either<Failure, Unit>> joinChallenge(
    String challengeId,
    String userId,
  ) async {
    return const Right(unit);
  }

  Future<List<SocialPost>> getFeed() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockPosts;
  }

  Future<void> likePost(String postId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // In a real app, this would update Firestore
  }

  Future<void> createPost(String content) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockPosts.insert(
      0,
      SocialPost(
        id: DateTime.now().toString(),
        userId: 'current_user',
        userName: 'You',
        userAvatarUrl: '',
        content: content,
        type: PostType.regular,
        likes: 0,
        comments: 0,
        timestamp: DateTime.now(),
        isLikedByMe: false,
      ),
    );
  }
}

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository();
});

final socialFeedProvider = FutureProvider<List<SocialPost>>((ref) async {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.getFeed();
});

final tribesProvider = FutureProvider<List<Tribe>>((ref) async {
  final repository = ref.watch(socialRepositoryProvider);
  final result = await repository.getTribes();
  return result.fold((l) => [], (r) => r);
});

final activeChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final repository = ref.watch(socialRepositoryProvider);
  final result = await repository.getActiveChallenges();
  return result.fold((l) => [], (r) => r);
});
