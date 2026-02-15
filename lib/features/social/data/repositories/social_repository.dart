import 'package:emerge_app/features/social/domain/models/social_post.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Activity Feed Repository (Keep as specific repo or part of SocialRepository)
class SocialRepository {
  SocialRepository();

  // Mock data for feed
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

  Future<List<SocialPost>> getFeed() async {
    // In future: fetch from 'feed' collection
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockPosts;
  }
}

// ================= PROVIDERS =================

// 1. Repositories

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository();
});

// 2. Data Providers

final socialFeedProvider = FutureProvider<List<SocialPost>>((ref) async {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.getFeed();
});
