import 'package:dating_app/core/features/feed/post_card.dart';
import 'package:dating_app/data/models/post_model.dart';
import 'package:dating_app/presentation/bloc/posts/posts_bloc.dart';
import 'package:dating_app/presentation/bloc/posts/posts_event.dart';
import 'package:dating_app/presentation/bloc/posts/posts_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:dating_app/core/utils/comment_skeleton.dart';
import 'package:dating_app/core/utils/date_utils.dart';

import 'package:dating_app/domain/entities/comment_entity.dart';
import 'package:dating_app/domain/repositories/likes_repository.dart';
import 'package:dating_app/presentation/bloc/comments/commenst_event.dart';
import 'package:dating_app/presentation/bloc/comments/comments_bloc.dart';
import 'package:dating_app/presentation/bloc/comments/comments_state.dart';
import 'package:dating_app/presentation/bloc/likes/likes_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart' as user_st;
import 'package:dating_app/presentation/pages/other_user_profile.dart';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DetailedPost extends StatefulWidget {
  final String postId;
  final String currentUserId;

  const DetailedPost({
    super.key,
    required this.currentUserId,
    required this.postId,
  });

  @override
  State<DetailedPost> createState() => _DetailedPostState();
}

class _DetailedPostState extends State<DetailedPost> {
  final _inputCtrl = TextEditingController();
  final _focusNode = FocusNode();
  CommentEntity? _replyingTo;

  @override
  void initState() {
    super.initState();
    // ✅ Fetch post first
    context.read<PostBloc>().add(GetOnePostById(postId: widget.postId));
    // ✅ Load comments
    context.read<CommentsBloc>().add(LoadComments(widget.postId));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    final userState = context.read<UserBloc>().state;
    if (userState is user_st.UserLoaded) {
      context.read<CommentsBloc>().add(
        AddComment(
          postId: widget.postId,
          // Use widget.postId directly
          userId: userState.user.id,
          repliersName: userState.user.name,
          text: text,
          parentCommentId: _replyingTo?.id,
        ),
      );

      _inputCtrl.clear();
      setState(() => _replyingTo = null);
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LikesBloc(context.read<LikesRepository>()),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Post',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: BlocBuilder<PostBloc, PostState>(
          builder: (context, postState) {
            // ── Loading Post ───────────────────────────────────
            if (postState is LoadingPosts || postState is PostInitial) {
              return const Center(child: CupertinoActivityIndicator());
            }

            // ── Error ────────────────────────────────────────
            if (postState is PostError) {
              return Center(child: Text('Error: ${postState.message}'));
            }

            // ── Loaded ───────────────────────────────────────
            if (postState is OnePostLoaded) {
              final post = postState.post;

              return Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: PostCard(
                            post: post,
                            currentUserId: widget.currentUserId,
                            onComment: () => _focusNode.requestFocus(),
                            onAuthorTap: (uid) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    OtherUserProfilePage(userId: uid),
                              ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Comments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        _buildCommentsList(),
                      ],
                    ),
                  ),
                  if (_replyingTo != null) _buildReplyBanner(),
                  _buildInputBar(),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    return BlocBuilder<CommentsBloc, CommentsState>(
      builder: (context, state) {
        if (state is LoadingComments) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CommentSkeletonItem(),
              ),
              childCount: 3,
            ),
          );
        }
        if (state is ErrorComments) {
          return SliverToBoxAdapter(child: Center(child: Text(state.message)));
        }
        if (state is CommentsLoaded) {
          if (state.comments.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    "No comments yet.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            );
          }

          final topLevel = state.comments
              .where((c) => c.parentCommentId == null)
              .toList();

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _CommentItem(
                  comment: topLevel[i],
                  onReply: (c) {
                    setState(() => _replyingTo = c);
                    _focusNode.requestFocus();
                  },
                ),
                childCount: topLevel.length,
              ),
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox());
      },
    );
  }

  Widget _buildReplyBanner() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(CupertinoIcons.reply, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Replying to ${_replyingTo!.repliersName}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _replyingTo = null),
            child: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        bottom: 10,
        left: 16,
        right: 16,
        top: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              CupertinoIcons.arrow_up_circle_fill,
              color: Color(0xFF6C63FF),
              size: 32,
            ),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final CommentEntity comment;
  final void Function(CommentEntity) onReply;

  const _CommentItem({required this.comment, required this.onReply});

  @override
  Widget build(BuildContext context) {
    final isAnonymous = comment.repliersName == 'Anonymous';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isAnonymous
                    ? Colors.grey.shade200
                    : Colors.purple.shade50,
                child: Text(isAnonymous ? '🎭' : comment.repliersName[0]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.repliersName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(comment.text, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateUtilsHelper.timeAgo(comment.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => onReply(comment),
                          child: const Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              children: comment.replies
                  .map((r) => _CommentItem(comment: r, onReply: onReply))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
