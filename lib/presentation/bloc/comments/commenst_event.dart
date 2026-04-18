// lib/presentation/bloc/comments_bloc/comments_event.dart

abstract class CommentsEvent {}

class LoadComments extends CommentsEvent {
  final String postId;
  LoadComments(this.postId);
}

class AddComment extends CommentsEvent {
  final String postId;
  final String userId;
  final String repliersName;
  final String text;
  final String? parentCommentId;

  AddComment({
    required this.postId,
    required this.userId,
    required this.repliersName,
    required this.text,
    this.parentCommentId,
  });
}

class DeleteComment extends CommentsEvent {
  final String commentId;
  final String? parentCommentId; // to know if it's a reply
  DeleteComment({required this.commentId, this.parentCommentId});
}

