import 'package:dating_app/core/utils/date_utils.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/core/widgets/like_comment_button.dart';
import 'package:dating_app/data/models/post_model.dart';
import 'package:dating_app/presentation/bloc/likes/LikesEvent.dart';
import 'package:dating_app/presentation/bloc/likes/LikesState.dart';
import 'package:dating_app/presentation/bloc/likes/likes_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart' as user_st;
import 'package:dating_app/presentation/pages/other_user_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final VoidCallback onComment;
  final Function(String) onAuthorTap;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onComment,
    required this.onAuthorTap,
  });

  @override
  State<PostCard> createState() => PostCardState();
}

class PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {

  late final _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final _slideAnim = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  late final _fadeAnim = CurvedAnimation(
    parent: _animCtrl,
    curve: Curves.easeOut,
  );

  // ── Local like state ───────────────────────────────────────────────────────
  late bool _hasLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _animCtrl.forward();
    });

    // Fire InitializeLikes — this card's own LikesBloc handles it
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
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }


  bool get _isDark => widget.post.backgroundColor != null;

  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1A1A2E);

  Color get _subtextColor => _isDark ? Colors.white60 : const Color(0xFF8E8E9A);

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final accent = post.postType.accentColor;

    return FadeTransition(
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
                  onTap: () {
                    post.isAnonymous
                        ? null
                        : Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OtherUserProfilePage(userId: post.userId),
                      ),
                    );
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
                            color: post.isAnonymous
                                ? Colors.transparent
                                : accent.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            post.isAnonymous ? '🎭' : '👤',
                            style: TextStyle(
                              fontSize: SizeConfig.widthPercent(5),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: SizeConfig.widthPercent(2.5)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.isAnonymous
                                  ? 'Anonymous'
                                  : post.authorName,
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
                          vertical: SizeConfig.heightPercent(0.4),
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(
                            SizeConfig.widthPercent(1.5),
                          ),
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
                  SizeConfig.heightPercent(2),
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
                  padding: EdgeInsets.only(
                    bottom: SizeConfig.heightPercent(2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      SizeConfig.widthPercent(2),
                    ),
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
                    BlocBuilder<LikesBloc, LikesState>(
                      builder: (context, state) {
                        final hasLiked = state is LikesLoaded && state.hasLiked;
                        final count = state is LikesLoaded
                            ? state.likeCount
                            : post.likeCount;

                        return ActionButton(
                          icon: hasLiked ? Icons.favorite : Icons.favorite_border,
                          label: count.toString(),
                          color: hasLiked ? Colors.pink : _subtextColor,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            final userState = context.read<UserBloc>().state;
                            if (userState is! user_st.UserLoaded) return;

                            if (hasLiked) {
                              context.read<LikesBloc>().add(UnlikePost(
                                postId: post.id,
                                userId: userState.user.id,
                              ));
                            } else {
                              context.read<LikesBloc>().add(LikePost(
                                postId: post.id,
                                userId: userState.user.id,
                                likedByName: userState.user.name,
                              ));
                            }
                          },
                        );
                      },
                    ),
                    ActionButton(
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

    );
  }
}
