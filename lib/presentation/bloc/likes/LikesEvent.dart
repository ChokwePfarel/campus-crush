// lib/presentation/bloc/likes/likes_event.dart

abstract class LikesEvent {}

/// Called once per card on mount — loads count + hasLiked in one go
class InitializeLikes extends LikesEvent {
  final String postId;
  final String userId;
  final int initialCount; // from PostModel, shown instantly before DB confirms
  InitializeLikes({
    required this.postId,
    required this.userId,
    required this.initialCount,
  });
}

class LikePost extends LikesEvent {
  final String postId;
  final String userId;
  final String likedByName;
  LikePost({required this.postId, required this.userId, required this.likedByName});
}

class UnlikePost extends LikesEvent {
  final String postId;
  final String userId;
  UnlikePost({required this.postId, required this.userId});
}