
import 'package:dating_app/domain/entities/message_entity.dart';

abstract class ChatEvent {}

class LoadMessages extends ChatEvent {
  final String conversationId;
  final String currentUserId;
  LoadMessages({required this.conversationId, required this.currentUserId});
}

class SendMessage extends ChatEvent {
  final String conversationId;
  final String senderId;
  final String text;
  SendMessage({
    required this.conversationId,
    required this.senderId,
    required this.text,
  });
}

class MessageReceived extends ChatEvent {
  final MessageEntity message;
  MessageReceived(this.message);
}