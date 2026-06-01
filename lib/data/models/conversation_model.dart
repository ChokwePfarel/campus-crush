
import 'package:dating_app/domain/entities/conversation_entity.dart';

class ConversationModel extends ConversationEntity {
  const ConversationModel({
    required super.id,
    required super.userOneId,
    required super.userTwoId,
    super.lastMessage,
    super.lastMessageAt,
    required super.createdAt,
    required super.otherUserName,
    required super.otherUserImageUrl,
    required super.otherUserIsVerified,
    super.unreadCount = 0,
  });

  factory ConversationModel.fromJson(
      Map<String, dynamic> json, String currentUserId, [int unreadCount = 0]) {

    // Determine which user is the "other" one
    final isUserOne = json['user_one_id'] == currentUserId;

    final otherUser = isUserOne
        ? json['user_two'] as Map<String, dynamic>
        : json['user_one'] as Map<String, dynamic>;

    return ConversationModel(
      id:                  json['id'],
      userOneId:           json['user_one_id'],
      userTwoId:           json['user_two_id'],
      lastMessage:         json['last_message'],
      lastMessageAt:       json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      createdAt:           DateTime.parse(json['created_at']),
      otherUserName:       otherUser['name'] ?? '',
      otherUserImageUrl:   otherUser['profile_image_url'] ?? '',
      otherUserIsVerified: otherUser['is_verified'] ?? false,
      unreadCount:         unreadCount,

    );
  }
}
