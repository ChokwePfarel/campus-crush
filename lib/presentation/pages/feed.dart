import 'package:dating_app/core/utils/date_utils.dart';
import 'package:dating_app/core/utils/feed_skeleton.dart';
import 'package:dating_app/core/utils/posts_skeleton.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/core/widgets/bottom_sheet.dart';
import 'package:dating_app/data/models/post_model.dart';
import 'package:dating_app/domain/repositories/posts_repository.dart';
import 'package:dating_app/presentation/bloc/comments/commenst_event.dart';
import 'package:dating_app/presentation/bloc/comments/comments_bloc.dart';
import 'package:dating_app/presentation/bloc/likes/LikesEvent.dart';
import 'package:dating_app/presentation/bloc/likes/LikesState.dart';
import 'package:dating_app/presentation/bloc/likes/likes_bloc.dart';
import 'package:dating_app/presentation/bloc/posts/posts_bloc.dart';
import 'package:dating_app/presentation/bloc/posts/posts_event.dart';
import 'package:dating_app/presentation/bloc/posts/posts_state.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart' as user_st;
import 'package:dating_app/presentation/bloc/user/user_event.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart' as user_st;
import 'package:dating_app/presentation/pages/create_post.dart';
import 'package:dating_app/presentation/pages/my_post_page.dart';
import 'package:dating_app/presentation/pages/other_user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Filter bar data ──────────────────────────────────────────────────────────

const _filters = [
  {'type': null,         'emoji': '✨', 'label': 'All'},
  {'type': 'crush',      'emoji': '💘', 'label': 'Crush'},
  {'type': 'confession', 'emoji': '🤫', 'label': 'Confession'},
  {'type': 'spotted',    'emoji': '📡', 'label': 'Spotted'},
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

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<CommentsBloc>().add(LoadComments(widget.currentUserId));
      context.read<LikesBloc>().add(LoadLikes(widget.currentUserId));
    });

    _scrollCtrl.addListener(_onScroll);
  }

  void _fetchPosts(BuildContext context, {bool isInitial = true}) {


    final userState = context.read<UserBloc>().state;

    if (userState is user_st.UserLoaded) {
      context.read<PostBloc>().add(LoadPosts(
        university: userState.user.university,
        isInitial: isInitial,
      ));
    }
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent * 0.9) {
      _fetchPosts(context, isInitial: false);
    }
  }

  void _setFilter(String? type) {
    HapticFeedback.selectionClick();
    setState(() => _activeFilter = type);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return BlocProvider(
      create: (context) => PostBloc(context.read<PostRepository>()),
      child: Builder(
        builder: (context) {
          // Trigger initial fetch once Bloc is available in context
          _fetchPosts(context);

          return Scaffold(
            backgroundColor: const Color(0xFFF4F4F8),

            body: BlocListener<user_st.UserBloc, user_st.UserState>(
              listener: (context, state) {
                if (state is user_st.UserLoaded) {
                  _fetchPosts(context);
                }
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
                          if (state is LoadingPosts) {
                            return const PostListSkeleton();
                          }

                          if (state is PostError) {
                            return Center(child: Text('Error: ${state.message}'));
                          }

                          if (state is PostsLoaded) {
                            final posts = _activeFilter == null
                                ? state.post
                                : state.post.where((p) => p.postType == _activeFilter).toList();

                            if (posts.isEmpty) return _buildEmpty();

                            return RefreshIndicator(
                              onRefresh: () async => _fetchPosts(context),
                              child: ListView.builder(
                                padding: EdgeInsets.fromLTRB(
                                  SizeConfig.widthPercent(4),
                                  SizeConfig.heightPercent(1),
                                  SizeConfig.widthPercent(4),
                                  SizeConfig.heightPercent(12)
                                ),
                                itemCount: state.hasReachedMax ? posts.length : posts.length + 1,
                                itemBuilder: (_, i) {
                                  if (i >= posts.length) {
                                    return const Center(child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ));
                                  }
                                  final post = posts[i];
                                  return _PostCard(
                                    key: ValueKey(post.id),
                                    post: post,
                                    onComment: () => showCommentsSheet(context: context, postId: post.id, commentCount: post.commentCount),
                                    onAuthorTap: (uid) {},
                                  );
                                },
                              ),
                            );
                          }
                          return const PostListSkeleton();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: _buildFAB(context),
          );
        }
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      centerTitle: false,
      title: Text(
        'Campus Feed',
        style: TextStyle(
          fontSize: SizeConfig.widthPercent(5),
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1A1A2E),
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {

            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyPostsPage()));
          },
          icon: const Icon(Icons.history_rounded),
          color: const Color(0xFF1A1A2E),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        SizeConfig.widthPercent(4),
        0,
        SizeConfig.widthPercent(4),
        SizeConfig.heightPercent(1.5)
      ),
      child: Row(
        children: _filters.map((f) {
          final type = f['type'];
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
                  borderRadius: BorderRadius.circular(SizeConfig.widthPercent(3)),
                ),
                child: Column(
                  children: [
                    Text(
                      f['emoji'] as String,
                      style: TextStyle(fontSize: SizeConfig.widthPercent(4)),
                    ),
                    SizedBox(height: SizeConfig.heightPercent(0.3)),
                    Text(
                      f['label'] as String,
                      style: TextStyle(
                        fontSize: SizeConfig.widthPercent(2.5),
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : const Color(0xFF8E8E9A),
                      ),
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
          Text(
            _activeFilter?.emoji ?? '✨',
            style: TextStyle(fontSize: SizeConfig.widthPercent(12)),
          ),
          SizedBox(height: SizeConfig.heightPercent(2)),
          Text(
            'No ${_activeFilter?.label ?? ''} posts yet',
            style: TextStyle(
              fontSize: SizeConfig.widthPercent(4.5),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: SizeConfig.heightPercent(1)),
          const Text(
            'Be the first to post something',
            style: TextStyle(color: Color(0xFF8E8E9A)),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () {
        /*Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider.value(
          value: context.read<PostBloc>(),
          child: const CreatePostScreen(),
        )));*/
      },
      child: Container(
        height: SizeConfig.heightPercent(7),
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.widthPercent(6)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4D6D), Color(0xFF6C63FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(SizeConfig.heightPercent(3.5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4D6D).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: SizeConfig.widthPercent(5.5)),
            SizedBox(width: SizeConfig.widthPercent(2)),

            Text(
              'New Post',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: SizeConfig.widthPercent(3.8),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback onComment;
  final Function(String) onAuthorTap;

  const _PostCard({
    super.key,
    required this.post,
    required this.onComment,
    required this.onAuthorTap,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> with SingleTickerProviderStateMixin {
  late final _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final _slideAnim = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  late final _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

  // ── Local like state ───────────────────────────────────────────────────────
  late bool _hasLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _hasLiked = false;
    _likeCount = widget.post.likeCount;

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _animCtrl.forward();
    });

    // Check if the current user has already liked this post
    Future.microtask(() {
      if (!mounted) return;
      final userState = context.read<UserBloc>().state;
      if (userState is user_st.UserLoaded) {
        context.read<LikesBloc>().add(CheckHasLiked(
          postId: widget.post.id,
          userId: userState.user.id,
        ));
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onLikeTap(BuildContext context) {
    HapticFeedback.lightImpact();
    final userState = context.read<UserBloc>().state;
    if (userState is! user_st.UserLoaded) return;

    if (_hasLiked) {
      setState(() {
        _hasLiked = false;
        _likeCount = (_likeCount - 1).clamp(0, double.maxFinite.toInt());
      });
      context.read<LikesBloc>().add(UnlikePost(
        postId: widget.post.id,
        userId: userState.user.id,
      ));
    } else {
      setState(() {
        _hasLiked = true;
        _likeCount += 1;
      });
      context.read<LikesBloc>().add(LikePost(
        postId: widget.post.id,
        userId: userState.user.id,
        likedByName: userState.user.name,
      ));
    }
  }

  bool get _isDark => widget.post.backgroundColor != null;
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1A1A2E);
  Color get _subtextColor => _isDark ? Colors.white60 : const Color(0xFF8E8E9A);

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final accent = post.postType.accentColor;

    return BlocListener<LikesBloc, LikesState>(
      // Only respond to CheckHasLiked results for THIS post
        listenWhen: (_, current) => current is LikesLoaded,
        listener: (context, state) {
          if (state is LikesLoaded) {
            setState(() => _hasLiked = state.hasLiked);
          }
        },
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Container(
              margin: EdgeInsets.only(bottom: SizeConfig.heightPercent(1.8)),
              decoration: BoxDecoration(
                color: post.backgroundColor ?? Colors.white,
                borderRadius: BorderRadius.circular(SizeConfig.widthPercent(5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isDark ? 0.18 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Padding(
                padding: EdgeInsets.all(SizeConfig.widthPercent(4)),
                child: GestureDetector(
                  onTap: (){
                    post.isAnonymous ? null : Navigator.push(
                    context,MaterialPageRoute(builder: (_) => OtherUserProfilePage(userId: post.userId)));
                  },
                  child: Row(
                    children: [
                      Container(
                        width: SizeConfig.widthPercent(10),
                        height: SizeConfig.widthPercent(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: post.isAnonymous
                              ? const Color(0xFF8E8E9A).withOpacity(0.15)
                              : accent.withOpacity(0.12),
                          border: Border.all(
                            color: post.isAnonymous ? Colors.transparent : accent.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            post.isAnonymous ? '🎭' : '👤',
                            style: TextStyle(fontSize: SizeConfig.widthPercent(5)),
                          ),
                        ),
                      ),
                      SizedBox(width: SizeConfig.widthPercent(2.5)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.isAnonymous ? 'Anonymous' : post.authorName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: SizeConfig.widthPercent(3.8),
                                color: _textColor,
                              ),
                            ),
                            Text(
                              DateUtilsHelper.timeAgo(post.createdAt),
                              style: TextStyle(
                                fontSize: SizeConfig.widthPercent(2.8),
                                color: _subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.widthPercent(2),
                          vertical: SizeConfig.heightPercent(0.4)
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(SizeConfig.widthPercent(1.5)),
                        ),
                        child: Text(
                          post.postType.label,
                          style: TextStyle(
                            fontSize: SizeConfig.widthPercent(2.5),
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  SizeConfig.widthPercent(4),
                  0,
                  SizeConfig.widthPercent(4),
                  SizeConfig.heightPercent(2)
                ),
                child: Text(
                  post.content,
                  style: TextStyle(
                    fontSize: SizeConfig.widthPercent(4),
                    height: 1.5,
                    color: _textColor,
                  ),
                ),
              ),
              if (post.imageUrl != null)
                Padding(
                  padding: EdgeInsets.only(bottom: SizeConfig.heightPercent(2)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(SizeConfig.widthPercent(2)),
                    child: Image.network(post.imageUrl!, fit: BoxFit.cover),
                  ),
                ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.widthPercent(2),
                      vertical: SizeConfig.heightPercent(1),
                    ),
                    child: Row(
                      children: [
                        _ActionButton(
                          icon: _hasLiked ? Icons.favorite : Icons.favorite_border,
                          label: _likeCount.toString(),
                          color: _hasLiked ? Colors.pink : _subtextColor,
                          onTap: () => _onLikeTap(context),
                        ),
                        _ActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: post.commentCount.toString(),
                          color: _subtextColor,
                          onTap: widget.onComment,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}


class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SizeConfig.widthPercent(2)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.widthPercent(3),
          vertical: SizeConfig.heightPercent(1)
        ),
        child: Row(
          children: [
            Icon(icon, size: SizeConfig.widthPercent(5), color: color),
            SizedBox(width: SizeConfig.widthPercent(1.5)),
            Text(
              label,
              style: TextStyle(
                fontSize: SizeConfig.widthPercent(3.2),
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
