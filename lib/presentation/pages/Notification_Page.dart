import 'package:dating_app/domain/entities/notification_entity.dart';
import 'package:dating_app/presentation/bloc/notification/notificationBloc.dart';
import 'package:dating_app/presentation/bloc/notification/notification_event.dart';
import 'package:dating_app/presentation/bloc/notification/notification_state.dart';

import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart' as user_st;
import 'package:dating_app/presentation/pages/detailed_post.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // NotificationPage initState — fetches persisted data
  // lib/presentation/pages/Notification_Page.dart

  @override
  void initState() {
    super.initState();
    final userState = context.read<UserBloc>().state;
    if (userState is user_st.UserLoaded) {
      final bloc = context.read<NotificationBloc>();
      bloc.add(LoadNotifications(userState.user.id));
      // Mark all as read when entering the page to clear the badge
      bloc.add(MarkNotificationsRead(userState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.read<UserBloc>().state;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.chevron_left,
            color: Color(0xFF1A1A2E),
          ),
        ),
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          // ── Loading ──────────────────────────────────────────
          if (state is NotificationLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }

          // ── Error ────────────────────────────────────────────
          if (state is NotificationError) {
            return Center(child: Text(state.message));
          }

          // ── Get notifications from state ─────────────────────
          final notifications = state is NotificationLoaded
              ? state.notifications
              : <NotificationEntity>[];

          // ── Empty ────────────────────────────────────────────
          if (notifications.isEmpty) {
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
            itemCount: notifications.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationItem(
                notification: notification,
                onTap: () {
                  if (userState is user_st.UserLoaded) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailedPost(
                          postId: notification.postId,
                          currentUserId: userState.user.id, //  logged in user
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;

  const _NotificationItem({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Colors.purple[50],
        child: Text(notification.triggeredByName[0].toUpperCase()),
      ),
      title: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
              text: notification.triggeredByName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: notification.isReply
                  ? ' replied to your comment'
                  : ' commented on your post',
            ),
          ],
        ),
      ),
      subtitle: Text(
        notification.commentText,
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
