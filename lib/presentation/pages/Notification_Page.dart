import 'package:dating_app/domain/entities/comment_entity.dart';
import 'package:dating_app/presentation/bloc/comments/comments_bloc.dart';
import 'package:dating_app/presentation/bloc/comments/comments_state.dart';
import 'package:dating_app/presentation/bloc/comments/commenst_event.dart';
import 'package:dating_app/presentation/pages/detailed_post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    // Mark all as read when user opens the page
    context.read<CommentsBloc>().add(MarkNotificationsAsRead());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<CommentsBloc, CommentsState>(
        builder: (context, state) {
          // ── Loading ──────────────────────────────────────────
          if (state is LoadingComments) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Get notifications from state ─────────────────────
          final notifications = state is CommentsLoaded
              ? state.notifications
              : <CommentEntity>[];

          // ── Empty ────────────────────────────────────────────
          if (notifications!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // ── List ─────────────────────────────────────────────
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications!.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationItem(
                notification: notification,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailedPost(
                      postId: notification.postId,
                      currentUserId: notification.userId,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final CommentEntity notification;
  final VoidCallback onTap;

  const _NotificationItem({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isReply = notification.parentCommentId != null;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Colors.purple[50],
        child: Text(notification.repliersName[0].toUpperCase()),
      ),
      title: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
              text: notification.repliersName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: isReply
                  ? ' replied to your comment'
                  : ' commented on your post',
            ),
          ],
        ),
      ),
      subtitle: Text(
        notification.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: Colors.grey,
      ),
    );
  }
}
