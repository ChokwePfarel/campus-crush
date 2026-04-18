import 'package:dating_app/domain/entities/conversation_entity.dart';
import 'package:dating_app/domain/entities/message_entity.dart';

class MessageMock {



  static final demoMessages = [

  MessageEntity(
  id: 'm1', conversationId: 'c1', senderId: 'u2',
  text: 'Hey! I saw your spotted post at the library 👀',
  isRead: true,
  createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
  ),
  MessageEntity(
  id: 'm2', conversationId: 'c1', senderId: 'u_mock_001',
  text: 'Haha yep that was me! Red hoodie 😅',
  isRead: true,
  createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
  ),
  MessageEntity(
  id: 'm3', conversationId: 'c1', senderId: 'u2',
  text: 'I thought it might be! You\'re always at the library around this time',
  isRead: true,
  createdAt: DateTime.now().subtract(const Duration(minutes: 38)),
  ),
  MessageEntity(
  id: 'm4', conversationId: 'c1', senderId: 'u_mock_001',
  text: 'Finals season has me basically living here 😭',
  isRead: true,
  createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
  ),
  MessageEntity(
  id: 'm5', conversationId: 'c1', senderId: 'u2',
  text: 'Same honestly. What are you studying?',
  isRead: true,
  createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
  ),
  MessageEntity(
  id: 'm6', conversationId: 'c1', senderId: 'u_mock_001',
  text: 'Psychology 3rd year. You?',
  isRead: true,
  createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
  ),
  MessageEntity(
  id: 'm7', conversationId: 'c1', senderId: 'u2',
  text: 'Law! We should study together sometime ☕',
  isRead: false,
  createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
  ),
  ];
}

class ConversationMock {
  static final demoConversations = [
    ConversationEntity(
      id: 'c1', userOneId: 'u1', userTwoId: 'u2',
      lastMessage: 'Hey, I saw your spotted post at the library 👀',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      otherUserName: 'Lerato Mokoena',
      otherUserImageUrl: 'https://i.pravatar.cc/150?u=lerato',
      otherUserIsVerified: true,
      unreadCount: 2,
    ),
    ConversationEntity(
      id: 'c2', userOneId: 'u1', userTwoId: 'u3',
      lastMessage: 'That confession was definitely about me 😅',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      otherUserName: 'Sipho Khumalo',
      otherUserImageUrl: 'https://i.pravatar.cc/150?u=sipho',
      otherUserIsVerified: false,
      unreadCount: 1,
    ),
    ConversationEntity(
      id: 'c3', userOneId: 'u1', userTwoId: 'u4',
      lastMessage: 'Are you coming to the braai on Friday?',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      otherUserName: 'Nomvula Petersen',
      otherUserImageUrl: 'https://i.pravatar.cc/150?u=nomvula',
      otherUserIsVerified: true,
      unreadCount: 0,
    ),
    ConversationEntity(
      id: 'c4', userOneId: 'u1', userTwoId: 'u5',
      lastMessage: 'Thanks for the notes 🙏',
      lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      otherUserName: 'Thabo Nkosi',
      otherUserImageUrl: 'https://i.pravatar.cc/150?u=thabo',
      otherUserIsVerified: false,
      unreadCount: 5,
    ),
  ];
}