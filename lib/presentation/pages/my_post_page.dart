import 'package:dating_app/core/utils/date_utils.dart';
import 'package:dating_app/core/utils/posts_skeleton.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/core/widgets/bottom_sheet.dart';
import 'package:dating_app/data/models/post_model.dart';
import 'package:dating_app/domain/repositories/current_user_post_repository.dart';
import 'package:dating_app/presentation/bloc/comments/commenst_event.dart';
import 'package:dating_app/presentation/bloc/comments/comments_bloc.dart';
import 'package:dating_app/presentation/bloc/current_user/user_post_bloc.dart';
import 'package:dating_app/presentation/bloc/current_user/user_post_event.dart';
import 'package:dating_app/presentation/bloc/current_user/user_post_state.dart';
import 'package:dating_app/presentation/bloc/likes/LikesEvent.dart';
import 'package:dating_app/presentation/bloc/likes/LikesState.dart';
import 'package:dating_app/presentation/bloc/likes/likes_bloc.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  final Set<String> _deletingIds = {};

  int _totalLikes(List<PostModel> posts) =>
      posts.fold(0, (sum, p) => sum + p.likeCount);

  int _totalComments(List<PostModel> posts) =>
      posts.fold(0, (sum, p) => sum + p.commentCount);


  void initState(){
    super.initState();

    final String currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    Future.microtask(() {

      context.read<CommentsBloc>().add(LoadComments(currentUserId));
      context.read<LikesBloc>().add(LoadLikes(currentUserId));
    });
  }

  Future<void> _confirmDelete(PostModel post) async {
    HapticFeedback.mediumImpact();

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Post?'),
        content: Text(
          'This ${post.postType.label.toLowerCase()} post will be permanently removed.',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingIds.add(post.id));
    // TODO: Dispatch Delete event to Bloc
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _deletingIds.remove(post.id));
  }

  void _showLikesList(BuildContext context, PostModel post) {
    if (post.likeCount == 0) return;
    
    HapticFeedback.lightImpact();
    context.read<LikesBloc>().add(LoadLikes(post.id));
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return BlocProvider.value(
          value: context.read<LikesBloc>(),
          child: Container(
            padding: EdgeInsets.all(SizeConfig.widthPercent(5)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.heightPercent(2)),
                Text(
                  'Liked by',
                  style: TextStyle(
                    fontSize: SizeConfig.widthPercent(5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: SizeConfig.heightPercent(2)),
                BlocBuilder<LikesBloc, LikesState>(
                  builder: (context, state) {
                    if (state is LikesLoading) {
                      return const Center(child: CupertinoActivityIndicator());
                    }
                    if (state is LikesError) {
                      return Center(child: Text('Error: ${state.message}'));
                    }
                    if (state is LikesLoaded) {
                      return Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: state.likes.length,
                          itemBuilder: (context, index) {
                            final like = state.likes[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.pinkAccent.withOpacity(0.1),
                                child: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 16),
                              ),
                              title: Text(
                                like.likedByName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: const Text('Student'),
                            );
                          },
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
                SizedBox(height: SizeConfig.heightPercent(4)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return BlocProvider(
      create: (context) => CurrentUserPostBloc(context.read<CurrentUserPostRepository>()),
      child: Builder(
        builder: (context) {
          // Dispatch fetch once Bloc is available
          context.read<CurrentUserPostBloc>().add(LoadUserPosts());



          return Scaffold(
            backgroundColor: const Color(0xFFF4F4F8),
            body: BlocBuilder<CurrentUserPostBloc, UserPostState>(
              builder: (context, state) {
                if (state is UserPostLoading) {
                  return const Center(child: PostListSkeleton());
                }

                if (state is UserPostError) {
                  return Center(child: Text('Error: ${state.message}'));
                }

                if (state is UserPostLoaded) {
                  final myPosts = state.posts;

                  return CustomScrollView(
                    slivers: [
                      _buildAppBar(),
                      if (myPosts.isNotEmpty) ...[
                        _buildStatsBar(myPosts),
                        _buildPostList(myPosts),
                      ] else
                        _buildEmpty(),
                    ],
                  );
                }

                return const Center(child: Text('Connecting to history...'));
              },
            ),
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
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.of(context).pop(),
        child: const Icon(
          CupertinoIcons.chevron_left,
          color: Color(0xFF1A1A2E),
        ),
      ),
      title: const Text(
        'My History',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A1A2E),
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildStatsBar(List<PostModel> posts) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
          SizeConfig.widthPercent(5), 
          SizeConfig.heightPercent(2), 
          SizeConfig.widthPercent(5), 
          SizeConfig.heightPercent(2.5)
        ),
        child: Row(
          children: [
            _StatChip(
              emoji: '📝',
              value: '${posts.length}',
              label: posts.length == 1 ? 'Post' : 'Posts',
              color: const Color(0xFF6C63FF),
            ),
            SizedBox(width: SizeConfig.widthPercent(2.5)),
            _StatChip(
              emoji: '❤️',
              value: '${_totalLikes(posts)}',
              label: 'Likes',
              color: const Color(0xFFFF4D6D),
            ),
            SizedBox(width: SizeConfig.widthPercent(2.5)),
            _StatChip(
              emoji: '💬',
              value: '${_totalComments(posts)}',
              label: 'Comments',
              color: const Color(0xFF2EC4B6),
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding _buildPostList(List<PostModel> posts) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.widthPercent(4), 
        SizeConfig.heightPercent(2), 
        SizeConfig.widthPercent(4), 
        SizeConfig.heightPercent(12)
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _MyPostItem(
            post: posts[i],
            isDeleting: _deletingIds.contains(posts[i].id),
            onDelete: () => _confirmDelete(posts[i]),
            onShowLikes: () => _showLikesList(context, posts[i]),
            onComment: () => showCommentsSheet(context: context, postId: posts[i].id, commentCount: posts[i].commentCount),
          ),
          childCount: posts.length,
        ),
      ),
    );
  }

  SliverFillRemaining _buildEmpty() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📭', style: TextStyle(fontSize: SizeConfig.widthPercent(12))),
            SizedBox(height: SizeConfig.heightPercent(2)),
            const Text(
              'No posts yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.heightPercent(1.5)),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(SizeConfig.widthPercent(3.5)),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: SizeConfig.widthPercent(5))),
            SizedBox(height: SizeConfig.heightPercent(0.5)),
            Text(
              value,
              style: TextStyle(
                fontSize: SizeConfig.widthPercent(4.5),
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: SizeConfig.widthPercent(2.8),
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyPostItem extends StatelessWidget {
  final PostModel post;
  final bool isDeleting;
  final VoidCallback onDelete;
  final VoidCallback onShowLikes;
  final VoidCallback onComment;

  const _MyPostItem({
    required this.post,
    required this.isDeleting,
    required this.onDelete,
    required this.onShowLikes,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    final accent = post.postType.accentColor;
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.heightPercent(1.5)),
      padding: EdgeInsets.all(SizeConfig.widthPercent(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.widthPercent(4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.widthPercent(2), 
                  vertical: SizeConfig.heightPercent(0.4)
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  post.postType.label,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: SizeConfig.widthPercent(2.8),
                  ),
                ),
              ),
              Text(
                DateUtilsHelper.timeAgo(post.createdAt),
                style: TextStyle(color: Colors.grey, fontSize: SizeConfig.widthPercent(3)),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.heightPercent(1.5)),
          Text(
            post.content,
            style: TextStyle(fontSize: SizeConfig.widthPercent(3.8), height: 1.4),
          ),
          SizedBox(height: SizeConfig.heightPercent(2)),
          Row(
            children: [
              GestureDetector(
                onTap: onShowLikes,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, size: 16, color: Colors.pink.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likeCount}', 
                        style: TextStyle(
                          color: Colors.grey[700], 
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onComment,
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble, size: 16, color: Colors.blue.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Text('${post.commentCount}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: isDeleting ? null : onDelete,
                icon: Icon(
                  CupertinoIcons.trash,
                  size: 18,
                  color: isDeleting ? Colors.grey : Colors.redAccent.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
