// lib/presentation/bloc/likes_bloc/likes_event.dart

abstract class LikesEvent {}

class LoadLikes extends LikesEvent {
  final String postId;
  LoadLikes(this.postId);
}

class LikePost extends LikesEvent {
  final String postId;
  final String userId;
  final String likedByName;

  LikePost({
    required this.postId,
    required this.userId,
    required this.likedByName,
  });
}

class UnlikePost extends LikesEvent {
  final String postId;
  final String userId;
  UnlikePost({required this.postId, required this.userId});
}

class CheckHasLiked extends LikesEvent {
  final String postId;
  final String userId;
  CheckHasLiked({required this.postId, required this.userId});
}