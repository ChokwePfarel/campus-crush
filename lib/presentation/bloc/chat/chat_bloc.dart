
import 'dart:async';
import 'package:dating_app/domain/entities/message_entity.dart';
import 'package:dating_app/domain/repositories/chat_repository.dart';
import 'package:dating_app/presentation/bloc/chat/chat_event.dart';
import 'package:dating_app/presentation/bloc/chat/chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription<MessageEntity>? _subscription;

  ChatBloc(this._chatRepository) : super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);

  }

  Future<void> _onLoadMessages(
      LoadMessages event,
      Emitter<ChatState> emit,
      ) async {
    try {
      emit(ChatLoading());
      final messages =
      await _chatRepository.getMessages(event.conversationId);
      emit(ChatLoaded(messages: messages));

      // Mark messages as read
      await _chatRepository.markAsRead(
          event.conversationId, event.currentUserId);

      // Subscribe to real-time new messages
      await _subscription?.cancel();
      _subscription = _chatRepository
          .subscribeToMessages(event.conversationId)
          .listen((message) => add(MessageReceived(message)));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onSendMessage(
      SendMessage event,
      Emitter<ChatState> emit,
      ) async {
    final current = state;
    if (current is! ChatLoaded) return;

    emit(current.copyWith(isSending: true));

    try {
      await _chatRepository.sendMessage(
        conversationId: event.conversationId,
        senderId:       event.senderId,
        text:           event.text,
      );
      // Real-time subscription will add the message to the list
      emit(current.copyWith(isSending: false));
    } catch (e) {
      emit(current.copyWith(isSending: false));
      emit(ChatError(e.toString()));
    }
  }

  void _onMessageReceived(
      MessageReceived event,
      Emitter<ChatState> emit,
      ) {
    final current = state;
    if (current is! ChatLoaded) return;

    // Avoid duplicates
    final exists = current.messages.any((m) => m.id == event.message.id);
    if (exists) return;

    emit(current.copyWith(
      messages: [...current.messages, event.message],
    ));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}