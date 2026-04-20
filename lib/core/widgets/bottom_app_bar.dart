import 'package:dating_app/core/utils/burg_icon.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_state.dart';

import 'package:dating_app/presentation/pages/direct_posts.dart';
import 'package:dating_app/presentation/pages/discover_page.dart';
import 'package:dating_app/presentation/pages/feed.dart';
import 'package:dating_app/presentation/pages/inbox_page.dart';
import 'package:dating_app/presentation/pages/profile_page.dart';
import 'package:dating_app/presentation/pages/radar_page.dart';
import 'package:dating_app/presentation/pages/spotted_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstaStyleNav extends StatefulWidget {
  const InstaStyleNav({super.key});

  @override
  _InstaStyleNavState createState() => _InstaStyleNavState();
}

class _InstaStyleNavState extends State<InstaStyleNav> {
  int _selectedIndex = 0;
  bool _isBottomBarVisible = true;

  void _handleScroll(bool isVisible) {
    // Only allow scroll-based hiding on the Discover (0) and Feed (3) pages
    if (_selectedIndex == 0 || _selectedIndex == 3) {
      if (_isBottomBarVisible != isVisible) {
        setState(() {
          _isBottomBarVisible = isVisible;
        });
      }
    }
  }

  late final List<Widget> _pages;


  @override
  void initState() {
    super.initState();

    final String currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    _pages = [
      DiscoverPage(onScrollDirectionChanged: _handleScroll),
      FeedScreen(currentUserId: currentUserId),
      const RadarPage(),
      /*SpottedPage(
        location: 'The Barn',
        university: 'University of the Western Cape (UWC)',
      ),*/
      DirectPostsPage(recipientId: currentUserId,),
      InboxPage(currentUserId: currentUserId),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);


    final String? currentUserId =
        Supabase.instance.client.auth.currentUser?.id;

    // Completely hide if Radar Page (index 2) is active
    final bool isRadarPage = _selectedIndex == 2;

    // Effective visibility
    final bool showBar = !isRadarPage && _isBottomBarVisible;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double barHeight = 50 + bottomPadding;
    //final double barHeight = showBar ? 55 + bottomPadding : 0;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: barHeight,
        child: Wrap(
          children: [
            CupertinoTabBar(
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
                ),

                const BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.news),
                  activeIcon: Icon(CupertinoIcons.news_solid),
                ),

                const BottomNavigationBarItem(
                  icon: Icon(LucideIcons.radio),
                  activeIcon: Icon(LucideIcons.radio),
                ),

                const BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.suit_heart),
                  activeIcon: Icon(CupertinoIcons.heart_fill),
                ),

                BottomNavigationBarItem(
                  icon: BlocBuilder<ConversationsBloc, ConversationsState>(
                    builder: (context, state) {
                      final unread = state is ConversationsLoaded
                          ? state.unreadCount
                          : 0;

                      return BadgeIcon(
                        icon: CupertinoIcons.chat_bubble_2,
                        activeIcon: CupertinoIcons.chat_bubble_2_fill,
                        isActive: _selectedIndex == 4,
                        badgeCount: unread,
                      );
                    },
                  ),

                ),

                /* BottomNavigationBarItem(
                  icon: Icon(LucideIcons.user),
                  activeIcon: Icon(LucideIcons.user),
                ),*/
              ],
            ),
          ],
        ),
      ),
    );
  }
}
