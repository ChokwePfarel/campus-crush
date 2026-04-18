import 'dart:async';
import 'package:dating_app/core/constants/message_mock.dart';
import 'package:dating_app/data/datasources/chat_remote_data_source.dart';
import 'package:dating_app/domain/entities/conversation_entity.dart';
import 'package:dating_app/domain/entities/message_entity.dart';
import 'package:dating_app/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _dataSource;

  ChatRepositoryImpl(this._dataSource);

  @override
  Future<List<ConversationEntity>> getConversations(String userId) =>
      _dataSource.getConversations(userId);

  @override
  Future<ConversationEntity> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
  }) =>
      _dataSource.getOrCreateConversation(
        currentUserId: currentUserId,
        otherUserId:   otherUserId,
      );

  @override
  Future<List<MessageEntity>> getMessages(String conversationId) =>
      _dataSource.getMessages(conversationId);

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) =>
      _dataSource.sendMessage(
        conversationId: conversationId,
        senderId:       senderId,
        text:           text,
      );

  @override
  Future<void> markAsRead(String conversationId, String currentUserId) =>
      _dataSource.markAsRead(conversationId, currentUserId);

  @override
  Stream<MessageEntity> subscribeToMessages(String conversationId) =>
      _dataSource.subscribeToMessages(conversationId);

  @override
  Stream<ConversationEntity> subscribeToConversations(String userId) =>
      _dataSource.subscribeToConversations(userId);

  @override
  void dispose() => _dataSource.dispose();

  @override
  Future<int> getUnreadCount(String currentUserId) =>
      _dataSource.getUnreadCount(currentUserId);
}



// ─── Mock Implementation ─────────────────────────────────────────────────────

class MockChatRepositoryImpl implements ChatRepository {
  final _messageController = StreamController<MessageEntity>.broadcast();
  final _conversationController = StreamController<ConversationEntity>.broadcast();

  @override
  void dispose() {
    _messageController.close();
    _conversationController.close();
  }

  @override
  Future<List<ConversationEntity>> getConversations(String currentUserId) async {
    // Return mock data from your constants
    return ConversationMock.demoConversations;
  }

  @override
  Future<List<MessageEntity>> getMessages(String conversationId) async {
    // Return mock messages
    return MessageMock.demoMessages;
  }

  @override
  Future<ConversationEntity> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    // Return the first demo conversation as a fallback
    return ConversationMock.demoConversations.first;
  }

  @override
  Future<void> markAsRead(String conversationId, String currentUserId) async {
    print("Mock: Marked conversation $conversationId as read");
  }

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final newMessage = MessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      senderId: senderId,
      text: text,
      isRead: false,
      createdAt: DateTime.now(),
    );
    
    // Push to stream so ChatPage UI updates
    _messageController.add(newMessage);
    return newMessage;
  }

  @override
  Stream<ConversationEntity> subscribeToConversations(String currentUserId) {
    return _conversationController.stream;
  }

  @override
  Stream<MessageEntity> subscribeToMessages(String conversationId) {
    return _messageController.stream;
  }

  @override
  Future<int> getUnreadCount(String currentUserId) async {
    return 0;
  }
}
