import 'package:dating_app/core/utils/notification_badge.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/presentation/bloc/notification/notificationBloc.dart';
import 'package:dating_app/presentation/bloc/notification/notification_state.dart';
import 'package:dating_app/presentation/bloc/notification/notification_event.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_state.dart';

import 'package:dating_app/presentation/pages/direct_posts.dart';
import 'package:dating_app/presentation/pages/discover_page.dart';
import 'package:dating_app/presentation/pages/feed.dart';
import 'package:dating_app/presentation/pages/inbox_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstaStyleNav extends StatefulWidget {
  const InstaStyleNav({super.key});

  @override
  _InstaStyleNavState createState() => _InstaStyleNavState();
}

class _InstaStyleNavState extends State<InstaStyleNav> {
  int _selectedIndex = 0;
  bool _isBottomBarVisible = true;

  double _accumulatedDelta = 0;
  final double _scrollThreshold = 40;

  void _handleScrollDelta(double delta) {
    if (_selectedIndex == 0 || _selectedIndex == 1 || _selectedIndex == 3) {
      if (delta > 0 && _accumulatedDelta < 0) _accumulatedDelta = 0;
      if (delta < 0 && _accumulatedDelta > 0) _accumulatedDelta = 0;

      _accumulatedDelta += delta;

      if (_accumulatedDelta > _scrollThreshold && _isBottomBarVisible) {
        setState(() {
          _isBottomBarVisible = false;
        });
        _accumulatedDelta = 0;
      } else if (_accumulatedDelta < -_scrollThreshold && !_isBottomBarVisible) {
        setState(() {
          _isBottomBarVisible = true;
        });
        _accumulatedDelta = 0;
      }
    }
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    final String currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';

    _pages = [
      DiscoverPage(currentUserId: currentUserId),
      FeedScreen(currentUserId: currentUserId),

      DirectPostsPage(recipientId: currentUserId),
      InboxPage(currentUserId: currentUserId),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _accumulatedDelta = 0;
      _isBottomBarVisible = true;
    });

    // Clear notifications when entering the "For You" tab (which contains the notification bell)
    if (index == 2) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        context.read<NotificationBloc>().add(MarkNotificationsRead(user.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    //final bool isRadarPage = _selectedIndex == 2;
    /*final bool keepVisible = isRadarPage || _selectedIndex == 4;
    final bool showBar = keepVisible || _isBottomBarVisible;
*/
    return Scaffold(
        extendBody: true,
        backgroundColor: CupertinoColors.systemBackground,
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification &&
                notification.metrics.axis == Axis.vertical) {
              _handleScrollDelta(notification.scrollDelta ?? 0);
            }
            return false;
          },
          child: IndexedStack(index: _selectedIndex, children: _pages),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 10),
            child: Container(
              height: 52, // Slimmer height for "needed space only"
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: CupertinoTabBar(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  activeColor: Colors.purple,
                  inactiveColor: CupertinoColors.systemGrey,
                  backgroundColor: CupertinoColors.systemBackground,
                  border: null, // Remove the extra top border/margin line
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.people, size: 28),
                      activeIcon: Icon(Icons.people, size: 28),
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.chat_bubble_2, size: 28),
                      activeIcon: Icon(CupertinoIcons.chat_bubble_2_fill, size: 28),
                    ),
                    BottomNavigationBarItem(
                      icon: BlocBuilder<NotificationBloc, NotificationState>(
                        builder: (context, state) => NotificationIcon(
                          icon: CupertinoIcons.suit_heart,
                          showDot: state.showRedDot,
                        ),
                      ),
                      activeIcon: BlocBuilder<NotificationBloc, NotificationState>(
                        builder: (context, state) => NotificationIcon(
                          icon: CupertinoIcons.heart_fill,
                          showDot: state.showRedDot,
                        ),
                      ),
                    ),
                    BottomNavigationBarItem(
                      icon: BlocBuilder<ConversationsBloc, ConversationsState>(
                        builder: (context, state) {
                          final unread = state is ConversationsLoaded
                              ? state.unreadCount
                              : 0;

                          return BadgeIcon(
                            icon: CupertinoIcons.chat_bubble,
                            activeIcon: CupertinoIcons.chat_bubble_fill,
                            isActive: _selectedIndex == 3, // Fixed index check
                            badgeCount: unread,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),)
        );
  }
}
