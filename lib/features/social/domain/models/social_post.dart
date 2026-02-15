import 'package:equatable/equatable.dart';

enum PostType { regular, challengeJoin, habitCompletion, levelUp }

class SocialPost extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String content;
  final String? imageUrl;
  final PostType type;
  final int likes;
  final int comments;
  final DateTime timestamp;
  final bool isLikedByMe;

  const SocialPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    this.imageUrl,
    required this.type,
    required this.likes,
    required this.comments,
    required this.timestamp,
    required this.isLikedByMe,
  });

  factory SocialPost.mock() {
    return SocialPost(
      id: '1',
      userId: 'user1',
      userName: 'Alice Walker',
      userAvatarUrl: 'https://i.pravatar.cc/150?u=alice',
      content: 'Just finished my morning meditation! Feeling centered.',
      type: PostType.habitCompletion,
      likes: 12,
      comments: 3,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isLikedByMe: false,
    );
  }

  SocialPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? content,
    String? imageUrl,
    PostType? type,
    int? likes,
    int? comments,
    DateTime? timestamp,
    bool? isLikedByMe,
  }) {
    return SocialPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      timestamp: timestamp ?? this.timestamp,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'content': content,
      'imageUrl': imageUrl,
      'type': type.name, // Store enum as string
      'likes': likes,
      'comments': comments,
      'timestamp': timestamp.toIso8601String(),
      'isLikedByMe':
          isLikedByMe, // Note: In real app, this is computed, not stored in post doc
    };
  }

  factory SocialPost.fromMap(Map<String, dynamic> map, String id) {
    return SocialPost(
      id: id,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Anonymous',
      userAvatarUrl: map['userAvatarUrl'] as String? ?? '',
      content: map['content'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      type: PostType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PostType.regular,
      ),
      likes: map['likes'] as int? ?? 0,
      comments: map['comments'] as int? ?? 0,
      timestamp:
          DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      isLikedByMe: map['isLikedByMe'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    userAvatarUrl,
    content,
    imageUrl,
    type,
    likes,
    comments,
    timestamp,
    isLikedByMe,
  ];
}
