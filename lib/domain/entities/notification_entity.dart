
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
}
