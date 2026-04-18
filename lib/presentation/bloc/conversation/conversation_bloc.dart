import 'dart:async';

import 'package:dating_app/domain/entities/conversation_entity.dart';
import 'package:dating_app/domain/repositories/chat_repository.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_event.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_state.dart';

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
    try {
      emit(ConversationsLoading());

      final conversations = await _chatRepository
          .getConversations(event.currentUserId);
      final unreadCount   = await _chatRepository
          .getUnreadCount(event.currentUserId);

      emit(ConversationsLoaded(conversations: conversations, unreadCount: unreadCount));


      // Real-time subscription — fires when any conversation is updated
      await _subscription?.cancel();
      _subscription = _chatRepository
          .subscribeToConversations(event.currentUserId)
          .listen((updated) {
        add(ConversationUpdated(updated));
        add(RefreshUnreadCount(event.currentUserId)); // refresh badge
      });
    } catch (e) {
      emit(ConversationsError(e.toString()));
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

    final updated = current.conversations.map((c) {
      return c.id == event.conversation.id ? event.conversation : c;
    }).toList();

    // Sort by latest message
    updated.sort((ConversationEntity a, ConversationEntity b) =>
        (b.lastMessageAt ?? b.createdAt)
            .compareTo(a.lastMessageAt ?? a.createdAt));

    emit(current.copyWith(conversations: updated));
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
    _subscription?.cancel();
    _chatRepository.dispose();
    return super.close();
  }
}
