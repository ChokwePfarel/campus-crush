import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/message_entity.dart';
import '../../presentation/bloc/chat/chat_bloc.dart';
import '../../presentation/bloc/chat/chat_event.dart';


String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _dayLabel(DateTime dt) {
  final now = DateTime.now();
  if (isSameDay(dt, now)) return 'Today';
  if (isSameDay(dt, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  return '${dt.day}/${dt.month}/${dt.year}';
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;


class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final bool isLastInGroup;
  final String otherUserImageUrl;

  const MessageBubble({
    required this.message,
    required this.isMe,
    required this.isLastInGroup,
    required this.otherUserImageUrl,
  });

  void _showOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (actionContext) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              context.read<ChatBloc>().add(deleteMessage(messageId: message.id));
              Navigator.pop(actionContext);
              HapticFeedback.mediumImpact();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.delete, color: CupertinoColors.destructiveRed),
                SizedBox(width: 8),
                Text('Delete Message'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(actionContext),
        ),
      ),
    );
  }

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
            child: GestureDetector(
              onLongPress: isMe ? () => _showOptions(context) : null,
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

//---------------------------------------------------------------- Day Separator

class DaySeparator extends StatelessWidget {
  final DateTime date;
  const DaySeparator({required this.date});

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