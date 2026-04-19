import 'dart:ui';

import 'package:dating_app/core/utils/date_utils.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/data/models/post_model.dart';
import 'package:dating_app/presentation/bloc/likes/LikesEvent.dart';
import 'package:dating_app/presentation/bloc/likes/LikesState.dart';
import 'package:dating_app/presentation/bloc/likes/likes_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyPostItem extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final bool isDeleting;
  final VoidCallback onDelete;
  final VoidCallback onShowLikes;
  final VoidCallback onComment;
  final ValueChanged<int> onLikeCountChanged;

  const MyPostItem({
    required this.post,
    required this.currentUserId,
    required this.isDeleting,
    required this.onDelete,
    required this.onShowLikes,
    required this.onComment,
    required this.onLikeCountChanged,
  });

  @override
  State<MyPostItem> createState() => MyPostItemState();
}

class MyPostItemState extends State<MyPostItem> {
  @override
  void initState() {
    super.initState();
    // Initialize this card's LikesBloc with the post's known count.
    // This page is "my posts" — the current user is the author, not a liker,
    // so we pass an empty userId for hasLiked (they can't like their own post).
    Future.microtask(() {
      if (!mounted) return;
      context.read<LikesBloc>().add(InitializeLikes(
        postId: widget.post.id,
        userId: widget.currentUserId,
        initialCount: widget.post.likeCount,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.post.postType.accentColor;
    final backgroundColor = widget.post.backgroundColor;


    return BlocListener<LikesBloc, LikesState>(
      listenWhen: (prev, curr) =>
      curr is LikesLoaded &&
          (prev is! LikesLoaded ||
              (prev).likeCount != curr.likeCount),
      listener: (_, state) {
        if (state is LikesLoaded) {
          widget.onLikeCountChanged(state.likeCount);
        }
      },
      child: GestureDetector(
        onLongPress: widget.isDeleting ? null : widget.onDelete,

        child: Container(
          margin: EdgeInsets.only(bottom: SizeConfig.heightPercent(1.5)),
          padding: EdgeInsets.all(SizeConfig.widthPercent(4)),
          decoration: BoxDecoration(
            color: backgroundColor,
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
                      vertical: SizeConfig.heightPercent(0.4),
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.post.postType.label,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.widthPercent(2.8)),
                    ),
                  ),
                  Text(
                    DateUtilsHelper.timeAgo(widget.post.createdAt),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: SizeConfig.widthPercent(3)),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.heightPercent(1.5)),
              Text(
                widget.post.content,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: SizeConfig.widthPercent(3.8), height: 1.4),
              ),
              SizedBox(height: SizeConfig.heightPercent(2)),
              Row(
                children: [
                  BlocBuilder<LikesBloc, LikesState>(
                    builder: (context, state) {
                      final hasLiked = state is LikesLoaded && state.hasLiked;
                      final count = state is LikesLoaded
                          ? state.likeCount
                          : widget.post.likeCount;

                      return Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              final userState = context.read<UserBloc>().state;
                              if (userState is! UserLoaded) return;
                              if (hasLiked) {
                                context.read<LikesBloc>().add(UnlikePost(
                                    postId: widget.post.id,
                                    userId: userState.user.id));
                              } else {
                                context.read<LikesBloc>().add(LikePost(
                                    postId: widget.post.id,
                                    userId: userState.user.id,
                                    likedByName: userState.user.name));
                              }
                            },
                            child: Icon(
                              hasLiked ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: hasLiked ? Colors.pink : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: widget.onShowLikes,
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: widget.onComment,
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble,
                            size: 16, color: Colors.blue.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text('${widget.post.commentCount}',
                            style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
