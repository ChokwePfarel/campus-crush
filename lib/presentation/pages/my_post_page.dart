import 'package:dating_app/core/features/my_posts/my_post_item.dart';
import 'package:dating_app/core/utils/date_utils.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/core/widgets/bottom_sheet.dart';
import 'package:dating_app/data/models/post_model.dart';
import 'package:dating_app/domain/repositories/current_user_post_repository.dart';
import 'package:dating_app/domain/repositories/likes_repository.dart';
import 'package:dating_app/presentation/bloc/current_user/user_post_bloc.dart';
import 'package:dating_app/presentation/bloc/current_user/user_post_event.dart';
import 'package:dating_app/presentation/bloc/current_user/user_post_state.dart';
import 'package:dating_app/presentation/bloc/likes/LikesEvent.dart';
import 'package:dating_app/presentation/bloc/likes/LikesState.dart';
import 'package:dating_app/presentation/bloc/likes/likes_bloc.dart';
import 'package:dating_app/presentation/bloc/posts/posts_bloc.dart';
import 'package:dating_app/presentation/bloc/posts/posts_event.dart';

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
  final Map<String, int> _liveLikeCounts = {};

  void _onLikeCountChanged(String postId, int count) {
    if (_liveLikeCounts[postId] != count) {
      setState(() => _liveLikeCounts[postId] = count);
    }
  }

  int _totalLikes(List<PostModel> posts) =>
      posts.fold(0, (sum, p) => sum + (_liveLikeCounts[p.id] ?? p.likeCount));

  int _totalComments(List<PostModel> posts) =>
      posts.fold(0, (sum, p) => sum + p.commentCount);


  Future<void> _confirmDelete(BuildContext context, PostModel post) async {
    HapticFeedback.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,

        title: const Text('Delete Post?'),
        content: Text(
          'This ${post.postType.label.toLowerCase()} post will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:  const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(

            onPressed: () => Navigator.pop(context, false),
            child:  const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // OPTIMISTIC UPDATE: Add to deleting set to hide from UI immediately
      setState(() => _deletingIds.add(post.id));

      // Dispatch background deletion
      context.read<PostBloc>().add(DeletePostRequested(postId: post.id));
    }
  }

  void _showLikesList(BuildContext pageContext, PostModel post) {
    final liveCount = _liveLikeCounts[post.id] ?? post.likeCount;
    if (liveCount == 0) return;

    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: pageContext,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return BlocProvider(
          create: (_) =>
              LikesBloc(pageContext.read<LikesRepository>())
                ..add(LoadLikes(post.id)),
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
                const Text(
                  'Liked by',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    if (state is LikesListLoaded) {
                      if (state.likes.isEmpty) {
                        return const Center(child: Text('No likes yet'));
                      }
                      return Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: state.likes.length,
                          itemBuilder: (context, index) {
                            final like = state.likes[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.pinkAccent.withOpacity(
                                  0.1,
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.pinkAccent,
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                like.likedByName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
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
    final String currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';

    return BlocProvider(
      create: (context) =>
          CurrentUserPostBloc(context.read<CurrentUserPostRepository>())
            ..add(LoadUserPosts()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F8),
        body: BlocBuilder<CurrentUserPostBloc, UserPostState>(
          builder: (context, state) {
            // Filter posts here to exclude those being deleted
            List<PostModel> visiblePosts = [];
            if (state is UserPostLoaded) {
              visiblePosts = state.posts
                  .where((p) => !_deletingIds.contains(p.id))
                  .toList();
            }
            return CustomScrollView(
              slivers: [
                _buildAppBar(),
                if (state is UserPostLoaded) ...[
                  _buildPostList(visiblePosts, currentUserId),
                ] else if (state is UserPostLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  )
                else if (state is UserPostError)
                  SliverFillRemaining(child: Center(child: Text(state.message)))
                else
                  const SliverFillRemaining(
                    child: Center(child: Text("No posts found")),
                  ),
              ],
            );
          },
        ),
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

  SliverPadding _buildPostList(List<PostModel> posts, String currentUserId) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.widthPercent(4),
        SizeConfig.heightPercent(2),
        SizeConfig.widthPercent(4),
        SizeConfig.heightPercent(12),
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, i) {
          final post = posts[i];
          return BlocProvider(
            key: ValueKey(post.id),
            create: (cardCtx) => LikesBloc(cardCtx.read<LikesRepository>()),
            child: MyPostItem(
              post: post,
              currentUserId: currentUserId,
              isDeleting: _deletingIds.contains(post.id),
              onDelete: () => _confirmDelete(context, post),
              onShowLikes: () => _showLikesList(context, post),
              onComment: () => showCommentsSheet(
                context: context,
                postId: post.id,
                commentCount: post.commentCount,
              ),
              onLikeCountChanged: (count) =>
                  _onLikeCountChanged(post.id, count),
            ),
          );
        }, childCount: posts.length),
      ),
    );
  }
}
