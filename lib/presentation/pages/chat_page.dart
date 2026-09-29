import 'package:dating_app/domain/entities/conversation_entity.dart';
import 'package:dating_app/domain/entities/message_entity.dart';
import 'package:dating_app/domain/repositories/chat_repository.dart';
import 'package:dating_app/presentation/bloc/chat/chat_bloc.dart';
import 'package:dating_app/presentation/bloc/chat/chat_event.dart';
import 'package:dating_app/presentation/bloc/chat/chat_state.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_event.dart';
import 'package:dating_app/presentation/pages/other_user_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/chat_bubble.dart';




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
      child: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatLoaded) {
            // Notify ConversationsBloc to clear unread count for this chat locally
            context.read<ConversationsBloc>().add(
              MarkConversationAsRead(
                conversationId: widget.conversation.id,
                currentUserId: widget.currentUserId,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),

        body: Column(
            children: [
              _buildAppBar(otherUserId),
              Expanded(child: _buildMessageList()),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }


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
          Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F6FA),
              shape: BoxShape.circle,
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(
                CupertinoIcons.chevron_left,
                color: Color(0xFF1A1A2E),
                size: 22,
              ),
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
                        color: const Color(0xFFFF4D6D).withValues(alpha: 0.1),
                        image: conv.otherUserImageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(conv.otherUserImageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        border: Border.all(
                          color: const Color(0xFFFF4D6D).withValues(alpha: 0.2),
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

  //------------------------------------------------------------ Message List

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

            if (isFirst || !isSameDay(msg.createdAt, prevMsg!.createdAt)) {
              items.add(msg.createdAt); // day separator
            }
            items.add(msg);
          }

          return ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              if (item is DateTime) return DaySeparator(date: item);
              final msg = item as MessageEntity;
              final isMe = msg.senderId == widget.currentUserId;

              final nextItem = i + 1 < items.length ? items[i + 1] : null;
              final isLastInGroup =
                  nextItem == null ||
                  nextItem is DateTime ||
                  (nextItem is MessageEntity &&
                      nextItem.senderId != msg.senderId);

              return MessageBubble(
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


