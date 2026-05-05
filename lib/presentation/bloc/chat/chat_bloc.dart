
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dating_app/core/utils/offline_cache.dart';
import 'package:dating_app/data/models/message_model.dart';
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

    // Trigger outbox flush whenever connectivity is restored
    _connSubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.first != ConnectivityResult.none) {
        final current = state;
        if (current is ChatLoaded && current.messages.isNotEmpty) {
          add(
            ResendQueuedMessages(
              conversationId: current.messages.first.conversationId,
            ),
          );
        }
      }
    });
  }

  // ─── Load Messages ─────────────────────────────────────────────────────────

  Future<void> _onLoadMessages(
      LoadMessages event,
      Emitter<ChatState> emit,
      ) async {
    // ── Step 1: Emit cached + queued instantly ───────────────────────────
    final cachedMessages = OfflineCache.getCachedMessages(event.conversationId);
    final queuedMessages = OfflineCache.getQueuedMessages(event.conversationId);

    if (cachedMessages.isNotEmpty || queuedMessages.isNotEmpty) {
      final combined = _merge(cachedMessages, queuedMessages);
      emit(ChatLoaded(messages: combined));
    } else {
      emit(ChatLoading());
    }

    // ── Step 2: Fetch from server and merge ──────────────────────────────
    try {
      final serverMessages =
      await _chatRepository.getMessages(event.conversationId);

      // Persist to cache (only confirmed server messages, not pending ones)
      final models = serverMessages
          .whereType<MessageModel>()
          .toList();
      if (models.isNotEmpty) {
        await OfflineCache.cacheMessageHistory(event.conversationId, models);
      }

      // Merge server messages with any still-pending queued messages.
      // Queued messages whose text+senderId appear in serverMessages are
      // considered delivered and dropped from the combined list.
      final serverIds = serverMessages.map((m) => m.id).toSet();
      final stillQueued = queuedMessages
          .where((q) => !serverMessages.any(
            (s) => s.text == q.text && s.senderId == q.senderId,
      ))
          .toList();

      final allMessages = _merge(serverMessages, stillQueued);
      emit(ChatLoaded(messages: allMessages));

      // Mark conversation as read
      await _chatRepository.markAsRead(
        event.conversationId,
        event.currentUserId,
      );

      // ── Step 3: Subscribe to real-time stream ──────────────────────────
      await _msgSubscription?.cancel();
      _msgSubscription = _chatRepository
          .subscribeToMessages(event.conversationId)
          .listen((message) => add(MessageReceived(message)));
    } catch (e) {
      // Server failed — if we already showed cache, stay silent.
      // If we showed the loading spinner (no cache), surface the error.
      final current = state;
      if (current is! ChatLoaded) {
        emit(ChatError(e.toString()));
      }
    }
  }

  // ─── Send Message ──────────────────────────────────────────────────────────

  Future<void> _onSendMessage(
      SendMessage event,
      Emitter<ChatState> emit,
      ) async {
    final current = state;
    if (current is! ChatLoaded) return;

    // Unique local ID — used to track this message through its lifecycle
    final tempId  = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final pending = MessageEntity(
      id:             tempId,
      conversationId: event.conversationId,
      senderId:       event.senderId,
      text:           event.text,
      isRead:         false,
      createdAt:      DateTime.now(),
      status:         MessageStatus.pending,
    );

    // Optimistic update — show bubble immediately
    emit(current.copyWith(messages: [...current.messages, pending]));

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.first == ConnectivityResult.none) {
      // Offline: persist to outbox and exit — will resend when online
      await OfflineCache.enqueueMessage(pending);
      return;
    }

    try {
      await _chatRepository.sendMessage(
        conversationId: event.conversationId,
        senderId:       event.senderId,
        text:           event.text,
      );
      // The real-time subscription will fire with the confirmed server message.
      // _onMessageReceived will replace the temp bubble using tempId matching.
    } catch (e) {
      // Online but failed — queue for later and mark as error
      await OfflineCache.enqueueMessage(pending);
      add(UpdateMessageStatus(messageId: tempId, status: MessageStatus.error));
    }
  }

  // ─── Resend Queued Messages ────────────────────────────────────────────────

  Future<void> _onResendQueued(
      ResendQueuedMessages event,
      Emitter<ChatState> emit,
      ) async {
    final queued = OfflineCache.getQueuedMessages(event.conversationId);
    if (queued.isEmpty) return;

    for (final msg in queued) {
      try {
        await _chatRepository.sendMessage(
          conversationId: msg.conversationId,
          senderId:       msg.senderId,
          text:           msg.text,
        );
        // Remove from outbox — the real-time sub will add the confirmed copy
        await OfflineCache.dequeueMessage(msg.id);
      } catch (_) {
        // Still failing — leave it in the queue for the next retry
      }
    }
  }

  // ─── Update Message Status ─────────────────────────────────────────────────

  void _onUpdateStatus(
      UpdateMessageStatus event,
      Emitter<ChatState> emit,
      ) {
    final current = state;
    if (current is! ChatLoaded) return;

    final updated = current.messages.map((m) {
      return m.id == event.messageId ? m.copyWith(status: event.status) : m;
    }).toList();

    emit(current.copyWith(messages: updated));
  }

  // ─── Message Received (real-time) ─────────────────────────────────────────

  void _onMessageReceived(
      MessageReceived event,
      Emitter<ChatState> emit,
      ) {
    final current = state;
    if (current is! ChatLoaded) return;

    final List<MessageEntity> updated = List.from(current.messages);

    // Remove the optimistic temp bubble that this server message confirms.
    // We match on text + senderId because the tempId is local-only.
    // Only remove messages that are NOT yet confirmed (pending/error) to
    // avoid accidentally wiping a second identical message.
    bool removedTemp = false;
    updated.removeWhere((m) {
      if (!removedTemp &&
          m.status != MessageStatus.sent &&
          m.text == event.message.text &&
          m.senderId == event.message.senderId) {
        removedTemp = true; // Remove at most ONE temp bubble per delivery
        return true;
      }
      return false;
    });

    // Avoid duplicates from the stream firing more than once
    if (!updated.any((m) => m.id == event.message.id)) {
      updated.add(event.message);
    }

    updated.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    emit(current.copyWith(messages: updated));
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Merge two lists, sort by createdAt, and de-duplicate by id.
  List<MessageEntity> _merge(
      List<MessageEntity> a,
      List<MessageEntity> b,
      ) {
    final seen  = <String>{};
    final merged = <MessageEntity>[];
    for (final m in [...a, ...b]) {
      if (seen.add(m.id)) merged.add(m);
    }
    merged.sort((x, y) => x.createdAt.compareTo(y.createdAt));
    return merged;
  }

  @override
  Future<void> close() {
    _msgSubscription?.cancel();
    _connSubscription?.cancel();
    return super.close();
  }
}



/*
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
*/


