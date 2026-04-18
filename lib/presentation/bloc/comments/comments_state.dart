import 'package:dating_app/domain/entities/comment_entity.dart';

abstract class CommentsState {}

class InitialComments extends CommentsState {}

class LoadingComments extends CommentsState {}

class CommentsLoaded extends CommentsState {
  final List<CommentEntity> comments;

  CommentsLoaded(this.comments);

  CommentsLoaded copyWith({
    List<CommentEntity>? comments,
  }) {
    return CommentsLoaded(
      comments ?? this.comments,
    );
  }
}

class ErrorComments extends CommentsState {
  final String message;

  ErrorComments(this.message);
}
