/*
import 'package:dating_app/domain/entities/conversation_entity.dart';
import 'package:dating_app/domain/entities/message_entity.dart';
import 'package:dating_app/domain/repositories/chat_repository.dart';
import 'package:dating_app/presentation/bloc/chat/chat_bloc.dart';
import 'package:dating_app/presentation/bloc/chat/chat_event.dart';
import 'package:dating_app/presentation/bloc/chat/chat_state.dart';
import 'package:dating_app/presentation/pages/other_user_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dayLabel(DateTime dt) {
  final now = DateTime.now();
  if (_isSameDay(dt, now)) return 'Today';
  if (_isSameDay(dt, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  return '${dt.day}/${dt.month}/${dt.year}';
}

// ─── ChatPage ─────────────────────────────────────────────────────────────────

class ChatPage extends StatefulWidget {
  final ConversationEntity conversation;
  final String currentUserId;

  const ChatPage({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = false}) {
    if (!_scrollCtrl.hasClients) return;
    if (animated) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
  }

  void _sendMessage(BuildContext context) {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    context.read<ChatBloc>().add(
      SendMessage(
        conversationId: widget.conversation.id,
        senderId: widget.currentUserId,
        text: text,
      ),
    );
    _inputCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final String otherUserId =
        widget.conversation.userOneId == widget.currentUserId
        ? widget.conversation.userTwoId
        : widget.conversation.userOneId;

    return BlocProvider(
      create: (context) => ChatBloc(context.read<ChatRepository>())
        ..add(
          LoadMessages(
            conversationId: widget.conversation.id,
            currentUserId: widget.currentUserId,
          ),
        ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7FB),
        body: Column(
          children: [
            _buildAppBar(otherUserId),
            Expanded(child: _buildMessageList()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar(String otherUserId) {
    final conv = widget.conversation;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 16,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEF4), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(
              CupertinoIcons.chevron_left,
              color: Color(0xFF1A1A2E),
              size: 22,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtherUserProfilePage(userId: otherUserId),
                ),
              );
            },
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF4D6D).withOpacity(0.1),
                        image: conv.otherUserImageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(conv.otherUserImageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        border: Border.all(
                          color: const Color(0xFFFF4D6D).withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: conv.otherUserImageUrl.isEmpty
                          ? const Center(
                              child: Text('👤', style: TextStyle(fontSize: 18)),
                            )
                          : null,
                    ),
                    if (conv.otherUserIsVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2EC4B6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 7,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conv.otherUserName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      'Tap to view profile',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Message List ───────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatLoaded) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(animated: true),
          );
        }
      },
      builder: (context, state) {
        if (state is ChatLoading) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (state is ChatError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        if (state is ChatLoaded) {
          final messages = state.messages;
          final items = <dynamic>[];
          for (var i = 0; i < messages.length; i++) {
            final msg = messages[i];
            final isFirst = i == 0;
            final prevMsg = isFirst ? null : messages[i - 1];

            if (isFirst || !_isSameDay(msg.createdAt, prevMsg!.createdAt)) {
              items.add(msg.createdAt); // day separator
            }
            items.add(msg);
          }

          return ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              if (item is DateTime) return _DaySeparator(date: item);
              final msg = item as MessageEntity;
              final isMe = msg.senderId == widget.currentUserId;

              final nextItem = i + 1 < items.length ? items[i + 1] : null;
              final isLastInGroup =
                  nextItem == null ||
                  nextItem is DateTime ||
                  (nextItem is MessageEntity &&
                      nextItem.senderId != msg.senderId);

              return _MessageBubble(
                message: msg,
                isMe: isMe,
                isLastInGroup: isLastInGroup,
                otherUserImageUrl: widget.conversation.otherUserImageUrl,
              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  // ── Input Bar ──────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    final bottom = MediaQuery.of(context).padding.bottom;

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFEEEEF4), width: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F8),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _inputCtrl,
                      focusNode: _focusNode,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _sendMessage(context),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1A1A2E),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: Color(0xFFB0B0C0),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: _inputCtrl.text.trim().isNotEmpty 
                      ? () => _sendMessage(context) 
                      : null,
                  icon: Icon(
                    CupertinoIcons.arrow_up_circle_fill,
                    size: 36,
                    color: _inputCtrl.text.trim().isNotEmpty
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFFE8E8F0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final bool isLastInGroup;
  final String otherUserImageUrl;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isLastInGroup,
    required this.otherUserImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLastInGroup ? 12 : 3,
        top: 0,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            isLastInGroup
                ? Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF4D6D).withOpacity(0.1),
                      image: otherUserImageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(otherUserImageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: otherUserImageUrl.isEmpty
                        ? const Center(child: Text('👤', style: TextStyle(fontSize: 12)))
                        : null,
                  )
                : const SizedBox(width: 36),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: message.status == MessageStatus.pending ? 0.6 : 1.0,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? const LinearGradient(
                              colors: [Color(0xFFFF4D6D), Color(0xFF6C63FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isMe ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe || !isLastInGroup ? 18 : 4),
                        bottomRight: Radius.circular(!isMe || !isLastInGroup ? 18 : 4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: isMe ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ),
                if (isLastInGroup)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sent:
        return Icon(
          message.isRead ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.checkmark_alt,
          size: 12,
          color: message.isRead ? const Color(0xFF2EC4B6) : Colors.grey.shade400,
        );
      case MessageStatus.pending:
        return const Icon(CupertinoIcons.clock, size: 12, color: Colors.grey);
      case MessageStatus.error:
        return const Icon(CupertinoIcons.exclamationmark_circle_fill, size: 12, color: Colors.redAccent);
    }
  }
}

// ─── Day Separator ────────────────────────────────────────────────────────────

class _DaySeparator extends StatelessWidget {
  final DateTime date;
  const _DaySeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade200, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _dayLabel(date),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade400),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade200, height: 1)),
        ],
      ),
    );
  }
}
*/

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dating_app/domain/entities/conversation_entity.dart';
import 'package:dating_app/domain/entities/message_entity.dart';
import 'package:dating_app/domain/repositories/chat_repository.dart';
import 'package:dating_app/presentation/bloc/chat/chat_bloc.dart';
import 'package:dating_app/presentation/bloc/chat/chat_event.dart';
import 'package:dating_app/presentation/bloc/chat/chat_state.dart';
import 'package:dating_app/presentation/pages/other_user_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dayLabel(DateTime dt) {
  final now = DateTime.now();
  if (_isSameDay(dt, now)) return 'Today';
  if (_isSameDay(dt, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  return '${dt.day}/${dt.month}/${dt.year}';
}

// ─── ChatPage ─────────────────────────────────────────────────────────────────

class ChatPage extends StatefulWidget {
  final ConversationEntity conversation;
  final String currentUserId;

  const ChatPage({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode  = FocusNode();

  // Track the message count so we only auto-scroll when new messages arrive,
  // not on every state rebuild.
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = false}) {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    if (animated) {
      _scrollCtrl.animateTo(
        max,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(max);
    }
  }

  // FIX 1: Accept the bloc explicitly so we're never calling
  // context.read<ChatBloc>() from a context that sits above the BlocProvider.
  void _sendMessage(ChatBloc bloc) {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    bloc.add(
      SendMessage(
        conversationId: widget.conversation.id,
        senderId:       widget.currentUserId,
        text:           text,
      ),
    );
    _inputCtrl.clear();
    // Scroll after the new bubble is painted
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToBottom(animated: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String otherUserId =
    widget.conversation.userOneId == widget.currentUserId
        ? widget.conversation.userTwoId
        : widget.conversation.userOneId;

    return BlocProvider(
      create: (ctx) => ChatBloc(ctx.read<ChatRepository>())
        ..add(
          LoadMessages(
            conversationId: widget.conversation.id,
            currentUserId:  widget.currentUserId,
          ),
        ),
      // FIX 1 (cont.): Use Builder so every child widget gets a context
      // that is *below* the BlocProvider and can safely call context.read<ChatBloc>().
      child: Builder(
        builder: (ctx) {
          final chatBloc = ctx.read<ChatBloc>();
          return Scaffold(
            backgroundColor: const Color(0xFFF7F7FB),
            body: Column(
              children: [
                _buildAppBar(ctx, otherUserId),
                // FIX 3: Offline banner — sits between app bar and messages
                _OfflineBanner(conversationId: widget.conversation.id),
                Expanded(child: _buildMessageList(chatBloc)),
                _buildInputBar(ctx, chatBloc),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext ctx, String otherUserId) {
    final conv = widget.conversation;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(ctx).padding.top + 8,
        left: 8,
        right: 16,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEF4), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Icon(
              CupertinoIcons.chevron_left,
              color: Color(0xFF1A1A2E),
              size: 22,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => OtherUserProfilePage(userId: otherUserId),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF4D6D).withOpacity(0.1),
                        image: conv.otherUserImageUrl.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(conv.otherUserImageUrl),
                          fit: BoxFit.cover,
                        )
                            : null,
                        border: Border.all(
                          color: const Color(0xFFFF4D6D).withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: conv.otherUserImageUrl.isEmpty
                          ? const Center(
                        child: Text('👤', style: TextStyle(fontSize: 18)),
                      )
                          : null,
                    ),
                    if (conv.otherUserIsVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2EC4B6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 7,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conv.otherUserName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      'Tap to view profile',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Message List ───────────────────────────────────────────────────────────

  Widget _buildMessageList(ChatBloc chatBloc) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (ctx, state) {
        if (state is ChatLoaded) {
          // FIX 2: Only scroll when the message count actually increases
          // (new message arrived), not on every state emission.
          final count = state.messages.length;
          if (count > _lastMessageCount) {
            _lastMessageCount = count;
            WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(animated: _lastMessageCount > 1),
            );
          }
        }
      },
      builder: (ctx, state) {
        if (state is ChatLoading) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (state is ChatError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        if (state is ChatLoaded) {
          final messages = state.messages;
          final items    = <dynamic>[];

          for (var i = 0; i < messages.length; i++) {
            final msg     = messages[i];
            final prevMsg = i == 0 ? null : messages[i - 1];
            if (i == 0 || !_isSameDay(msg.createdAt, prevMsg!.createdAt)) {
              items.add(msg.createdAt); // day separator
            }
            items.add(msg);
          }

          return ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              if (item is DateTime) return _DaySeparator(date: item);

              final msg          = item as MessageEntity;
              final isMe         = msg.senderId == widget.currentUserId;
              final nextItem     = i + 1 < items.length ? items[i + 1] : null;
              final isLastInGroup =
                  nextItem == null ||
                      nextItem is DateTime ||
                      (nextItem is MessageEntity &&
                          nextItem.senderId != msg.senderId);

              return _MessageBubble(
                message:           msg,
                isMe:              isMe,
                isLastInGroup:     isLastInGroup,
                otherUserImageUrl: widget.conversation.otherUserImageUrl,
                // Enhancement: tap error bubble to retry
                onRetry: msg.status == MessageStatus.error
                    ? () => chatBloc.add(
                  ResendQueuedMessages(
                    conversationId: widget.conversation.id,
                  ),
                )
                    : null,
              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  // ── Input Bar ──────────────────────────────────────────────────────────────

  Widget _buildInputBar(BuildContext ctx, ChatBloc chatBloc) {
    final bottom = MediaQuery.of(ctx).padding.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFEEEEF4), width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  focusNode: _focusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _sendMessage(chatBloc),
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Color(0xFFB0B0C0), fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              padding: EdgeInsets.zero,
              onPressed: _inputCtrl.text.trim().isNotEmpty
                  ? () => _sendMessage(chatBloc)
                  : null,
              icon: Icon(
                CupertinoIcons.arrow_up_circle_fill,
                size: 36,
                color: _inputCtrl.text.trim().isNotEmpty
                    ? const Color(0xFF6C63FF)
                    : const Color(0xFFE8E8F0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Offline Banner ───────────────────────────────────────────────────────────

/// FIX 3: Watches connectivity and shows a slim banner when offline.
/// Dismisses automatically when the connection is restored.
class _OfflineBanner extends StatefulWidget {
  final String conversationId;
  const _OfflineBanner({required this.conversationId});

  @override
  State<_OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<_OfflineBanner> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    // Check initial state
    Connectivity().checkConnectivity().then((results) {
      if (mounted) {
        setState(() => _isOffline = results.first == ConnectivityResult.none);
      }
    });
    // Listen for changes
    Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() => _isOffline = results.first == ConnectivityResult.none);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: _isOffline
          ? Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        color: const Color(0xFFFF4D6D),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.wifi_slash, size: 13, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'You\'re offline — messages will send when reconnected',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : const SizedBox.shrink(),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final bool isLastInGroup;
  final String otherUserImageUrl;
  final VoidCallback? onRetry; // Enhancement: retry on error tap

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isLastInGroup,
    required this.otherUserImageUrl,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLastInGroup ? 12 : 3),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            isLastInGroup
                ? Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4D6D).withOpacity(0.1),
                image: otherUserImageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(otherUserImageUrl),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: otherUserImageUrl.isEmpty
                  ? const Center(
                child: Text('👤', style: TextStyle(fontSize: 12)),
              )
                  : null,
            )
                : const SizedBox(width: 36),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  // Enhancement: tap error bubble to retry
                  onTap: message.status == MessageStatus.error ? onRetry : null,
                  child: Opacity(
                    opacity:
                    message.status == MessageStatus.pending ? 0.6 : 1.0,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.72,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isMe
                            ? const LinearGradient(
                          colors: [
                            Color(0xFFFF4D6D),
                            Color(0xFF6C63FF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                            : null,
                        color: isMe ? null : Colors.white,
                        // Red tint for error state
                        border: message.status == MessageStatus.error
                            ? Border.all(
                          color: Colors.redAccent.withOpacity(0.6),
                          width: 1.5,
                        )
                            : null,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(
                              isMe || !isLastInGroup ? 18 : 4),
                          bottomRight: Radius.circular(
                              !isMe || !isLastInGroup ? 18 : 4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: isMe
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ),
                ),
                if (isLastInGroup)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(),
                          // Enhancement: "Tap to retry" hint on error
                          if (message.status == MessageStatus.error) ...[
                            const SizedBox(width: 4),
                            Text(
                              'Tap to retry',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.redAccent.shade100,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sent:
        return Icon(
          message.isRead
              ? CupertinoIcons.checkmark_alt_circle_fill
              : CupertinoIcons.checkmark_alt,
          size: 12,
          color: message.isRead
              ? const Color(0xFF2EC4B6)
              : Colors.grey.shade400,
        );
      case MessageStatus.pending:
        return const Icon(CupertinoIcons.clock, size: 12, color: Colors.grey);
      case MessageStatus.error:
        return const Icon(
          CupertinoIcons.exclamationmark_circle_fill,
          size: 12,
          color: Colors.redAccent,
        );
    }
  }
}

// ─── Day Separator ────────────────────────────────────────────────────────────

class _DaySeparator extends StatelessWidget {
  final DateTime date;
  const _DaySeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade200, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _dayLabel(date),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade200, height: 1)),
        ],
      ),
    );
  }
}