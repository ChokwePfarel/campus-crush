
import '../../domain/entities/comment_entity.dart';

class CommentModel extends CommentEntity {
  CommentModel({
    required super.id,
    required super.repliersName,
    required super.postId,
    required super.userId,
    required super.text,
    required super.createdAt,
    super.parentCommentId,
    super.replies = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      repliersName: json['repliers_name'] ?? '',
      postId: json['post_id'] ?? '',
      userId: json['user_id'] ?? '',
      text: json['text'] ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      parentCommentId: json['parent_comment_id'],
      replies: json['replies'] != null
          ? (json['replies'] as List)
                .map((e) => CommentModel.fromJson(e))
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repliers_name': repliersName,
      'post_id': postId,
      'user_id': userId,
      'text': text,
      'parent_comment_id': parentCommentId,
      'created_at': createdAt.toIso8601String(),

    };
  }
}
