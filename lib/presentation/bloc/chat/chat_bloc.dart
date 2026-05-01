import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dating_app/core/utils/offline_cache.dart';
import 'package:dating_app/domain/entities/message_entity.dart';
import 'package:dating_app/domain/repositories/chat_repository.dart';
import 'package:dating_app/presentation/bloc/chat/chat_event.dart';
import 'package:dating_app/presentation/bloc/chat/chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription<MessageEntity>? _msgSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connSubscription;

  ChatBloc(this._chatRepository) : super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<ResendQueuedMessages>(_onResendQueued);
    on<UpdateMessageStatus>(_onUpdateStatus);

    // Monitor connectivity to trigger resend
    _connSubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.first != ConnectivityResult.none) {
        final current = state;
        if (current is ChatLoaded && current.messages.isNotEmpty) {
          add(ResendQueuedMessages(conversationId: current.messages.first.conversationId));
        }
      }
    });
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(ChatLoading());
      
      // 1. Fetch from server
      final serverMessages = await _chatRepository.getMessages(event.conversationId);
      
      // 2. Fetch queued from local Hive
      final queuedMessages = OfflineCache.getQueuedMessages(event.conversationId);
      
      final allMessages = [...serverMessages, ...queuedMessages];
      allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      emit(ChatLoaded(messages: allMessages));

      // Mark as read
      await _chatRepository.markAsRead(event.conversationId, event.currentUserId);

      // Subscribe to real-time
      await _msgSubscription?.cancel();
      _msgSubscription = _chatRepository
          .subscribeToMessages(event.conversationId)
          .listen((message) => add(MessageReceived(message)));
          
    } catch (e) {
      // If server fails, show cached messages + queue
      final queued = OfflineCache.getQueuedMessages(event.conversationId);
      if (queued.isNotEmpty) {
        emit(ChatLoaded(messages: queued));
      } else {
        emit(ChatError(e.toString()));
      }
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final pendingMsg = MessageEntity(
      id: tempId,
      conversationId: event.conversationId,
      senderId: event.senderId,
      text: event.text,
      isRead: false,
      createdAt: DateTime.now(),
      status: MessageStatus.pending,
    );

    // Optimistic UI update: Show pending message immediately
    emit(current.copyWith(
      messages: [...current.messages, pendingMsg],
    ));

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.first == ConnectivityResult.none) {
      // Offline: Keep in Hive queue
      await OfflineCache.enqueueMessage(pendingMsg);
      return;
    }

    try {
      await _chatRepository.sendMessage(
        conversationId: event.conversationId,
        senderId: event.senderId,
        text: event.text,
      );
      // Real-time sub will receive the 'sent' message and UpdateMessageReceived will handle it
    } catch (e) {
      // Failed (Online error): Mark as error in memory and queue for later
      await OfflineCache.enqueueMessage(pendingMsg);
      add(UpdateMessageStatus(messageId: tempId, status: MessageStatus.error));
    }
  }

  Future<void> _onResendQueued(
    ResendQueuedMessages event,
    Emitter<ChatState> emit,
  ) async {
    final queued = OfflineCache.getQueuedMessages(event.conversationId);
    if (queued.isEmpty) return;

    for (var msg in queued) {
      try {
        await _chatRepository.sendMessage(
          conversationId: msg.conversationId,
          senderId: msg.senderId,
          text: msg.text,
        );
        await OfflineCache.dequeueMessage(msg.id);
        // Note: The real-time stream will add the formal message with DB ID
      } catch (_) {
        // Still failing, leave in queue
      }
    }
  }

  void _onUpdateStatus(UpdateMessageStatus event, Emitter<ChatState> emit) {
    final current = state;
    if (current is! ChatLoaded) return;

    final updated = current.messages.map((m) {
      if (m.id == event.messageId) return m.copyWith(status: event.status);
      return m;
    }).toList();

    emit(current.copyWith(messages: updated));
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final current = state;
    if (current is! ChatLoaded) return;

    // Remove any temporary local pending messages that match this text/sender
    // to avoid "double-bubbles" when the message comes back from the server.
    final List<MessageEntity> updated = List.from(current.messages);
    updated.removeWhere((m) => 
      m.status != MessageStatus.sent && 
      m.text == event.message.text && 
      m.senderId == event.message.senderId
    );

    // Avoid duplicates for sent messages
    if (!updated.any((m) => m.id == event.message.id)) {
      updated.add(event.message);
    }
    
    updated.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    emit(current.copyWith(messages: updated));
  }

  @override
  Future<void> close() {
    _msgSubscription?.cancel();
    _connSubscription?.cancel();
    return super.close();
  }
}
