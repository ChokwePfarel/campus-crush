import 'package:dating_app/core/utils/burg_icon.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_state.dart';

import 'package:dating_app/presentation/pages/direct_posts.dart';
import 'package:dating_app/presentation/pages/discover_page.dart';
import 'package:dating_app/presentation/pages/feed.dart';
import 'package:dating_app/presentation/pages/inbox_page.dart';
import 'package:dating_app/presentation/pages/radar_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  // Track scroll direction
  double _lastScrollOffset = 0;
  final double _scrollThreshold = 10; // Minimum scroll distance to trigger hide/show

  void _handleScroll(double offset) {
    if (_selectedIndex == 0 || _selectedIndex == 1 || _selectedIndex == 3) {
      final delta = offset - _lastScrollOffset;

      // Scrolling up (negative delta) - hide bar
      // Scrolling down (positive delta) - show bar
      if (delta > _scrollThreshold && _isBottomBarVisible) {
        // Scrolling down - hide
        setState(() {
          _isBottomBarVisible = false;
        });
      } else if (delta < -_scrollThreshold && !_isBottomBarVisible) {
        // Scrolling up - show
        setState(() {
          _isBottomBarVisible = true;
        });
      }

      _lastScrollOffset = offset;
    }
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    final String currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';

    _pages = [
      DiscoverPage(onScrollDirectionChanged: _handleScroll),
      FeedScreen(currentUserId: currentUserId),
      const RadarPage(),
      DirectPostsPage(recipientId: currentUserId),
      InboxPage(currentUserId: currentUserId),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Reset scroll tracking when switching tabs
      _lastScrollOffset = 0;
      // Ensure bar is visible when switching tabs
      _isBottomBarVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    // Don't hide bar on Radar page (index 2)
    final bool isRadarPage = _selectedIndex == 2;

    // Also keep bar always visible on Chats page (index 4)
    final bool keepVisible = isRadarPage || _selectedIndex == 4;

    // Effective visibility
    final bool showBar = !keepVisible && _isBottomBarVisible;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double barHeight = showBar ? 50 + bottomPadding : 0;

    return Scaffold(
      backgroundColor: isRadarPage
          ? Colors.black
          : CupertinoColors.systemBackground,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: showBar
          ? Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: CupertinoTabBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            activeColor: Colors.purple,
            inactiveColor: CupertinoColors.systemGrey,
            backgroundColor: isRadarPage
                ? Colors.black
                : CupertinoColors.systemBackground,
            border: const Border(
              top: BorderSide(color: Color(0xFFE8E8F0), width: 0.5),
            ),
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  activeIcon: Icon(Icons.people),
                  label: 'Discover'
              ),
              const BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.chat_bubble_2),
                  activeIcon: Icon(CupertinoIcons.chat_bubble_2_fill),
                  label: 'Feed'
              ),
              const BottomNavigationBarItem(
                  icon: Icon(LucideIcons.radio),
                  activeIcon: Icon(LucideIcons.radio),
                  label: 'Radar'
              ),
              const BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.suit_heart),
                  activeIcon: Icon(CupertinoIcons.heart_fill),
                  label: 'For You'
              ),
              BottomNavigationBarItem(
                label: 'Chats',
                icon: BlocBuilder<ConversationsBloc, ConversationsState>(
                  builder: (context, state) {
                    final unread = state is ConversationsLoaded
                        ? state.unreadCount
                        : 0;

                    return BadgeIcon(
                      icon: CupertinoIcons.chat_bubble,
                      activeIcon: CupertinoIcons.chat_bubble_fill,
                      isActive: _selectedIndex == 4,
                      badgeCount: unread,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      )
          : null, // Return null to hide the bottom bar completely
    );
  }
}