class CommentEntity {
  final String id;
  final String repliersName;
  final String postId;
  final String userId;
  final String text;
  final DateTime createdAt;
  final String? parentCommentId; // null if top-level
  final List<CommentEntity> replies; // optional, for UI convenience

  // ADD THESE:
  final String? postAuthorId;
  final String? parentCommentAuthorId;


  CommentEntity({
    required this.id,
    required this.repliersName,
    required this.postId,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.parentCommentId,
    this.replies = const [],

    // ADD THESE:
    this.postAuthorId,
    this.parentCommentAuthorId,
  });
}
