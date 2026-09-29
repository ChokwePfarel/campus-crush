
class NotificationEntity {
  final String id;
  final String userId;
  final String triggeredByName;
  final String postId;
  final String commentId;
  final String commentText;
  final bool isReply;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.triggeredByName,
    required this.postId,
    required this.commentId,
    required this.commentText,
    required this.isReply,
    required this.isRead,
    required this.createdAt,
  });

  NotificationEntity copyWith({
    String? id,
    String? userId,
    String? triggeredByName,
    String? postId,
    String? commentId,
    String? commentText,
    bool? isReply,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      triggeredByName: triggeredByName ?? this.triggeredByName,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      commentText: commentText ?? this.commentText,
      isReply: isReply ?? this.isReply,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
