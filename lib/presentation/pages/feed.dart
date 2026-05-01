import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dating_app/core/features/feed/post_card.dart';
import 'package:dating_app/core/utils/date_utils.dart';
import 'package:dating_app/core/utils/feed_skeleton.dart';
import 'package:dating_app/core/utils/offline_cache.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/core/widgets/bottom_sheet.dart';
import 'package:dating_app/data/models/post_model.dart';
import 'package:dating_app/domain/repositories/likes_repository.dart';
import 'package:dating_app/domain/repositories/posts_repository.dart';
import 'package:dating_app/presentation/bloc/comments/comments_bloc.dart';
import 'package:dating_app/presentation/bloc/comments/commenst_event.dart';
import 'package:dating_app/presentation/bloc/likes/likes_bloc.dart';
import 'package:dating_app/presentation/bloc/posts/posts_bloc.dart';
import 'package:dating_app/presentation/bloc/posts/posts_event.dart';
import 'package:dating_app/presentation/bloc/posts/posts_state.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart';
import 'package:dating_app/presentation/pages/create_post.dart';
import 'package:dating_app/presentation/pages/my_post_page.dart';
import 'package:dating_app/presentation/pages/other_user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Filter bar data ──────────────────────────────────────────────────────────

const _filters = [
  {'type': null, 'emoji': '✨', 'label': 'All'},
  {'type': 'crush', 'emoji': '💘', 'label': 'Crush'},
  {'type': 'confession', 'emoji': '🤫', 'label': 'Confession'},
  {'type': 'spotted', 'emoji': '📡', 'label': 'Spotted'},
];

// ─── Feed Screen ──────────────────────────────────────────────────────────────

class FeedScreen extends StatefulWidget {
  final String currentUserId;
  const FeedScreen({super.key, required this.currentUserId});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  String? _activeFilter;
  final _scrollCtrl = ScrollController();
  bool _isFabVisible = true;
  bool _isOffline = false;
  StreamSubscription? _connectivitySub;

  @override
  void initState() {
    super.initState();
    
    _scrollCtrl.addListener(_scrollListener);

    // Initial check
    Connectivity().checkConnectivity().then((results) {
      if (mounted) {
        setState(() => _isOffline = results.first == ConnectivityResult.none);
      }
    });
    
    // Connectivity listener for real-time resync
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.first == ConnectivityResult.none;
      if (mounted) {
        // If we were offline and now online, refresh the feed
        if (_isOffline && !offline) {
          _fetchPosts(context, isInitial: true);
        }
        setState(() => _isOffline = offline);
      }
    });

    Future.microtask(() {
      if (mounted) {
        context.read<CommentsBloc>().add(LoadComments(widget.currentUserId));
        _fetchPosts(context);
      }
    });
  }

  void _scrollListener() {
    if (!mounted) return;
    
    // FAB visibility logic
    if (_scrollCtrl.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isFabVisible) setState(() => _isFabVisible = false);
    } else if (_scrollCtrl.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isFabVisible) setState(() => _isFabVisible = true);
    }
    
    // Pagination trigger (only if online)
    if (!_isOffline && _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent * 0.9) {
      _fetchPosts(context, isInitial: false);
    }
  }

  void _fetchPosts(BuildContext context, {bool isInitial = true}) {
    if (!mounted) return;
    final userState = context.read<UserBloc>().state;
    if (userState is UserLoaded) {
      context.read<PostBloc>().add(
        LoadPosts(
          university: userState.user.university, 
          isInitial: isInitial
        ),
      );
    }
  }

  void _setFilter(String? type) {
    HapticFeedback.selectionClick();
    setState(() => _activeFilter = type);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_scrollListener);
    _scrollCtrl.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return BlocProvider(
      create: (context) => PostBloc(context.read<PostRepository>()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F4F8),
            body: Column(
              children: [
                if (_isOffline) _buildOfflineBanner(),
                Expanded(
                  child: BlocListener<UserBloc, UserState>(
                    listener: (context, state) {
                      if (state is UserLoaded) _fetchPosts(context);
                    },
                    child: NestedScrollView(
                      controller: _scrollCtrl,
                      headerSliverBuilder: (_, __) => [_buildAppBar()],
                      body: Column(
                        children: [
                          _buildFilterBar(),
                          Expanded(
                            child: BlocBuilder<PostBloc, PostState>(
                              builder: (context, state) {
                                // Loading/Error handling with Cache Fallback
                                if (state is LoadingPosts || state is PostError) {
                                  if (_isOffline || state is PostError) {
                                    final cached = OfflineCache.getCachedPosts();
                                    if (cached.isNotEmpty) {
                                      return _buildPostList(cached, true);
                                    }
                                  }
                                  return const FeedSkeleton();
                                }

                                if (state is PostsLoaded) {
                                  final posts = _activeFilter == null
                                      ? state.post
                                      : state.post.where((p) => p.postType == _activeFilter).toList();
                                  
                                  if (posts.isEmpty && _isOffline) {
                                    final cached = OfflineCache.getCachedPosts();
                                    if (cached.isNotEmpty) return _buildPostList(cached, true);
                                    return const Center(child: Text("No cached posts available."));
                                  }

                                  return _buildPostList(posts, state.hasReachedMax);
                                }
                                return const FeedSkeleton();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: _isOffline ? null : _buildAnimatedFAB(context),
          );
        }
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade800,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Text(
        'Offline Mode — viewing cached feed',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPostList(List<PostModel> posts, bool hasReachedMax) {
    if (posts.isEmpty) return _buildEmpty();
    
    return RefreshIndicator(
      onRefresh: () async {
        if (!_isOffline) _fetchPosts(context);
      },
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.widthPercent(4),
          SizeConfig.heightPercent(1),
          SizeConfig.widthPercent(4),
          SizeConfig.heightPercent(12),
        ),
        itemCount: hasReachedMax || _isOffline ? posts.length : posts.length + 1,
        itemBuilder: (context, i) {
          if (i >= posts.length) {
            return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
          }
          final post = posts[i];
          return BlocProvider(
            key: ValueKey(post.id),
            create: (_) => LikesBloc(context.read<LikesRepository>()),
            child: PostCard(
              post: post,
              currentUserId: widget.currentUserId,
              isOffline: _isOffline,
              onComment: () => showCommentsSheet(context: context, postId: post.id, commentCount: post.commentCount),
              onAuthorTap: (uid) => Navigator.push(context, MaterialPageRoute(builder: (_) => OtherUserProfilePage(userId: uid))),
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      floating: true,
      snap: true,
      title: Text(
        'Campus Feed', 
        style: TextStyle(
          fontSize: SizeConfig.widthPercent(5), 
          fontWeight: FontWeight.w800, 
          color: const Color(0xFF1A1A2E)
        )
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPostsPage())),
          icon: const Icon(Icons.history_rounded, color: Color(0xFF1A1A2E)),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(SizeConfig.widthPercent(4), 0, SizeConfig.widthPercent(4), SizeConfig.heightPercent(1.5)),
      child: Row(
        children: _filters.map((f) {
          final type = f['type'] as String?;
          final isActive = _activeFilter == type;
          final color = type != null ? type.accentColor : const Color(0xFF6C63FF);
          
          return Expanded(
            child: GestureDetector(
              onTap: () => _setFilter(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: SizeConfig.widthPercent(1.5)),
                padding: EdgeInsets.symmetric(vertical: SizeConfig.heightPercent(1)),
                decoration: BoxDecoration(
                  color: isActive ? color : const Color(0xFFF4F4F8), 
                  borderRadius: BorderRadius.circular(SizeConfig.widthPercent(3))
                ),
                child: Column(
                  children: [
                    Text(f['emoji'] as String, style: TextStyle(fontSize: SizeConfig.widthPercent(4))),
                    Text(
                      f['label'] as String, 
                      style: TextStyle(
                        fontSize: SizeConfig.widthPercent(2.5), 
                        fontWeight: FontWeight.w700, 
                        color: isActive ? Colors.white : const Color(0xFF8E8E9A)
                      )
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_activeFilter?.emoji ?? '✨', style: TextStyle(fontSize: SizeConfig.widthPercent(12))),
          const SizedBox(height: 16),
          Text(
            'No ${_activeFilter?.label ?? ''} posts yet', 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFAB(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isFabVisible ? 1 : 0,
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider.value(value: context.read<PostBloc>(), child: const CreatePostScreen()))),
          child: Container(
            height: SizeConfig.heightPercent(7),
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.widthPercent(6)),
            decoration: BoxDecoration(
              color: Colors.black, 
              borderRadius: BorderRadius.circular(SizeConfig.heightPercent(3.5)), 
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))]
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  'New Post', 
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: SizeConfig.widthPercent(3.8)
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
