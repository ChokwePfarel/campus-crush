
import 'package:dating_app/domain/entities/conversation_entity.dart';
import 'package:dating_app/domain/entities/message_entity.dart';

abstract class ChatRepository {
  Future<List<ConversationEntity>> getConversations(String currentUserId);
  Future<ConversationEntity> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
  });
  Future<List<MessageEntity>> getMessages(String conversationId);
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  });
  Future<void> markAsRead(String conversationId, String currentUserId);
  Stream<MessageEntity> subscribeToMessages(String conversationId);
  Stream<ConversationEntity> subscribeToConversations(String currentUserId);
  void dispose();

  Future<int> getUnreadCount(String currentUserId);

  Future<void> deleteMessage(String messageId);
}


