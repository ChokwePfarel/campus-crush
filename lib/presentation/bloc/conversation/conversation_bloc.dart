import 'dart:async';

import 'package:dating_app/core/utils/offline_cache.dart';
import 'package:dating_app/data/models/conversation_model.dart';
import 'package:dating_app/domain/entities/conversation_entity.dart';
import 'package:dating_app/domain/repositories/chat_repository.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_event.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final ChatRepository _chatRepository;
  StreamSubscription? _subscription;

  ConversationsBloc(this._chatRepository) : super(ConversationsInitial()) {
    on<LoadConversations>(_onLoad);
    on<OpenOrCreateConversation>(_onOpenOrCreate);
    on<ConversationUpdated>(_onConversationUpdated);
    on<RefreshUnreadCount>(_onRefreshUnreadCount);
    on<MarkConversationAsRead>(_onMarkAsRead);
  }

  Future<void> _onLoad(
      LoadConversations event,
      Emitter<ConversationsState> emit,
      ) async {
    debugPrint('ConversationsBloc: _onLoad started for user: ${event.currentUserId}');
    
    try {
      final cached = OfflineCache.getCachedConversations(event.currentUserId);
      if (cached.isNotEmpty) {
        emit(ConversationsLoaded(conversations: cached, unreadCount: 0));
      } else {
        emit(ConversationsLoading());
      }
    } catch (e) {
      emit(ConversationsLoading());
    }

    try {
      final conversations =
      await _chatRepository.getConversations(event.currentUserId);
      final unreadCount =
      await _chatRepository.getUnreadCount(event.currentUserId);

      final models = conversations.whereType<ConversationModel>().toList();
      if (models.isNotEmpty) {
        await OfflineCache.cacheConversations(event.currentUserId, models);
      }

      emit(
        ConversationsLoaded(
          conversations: conversations,
          unreadCount: unreadCount,
        ),
      );

      await _subscription?.cancel();
      _subscription = _chatRepository
          .subscribeToConversations(event.currentUserId)
          .listen((updated) {
        add(ConversationUpdated(updated));
        add(RefreshUnreadCount(event.currentUserId));
      });
    } catch (e) {
      if (state is! ConversationsLoaded) {
        emit(ConversationsError(e.toString()));
      }
    }
  }

  Future<void> _onOpenOrCreate(
      OpenOrCreateConversation event,
      Emitter<ConversationsState> emit,
      ) async {
    try {
      emit(ConversationsLoading());
      final conversation = await _chatRepository.getOrCreateConversation(
        currentUserId: event.currentUserId,
        otherUserId:   event.otherUserId,
      );
      emit(ConversationReady(conversation));
    } catch (e) {
      emit(ConversationsError(e.toString()));
    }
  }

  void _onConversationUpdated(
      ConversationUpdated event,
      Emitter<ConversationsState> emit,
      ) {
    final current = state;
    if (current is! ConversationsLoaded) return;

    final updatedList = current.conversations.map((c) {
      return c.id == event.conversation.id ? event.conversation : c;
    }).toList();

    updatedList.sort(
          (ConversationEntity a, ConversationEntity b) =>
          (b.lastMessageAt ?? b.createdAt)
              .compareTo(a.lastMessageAt ?? a.createdAt),
    );

    emit(current.copyWith(conversations: updatedList));
  }

  Future<void> _onRefreshUnreadCount(
      RefreshUnreadCount event,
      Emitter<ConversationsState> emit,
      ) async {
    final current = state;
    if (current is! ConversationsLoaded) return;
    try {
      final count = await _chatRepository.getUnreadCount(event.currentUserId);
      emit(current.copyWith(unreadCount: count));
    } catch (_) {}
  }

  void _onMarkAsRead(
      MarkConversationAsRead event,
      Emitter<ConversationsState> emit,
      ) {
    final current = state;
    if (current is! ConversationsLoaded) return;

    final updatedConversations = current.conversations.map((c) {
      if (c.id == event.conversationId) {
        // Optimistically set unreadCount to 0 for this conversation
        if (c is ConversationModel) {
            // Need a way to copy with unreadCount 0. 
            // Assuming ConversationModel has copyWith or similar, 
            // but the Entity doesn't. 
            // Let's create a new Model instance with 0 unread.
            return ConversationModel(
              id: c.id,
              userOneId: c.userOneId,
              userTwoId: c.userTwoId,
              lastMessage: c.lastMessage,
              lastMessageAt: c.lastMessageAt,
              createdAt: c.createdAt,
              otherUserName: c.otherUserName,
              otherUserImageUrl: c.otherUserImageUrl,
              otherUserIsVerified: c.otherUserIsVerified,
              unreadCount: 0,
            );
        }
        return c;
      }
      return c;
    }).toList();

    emit(current.copyWith(conversations: updatedConversations));
    add(RefreshUnreadCount(event.currentUserId));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _chatRepository.dispose();
    return super.close();
  }
}
