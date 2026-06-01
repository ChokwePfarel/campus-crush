import 'package:dating_app/domain/entities/notification_entity.dart';
import 'package:flutter/foundation.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.triggeredByName,
    required super.postId,
    required super.commentId,
    required super.commentText,
    required super.isReply,
    required super.isRead,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    try {
      return NotificationModel(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        triggeredByName: json['triggered_by_name']?.toString() ?? 'Someone',
        postId: json['post_id']?.toString() ?? '',
        commentId: json['comment_id']?.toString() ?? '',
        commentText: json['comment_text']?.toString() ?? '',
        isReply: json['is_reply'] == true,
        isRead: json['is_read'] == true,
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at']) 
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('NotificationModel: Error parsing JSON: $e');
      debugPrint('NotificationModel: Corrupted JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'triggered_by_name': triggeredByName,
    'post_id': postId,
    'comment_id': commentId,
    'comment_text': commentText,
    'is_reply': isReply,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
  };
}
