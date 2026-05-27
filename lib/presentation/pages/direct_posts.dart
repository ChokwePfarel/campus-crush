import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dating_app/core/utils/date_utils.dart';
import 'package:dating_app/core/utils/feed_skeleton.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/core/utils/snackbar.dart';
import 'package:dating_app/core/utils/theme.dart';
import 'package:dating_app/core/widgets/bottom_sheet.dart';
import 'package:dating_app/data/models/post_model.dart';
import 'package:dating_app/data/models/user_model.dart';
import 'package:dating_app/domain/entities/coins_entity.dart';
import 'package:dating_app/presentation/bloc/coins/coins_bloc.dart';
import 'package:dating_app/presentation/bloc/coins/coins_event.dart';
import 'package:dating_app/presentation/bloc/coins/coins_state.dart';
import 'package:dating_app/presentation/bloc/direct_posts/direct_posts_bloc.dart';
import 'package:dating_app/presentation/bloc/direct_posts/direct_posts_event.dart';
import 'package:dating_app/presentation/bloc/direct_posts/direct_posts_state.dart';
import 'package:dating_app/presentation/pages/Notification_Page.dart';
import 'package:dating_app/presentation/pages/other_user_profile.dart';
import 'package:dating_app/presentation/pages/send_post_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DirectPostsPage extends StatefulWidget {
  final String recipientId;
  final Function(double)? onScroll;

  const DirectPostsPage({super.key, required this.recipientId, this.onScroll});

  @override
  State<DirectPostsPage> createState() => _DirectPostsPageState();
}

class _DirectPostsPageState extends State<DirectPostsPage>
    with SingleTickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  String? _pendingProfileUserId;
  String? _pendingPostId;
  bool _isCheckingReveal = false;

  bool _isOffline = false;
  StreamSubscription? _connectivitySub;

  late final _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();

  @override
  void initState() {
    super.initState();

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isOffline = results.first == ConnectivityResult.none;
        });
      }
    });

    _scrollCtrl.addListener(_onScroll);

    // Initial load after mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
    });
  }

  void _loadData() {
    context.read<DirectPostsBloc>().add(LoadDirectPosts(widget.recipientId));
    context.read<CoinsBloc>().add(LoadCoins(widget.recipientId));
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients || !mounted) return;

    widget.onScroll?.call(_scrollCtrl.offset);

    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent * 0.9) {
      context.read<DirectPostsBloc>().add(
        LoadMoreDirectPosts(widget.recipientId),
      );
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    context.read<DirectPostsBloc>().add(RefreshDirectPosts(widget.recipientId));
  }

  void _handlePostTap(PostModel post, String currentUserId) {
    if (!mounted) return;

    if (_isOffline) {
      AppSnackBar.show(
        context,
        'No internet connection',
        type: SnackBarType.warning,
      );
      return; // stops here
    }

    if (!post.isAnonymous) {
      _navigateToProfile(post.userId);
      return;
    }

    // It's anonymous. First check if we've already revealed it.
    _pendingPostId = post.id;
    _pendingProfileUserId = post.userId;
    _isCheckingReveal = true;

    HapticFeedback.selectionClick();
    context.read<CoinsBloc>().add(
      CheckHasRevealed(userId: currentUserId, postId: post.id),
    );
  }

  void _showRevealDialog(
    BuildContext context,
    PostModel post,
    String currentUserId,
  ) {
    if (!mounted) return;

    if (_isOffline) {
      AppSnackBar.show(
        context,
        'No internet connection',
        type: SnackBarType.warning,
      );

      return; // stops here
    }

    final coinsState = context.read<CoinsBloc>().state;
    final coins = coinsState is CoinsLoaded ? coinsState.coins : null;
    final hasEnough = (coins?.balance ?? 0) >= CoinsEntity.anonymousRevealCost;

    showCupertinoDialog(
      context: context,
      builder: (_) => _RevealDialog(
        post: post,
        hasEnoughCoins: hasEnough,
        coinBalance: coins?.balance ?? 0,
        onReveal: () {
          Navigator.pop(context);
          if (post.isAnonymous) {
            _pendingProfileUserId = post.userId;
            _pendingPostId = post.id;
            context.read<CoinsBloc>().add(
              SpendCoinsOnReveal(userId: currentUserId, postId: post.id),
            );
          } else {
            _navigateToProfile(post.userId);
          }
        },
        onWatchAd: () {
          Navigator.pop(context);
          _pendingProfileUserId = post.userId;
          _pendingPostId = post.id;
          context.read<CoinsBloc>().add(WatchAdRequested(currentUserId));
        },
      ),
    );
  }

  void _navigateToProfile(String userId) {
    if (!mounted) return;
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => OtherUserProfilePage(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return BlocListener<CoinsBloc, CoinsState>(
      listener: (context, state) {
        if (!mounted) return;

        if (state is CoinsLoaded && _isCheckingReveal) {
          _isCheckingReveal = false;

          if (state.hasRevealed == true) {
            // Already revealed! Navigate directly.
            _navigateToProfile(_pendingProfileUserId!);
            _pendingProfileUserId = null;
            _pendingPostId = null;
          } else {
            // Not revealed yet. Show dialog.
            final directPostsState = context.read<DirectPostsBloc>().state;
            if (directPostsState is DirectPostsLoaded) {
              final post = directPostsState.posts.firstWhere(
                (p) => p.id == _pendingPostId,
              );
              _showRevealDialog(context, post, currentUserId!);
            }
          }
        }

        if (state is CoinsEarned && _pendingPostId != null) {
          context.read<CoinsBloc>().add(
            SpendCoinsOnReveal(userId: currentUserId!, postId: _pendingPostId!),
          );
        }
        if (state is CoinsSpent && _pendingProfileUserId != null) {
          HapticFeedback.mediumImpact();
          _navigateToProfile(_pendingProfileUserId!);
          _pendingProfileUserId = null;
          _pendingPostId = null;
        }
        if (state is CoinsError) {
          _pendingProfileUserId = null;
          _pendingPostId = null;
          _isCheckingReveal = false;
          AppSnackBar.show(context, state.message, type: SnackBarType.warning);
          ;
        }
      },
      child: FadeTransition(
        opacity: _fadeCtrl,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            displacement: 100,
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(),
                _buildCoinsBar(),
                _buildBody(currentUserId ?? ''),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      title: const Text(
        'For You',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A2E),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: const Color(0xFFEEEEF4)),
      ),

      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationPage()),
            );
          },
          icon: Icon(Icons.notifications),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildCoinsBar() {
    return SliverToBoxAdapter(
      child: BlocBuilder<CoinsBloc, CoinsState>(
        builder: (context, state) {
          final balance = state is CoinsLoaded ? state.coins.balance : 0;

          return Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reveal identities for 20 coins',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('🪙'),
                      const SizedBox(width: 5),
                      Text(
                        '$balance',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverPadding _buildBody(String currentUserId) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      sliver: BlocBuilder<DirectPostsBloc, DirectPostsState>(
        builder: (context, state) {
          if (_isOffline && state is! DirectPostsLoaded) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: _buildOfflineState(),
            );
          }

          if (state is DirectPostsLoading) {
            return const SliverFillRemaining(child: FeedSkeleton());
          }
          if (state is DirectPostsError) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: _buildOfflineState(),
            );
          }
          if (state is DirectPostsLoaded) {
            if (state.posts.isEmpty) {
              return const SliverFillRemaining(child: _EmptyState());
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  if (i >= state.posts.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  }
                  final post = state.posts[i];
                  return _DirectPostCard(
                    post: post,
                    onTap: () => _handlePostTap(post, currentUserId),
                    onReplyTap: () => _isOffline
                        ? AppSnackBar.show(
                            context,
                            'No internet connection',
                            type: SnackBarType.warning,
                          )
                        : showCommentsSheet(
                            context: context,
                            postId: post.id,
                            commentCount: post.commentCount,
                          ),
                  );
                },
                childCount: state.hasMore
                    ? state.posts.length + 1
                    : state.posts.length,
              ),
            );
          }
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        },
      ),
    );
  }

  Widget _buildOfflineState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          "assets/offline.png",
          fit: BoxFit.contain,
          height: 300,
          width: double.infinity,
        ),
        const SizedBox(height: 24),
        const Text(
          'Something went wrong',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),

        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => _loadData(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStylee.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

class _DirectPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  final VoidCallback onReplyTap;

  const _DirectPostCard({
    required this.post,
    required this.onTap,
    required this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = post.postType.accentColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accent.withOpacity(0.1),
                  child: Text(post.isAnonymous ? '🎭' : '👤'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.isAnonymous ? 'Someone special' : post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Sent you a ${post.postType.label}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateUtilsHelper.timeAgo(post.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.content,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const Divider(height: 32),

            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.remove_red_eye_outlined,
                        size: 16,
                        color: accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Reveal Sender',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 20, color: Colors.grey[200]),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onReplyTap,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.reply_outlined,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealDialog extends StatelessWidget {
  final PostModel post;
  final bool hasEnoughCoins;
  final int coinBalance;
  final VoidCallback onReveal;
  final VoidCallback onWatchAd;

  const _RevealDialog({
    required this.post,
    required this.hasEnoughCoins,
    required this.coinBalance,
    required this.onReveal,
    required this.onWatchAd,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(post.isAnonymous ? 'Reveal Sender?' : 'View Profile?'),
      content: Text(
        post.isAnonymous
            ? 'Revealing costs ${CoinsEntity.anonymousRevealCost} coins. You have $coinBalance.'
            : 'View the profile of the person who sent this.',
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (post.isAnonymous && !hasEnoughCoins)
          CupertinoDialogAction(
            onPressed: onWatchAd,
            child: const Text('Watch Ad (+10 🪙)'),
          ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: (post.isAnonymous && !hasEnoughCoins) ? null : onReveal,
          child: Text(post.isAnonymous ? 'Reveal (20 🪙)' : 'View'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No messages yet 💌', style: TextStyle(color: Colors.grey)),
    );
  }
}
