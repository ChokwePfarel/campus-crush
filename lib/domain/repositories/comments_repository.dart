
import 'package:dating_app/domain/entities/comment_entity.dart';

abstract class CommentsRepository {
  Future<List<CommentEntity>> getComments(String postId);
  Future<CommentEntity> addComment({
    required String postId,
    required String userId,
    required String repliersName,
    required String text,
    String? parentCommentId,

  });
  Future<void> deleteComment(String commentId);

  Stream<CommentEntity> watchUserNotifications(String userId);
}


