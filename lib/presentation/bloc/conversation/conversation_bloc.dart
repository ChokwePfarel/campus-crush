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
  }

  Future<void> _onLoad(
      LoadConversations event,
      Emitter<ConversationsState> emit,
      ) async {
    debugPrint('ConversationsBloc: _onLoad started for user: ${event.currentUserId}');
    
    // ── Step 1: Show cached data immediately (zero-wait) ───────────────────
    try {
      final cached = OfflineCache.getCachedConversations(event.currentUserId);
      debugPrint('ConversationsBloc: Cached conversations found: ${cached.length}');
      if (cached.isNotEmpty) {
        emit(ConversationsLoaded(conversations: cached, unreadCount: 0));
      } else {
        debugPrint('ConversationsBloc: No cache found, emitting Loading');
        emit(ConversationsLoading());
      }
    } catch (e) {
      debugPrint('ConversationsBloc: Error reading cache: $e');
      emit(ConversationsLoading());
    }

    // ── Step 2: Fetch from server and merge ────────────────────────────────
    try {
      debugPrint('ConversationsBloc: Fetching from network...');
      final conversations =
      await _chatRepository.getConversations(event.currentUserId);
      debugPrint('ConversationsBloc: Network fetch success. Count: ${conversations.length}');
      
      final unreadCount =
      await _chatRepository.getUnreadCount(event.currentUserId);

      // Persist fresh data for next cold start
      final models = conversations.whereType<ConversationModel>().toList();
      if (models.isNotEmpty) {
        debugPrint('ConversationsBloc: Caching ${models.length} fresh conversations');
        await OfflineCache.cacheConversations(event.currentUserId, models);
      }

      emit(
        ConversationsLoaded(
          conversations: conversations,
          unreadCount: unreadCount,
        ),
      );
      debugPrint('ConversationsBloc: Emitted ConversationsLoaded with fresh data');

      // ── Step 3: Subscribe to real-time updates ─────────────────────────
      await _subscription?.cancel();
      _subscription = _chatRepository
          .subscribeToConversations(event.currentUserId)
          .listen((updated) {
        debugPrint('ConversationsBloc: Real-time update received for conversation: ${updated.id}');
        add(ConversationUpdated(updated));
        add(RefreshUnreadCount(event.currentUserId));
      });
    } catch (e) {
      debugPrint('ConversationsBloc: Network fetch error: $e');
      // Server failed — if we already emitted cache, stay there silently.
      // Otherwise surface the error.
      if (state is! ConversationsLoaded) {
        debugPrint('ConversationsBloc: Emitting error because no cache was shown');
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

    // Sort by most recent message
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

  @override
  Future<void> close() {
    debugPrint('ConversationsBloc: Closing');
    _subscription?.cancel();
    _chatRepository.dispose();
    return super.close();
  }
}
