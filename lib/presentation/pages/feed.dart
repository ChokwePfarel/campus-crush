import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dating_app/core/features/feed/post_card.dart';
import 'package:dating_app/core/utils/date_utils.dart';
import 'package:dating_app/core/utils/feed_skeleton.dart';
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
import 'package:dating_app/presentation/bloc/user/user_event.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart';
import 'package:dating_app/presentation/pages/create_post.dart';
import 'package:dating_app/presentation/pages/my_post_page.dart';
import 'package:dating_app/presentation/pages/other_user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dating_app/core/utils/comment_skeleton.dart';

// ─── Filter bar data ──────────────────────────────────────────────────────────

const _filters = [
  {'type': null, 'label': 'All'},
  {'type': 'crush', 'label': 'Crush'},
  {'type': 'confession', 'label': 'Confession'},
];

// ─── Feed Screen ──────────────────────────────────────────────────────────────

class FeedScreen extends StatefulWidget {
  final String currentUserId;
  final Function(double)? onScroll;

  const FeedScreen({super.key, required this.currentUserId, this.onScroll});

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

    context.read<UserBloc>().add(LoadUserSubscription());

    _scrollCtrl.addListener(_scrollListener);

    Connectivity().checkConnectivity().then((results) {
      if (mounted)
        setState(() => _isOffline = results.first == ConnectivityResult.none);
    });

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

    if (_scrollCtrl.hasClients) {
      widget.onScroll?.call(_scrollCtrl.offset);
    }

    if (_scrollCtrl.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isFabVisible) setState(() => _isFabVisible = false);
    } else if (_scrollCtrl.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabVisible) setState(() => _isFabVisible = true);
    }

    if (!_isOffline &&
        _scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent * 0.9) {
      _fetchPosts(context, isInitial: false);
    }
  }

  void _fetchPosts(BuildContext context, {bool isInitial = true}) {
    if (!mounted) return;
    final userState = context.read<UserBloc>().state;

    if (userState is UserLoaded) {
      context.read<PostBloc>().add(
        LoadPosts(university: userState.user.university, isInitial: isInitial),
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
            backgroundColor: Colors.black,
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
                                // The bloc handles cache-first loading and
                                // offline fallback internally — the UI just
                                // renders whatever state it receives.
                                if (state is LoadingPosts) {
                                  return const FeedSkeleton();
                                }

                                if (state is PostError) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text('Could not load posts'),
                                        const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: () => _fetchPosts(
                                            context,
                                            isInitial: true,
                                          ),
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                if (state is PostsLoaded) {
                                  final posts = _activeFilter == null
                                      ? state.post
                                      : state.post
                                            .where(
                                              (p) =>
                                                  p.postType == _activeFilter,
                                            )
                                            .toList();

                                  return _buildPostList(
                                    posts,
                                    state.hasReachedMax,
                                  );
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
          );
        },
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Text(
        'Connection lost',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
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
        itemCount: hasReachedMax || _isOffline
            ? posts.length
            : posts.length + 1,
        itemBuilder: (context, i) {

          if (i >= posts.length) {
            return Center(
              child: const CircularProgressIndicator.adaptive(),
            );

          }
          final post = posts[i];
          return BlocProvider(
            key: ValueKey(post.id),
            create: (_) => LikesBloc(context.read<LikesRepository>()),
            child: PostCard(
              post: post,
              currentUserId: widget.currentUserId,
              isOffline: _isOffline,
              onComment: () => showCommentsSheet(
                context: context,
                postId: post.id,
                commentCount: post.commentCount,
              ),
              onAuthorTap: (uid) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtherUserProfilePage(userId: uid),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      pinned: true,
      floating: true,
      snap: true,
      title: Text(
        'CampusFeed',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        _isOffline
            ? const SizedBox.shrink()
            : IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyPostsPage()),
                ),
                icon: Icon(Icons.history,
                color: Colors.white,),
              ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.black,
      child: Row(
        children: [
          ..._filters.map((f) {
            final type = f['type'];
            final isActive = _activeFilter == type;
            final color = type != null
                ? type.accentColor
                : const Color(0xFF6C63FF);

            return Expanded(
              child: GestureDetector(
                onTap: () => _setFilter(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: isActive
                        ? const Border(
                            bottom: BorderSide(color: Colors.white, width: 2.0),
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        // Add space below text
                        child: Text(
                          f['label'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF8E8E9A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

          // Add icon button at the end of the row
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<PostBloc>(),
                  child: const CreatePostScreen(),
                ),
              ),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.widthPercent(3),
                vertical: SizeConfig.heightPercent(1),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle, // This makes it a perfect circle
              ),

              child: const Icon(Icons.add, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _activeFilter?.emoji ?? '✨',
            style: TextStyle(fontSize: SizeConfig.widthPercent(12)),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_activeFilter?.label ?? ''} posts yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSkeleton() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => const CommentSkeletonItem(),
    );
  }
}
