
import 'package:dating_app/domain/entities/conversation_entity.dart';

abstract class ConversationsEvent {}

class LoadConversations extends ConversationsEvent {
  final String currentUserId;
  LoadConversations(this.currentUserId);
}

class OpenOrCreateConversation extends ConversationsEvent {
  final String currentUserId;
  final String otherUserId;
  OpenOrCreateConversation({
    required this.currentUserId,
    required this.otherUserId,
  });
}

class ConversationUpdated extends ConversationsEvent {
  final ConversationEntity conversation;
  ConversationUpdated(this.conversation);
}


class RefreshUnreadCount extends ConversationsEvent {
  final String currentUserId;
  RefreshUnreadCount(this.currentUserId);
}