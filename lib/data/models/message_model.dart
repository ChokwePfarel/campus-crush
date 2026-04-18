// lib/data/models/message_model.dart

import 'package:dating_app/domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.text,
    required super.isRead,
    required super.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id:             json['id'],
      conversationId: json['conversation_id'],
      senderId:       json['sender_id'],
      text:           json['text'],
      isRead:         json['is_read'] ?? false,
      createdAt:      DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':              id,
    'conversation_id': conversationId,
    'sender_id':       senderId,
    'text':            text,
    'is_read':         isRead,
    'created_at':      createdAt.toIso8601String(),
  };
}