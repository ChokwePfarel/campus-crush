import 'package:dating_app/domain/entities/comment_entity.dart';

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

class WatchUserNotifications extends CommentsEvent {
  final String userId;
  WatchUserNotifications(this.userId);
}

class MarkNotificationsAsRead extends CommentsEvent {}

class NewNotificationReceived extends CommentsEvent {
  final CommentEntity comment;
  NewNotificationReceived(this.comment);
}
