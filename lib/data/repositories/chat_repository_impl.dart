/*
import 'dart:async';
import 'dart:io';
import 'package:dating_app/core/utils/offline_cache.dart';
import 'package:dating_app/data/datasources/chat_remote_data_source.dart';
import 'package:dating_app/data/models/conversation_model.dart';
import 'package:dating_app/data/models/message_model.dart';
import 'package:dating_app/domain/entities/conversation_entity.dart';
import 'package:dating_app/domain/entities/message_entity.dart';
import 'package:dating_app/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _dataSource;

  ChatRepositoryImpl(this._dataSource);

  @override
  Future<List<ConversationEntity>> getConversations(String userId) async {
    try {
      final conversations = await _dataSource.getConversations(userId);
      // Cache conversations for offline use
      final jsonList = conversations.map((c) => (c as ConversationModel).toJson()).toList();
      // We need a way to cache conversations specifically. Let's reuse Profiles for now or add to OfflineCache
      // For now, returning the network result.
      return conversations;
    } catch (e) {
      // In a full implementation, we'd pull from Hive here
      // return OfflineCache.getCachedConversations();
      rethrow;
    }
  }

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
  Future<List<MessageEntity>> getMessages(String conversationId) async {
    try {
      return await _dataSource.getMessages(conversationId);
    } catch (e) {
      // Fallback to local queue if network fails
      return OfflineCache.getQueuedMessages(conversationId);
    }
  }

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) =>
      _dataSource.sendMessage(

        text: text,
        conversationId: conversationId,
        senderId: senderId,
      );

  @override
  Future<void> markAsRead(String conversationId, String currentUserId) async {
    try {
      await _dataSource.markAsRead(conversationId, currentUserId);
    } catch (_) {
      // Ignore if offline
    }
  }

  @override
  Stream<MessageEntity> subscribeToMessages(String conversationId) =>
      _dataSource.subscribeToMessages(conversationId);

  @override
  Stream<ConversationEntity> subscribeToConversations(String userId) =>
      _dataSource.subscribeToConversations(userId);

  @override
  void dispose() => _dataSource.dispose();

  @override
  Future<int> getUnreadCount(String currentUserId) async {
     try {
       return await _dataSource.getUnreadCount(currentUserId);
     } catch (_) {
       return 0;
     }
  }
}
*/

import 'dart:async';

import 'package:dating_app/core/utils/offline_cache.dart';
import 'package:dating_app/data/datasources/chat_remote_data_source.dart';
import 'package:dating_app/data/models/conversation_model.dart';
import 'package:dating_app/data/models/message_model.dart';
import 'package:dating_app/domain/entities/conversation_entity.dart';
import 'package:dating_app/domain/entities/message_entity.dart';
import 'package:dating_app/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _dataSource;

  ChatRepositoryImpl(this._dataSource);

  // ─── Conversations ─────────────────────────────────────────────────────────

  @override
  Future<List<ConversationEntity>> getConversations(String userId) async {
    try {
      final conversations = await _dataSource.getConversations(userId);

      // Cache the fresh list for offline use
      final models = conversations.whereType<ConversationModel>().toList();
      if (models.isNotEmpty) {
        await OfflineCache.cacheConversations(userId, models);
      }

      return conversations;
    } catch (e) {
      // Network unavailable — serve from cache
      final cached = OfflineCache.getCachedConversations(userId);
      if (cached.isNotEmpty) return cached;
      rethrow; // No cache and no network — surface the error
    }
  }

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
  Future<List<MessageEntity>> getMessages(String conversationId) async {
    try {
      final messages = await _dataSource.getMessages(conversationId);

      // Cache confirmed server messages
      final models = messages.whereType<MessageModel>().toList();
      if (models.isNotEmpty) {
        await OfflineCache.cacheMessageHistory(conversationId, models);
      }

      return messages;
    } catch (e) {
      // Fall back to cached history + queued outbox
      final cached = OfflineCache.getCachedMessages(conversationId);
      final queued = OfflineCache.getQueuedMessages(conversationId);

      if (cached.isNotEmpty || queued.isNotEmpty) {
        final seen   = <String>{};
        final merged = <MessageEntity>[...cached, ...queued]
            .where((m) => seen.add(m.id))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return merged;
      }

      rethrow;
    }
  }

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
  Future<void> markAsRead(String conversationId, String currentUserId) async {
    try {
      await _dataSource.markAsRead(conversationId, currentUserId);
    } catch (_) {
      // Safe to ignore when offline — will be corrected on next fetch
    }
  }


  @override
  Stream<MessageEntity> subscribeToMessages(String conversationId) =>
      _dataSource.subscribeToMessages(conversationId);

  @override
  Stream<ConversationEntity> subscribeToConversations(String userId) =>
      _dataSource.subscribeToConversations(userId);


  @override
  Future<int> getUnreadCount(String currentUserId) async {
    try {
      return await _dataSource.getUnreadCount(currentUserId);
    } catch (_) {
      return 0;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    return _dataSource.deleteMessage(messageId);
  }

  @override
  void dispose() => _dataSource.dispose();
}