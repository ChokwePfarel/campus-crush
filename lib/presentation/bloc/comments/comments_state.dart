import 'package:dating_app/domain/entities/comment_entity.dart';

abstract class CommentsState {
  final bool showRedDot;
  final List<CommentEntity> notifications;

  const CommentsState({this.showRedDot = false, this.notifications = const []});
}

class InitialComments extends CommentsState {
  const InitialComments({super.showRedDot, super.notifications});
}

class LoadingComments extends CommentsState {
  const LoadingComments({super.showRedDot, super.notifications});
}

class CommentsLoaded extends CommentsState {
  final List<CommentEntity> comments;

  const CommentsLoaded(this.comments, {super.showRedDot, super.notifications});

  CommentsLoaded copyWith({
    List<CommentEntity>? comments,
    bool? showRedDot,
    List<CommentEntity>? notifications,
  }) {
    return CommentsLoaded(
      comments ?? this.comments,
      showRedDot: showRedDot ?? this.showRedDot,
      notifications: notifications ?? this.notifications,
    );
  }
}

class ErrorComments extends CommentsState {
  final String message;

  const ErrorComments(this.message, {super.showRedDot, super.notifications});
}
