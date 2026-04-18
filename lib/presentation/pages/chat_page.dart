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

  /// Called when tapping the other user's name/avatar → navigate to their profile

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
          // Back button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(
              CupertinoIcons.chevron_left,
              color: Color(0xFF1A1A2E),
              size: 22,
            ),
          ),

          // Avatar + name (tappable → profile)
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
        final isSending = state is ChatLoaded && state.isSending;

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

                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: _inputCtrl.text.trim().isNotEmpty
                        ? const LinearGradient(
                            colors: [Color(0xFFFF4D6D), Color(0xFF6C63FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: _inputCtrl.text.trim().isEmpty
                        ? const Color(0xFFE8E8F0)
                        : null,
                    shape: BoxShape.circle,
                    boxShadow: _inputCtrl.text.trim().isNotEmpty
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF4D6D).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _inputCtrl.text.trim().isNotEmpty && !isSending
                        ? () => _sendMessage(context)
                        : null,
                    child: isSending
                        ? const CupertinoActivityIndicator(
                            color: Colors.white,
                            radius: 9,
                          )
                        : Icon(
                            CupertinoIcons.arrow_up,
                            size: 20,
                            color: _inputCtrl.text.trim().isNotEmpty
                                ? Colors.white
                                : const Color(0xFFB0B0C0),
                          ),
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

class _MessageBubble extends StatefulWidget {
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
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  late final _scale = Tween<double>(
    begin: 0.85,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  late final _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: widget.isLastInGroup ? 12 : 3,
            top: 0,
          ),
          child: Row(
            mainAxisAlignment: widget.isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe) ...[
                widget.isLastInGroup
                    ? Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF4D6D).withOpacity(0.1),
                          image: widget.otherUserImageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(widget.otherUserImageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.otherUserImageUrl.isEmpty
                            ? const Center(
                                child: Text(
                                  '👤',
                                  style: TextStyle(fontSize: 12),
                                ),
                              )
                            : null,
                      )
                    : const SizedBox(width: 36),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: widget.isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.72,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: widget.isMe
                            ? const LinearGradient(
                                colors: [Color(0xFFFF4D6D), Color(0xFF6C63FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: widget.isMe ? null : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(
                            widget.isMe || !widget.isLastInGroup ? 18 : 4,
                          ),
                          bottomRight: Radius.circular(
                            !widget.isMe || !widget.isLastInGroup ? 18 : 4,
                          ),
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
                        widget.message.text,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: widget.isMe
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    if (widget.isLastInGroup)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(widget.message.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            if (widget.isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                widget.message.isRead
                                    ? CupertinoIcons.checkmark_alt_circle_fill
                                    : CupertinoIcons.checkmark_alt,
                                size: 12,
                                color: widget.message.isRead
                                    ? const Color(0xFF2EC4B6)
                                    : Colors.grey.shade400,
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.isMe) const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
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
